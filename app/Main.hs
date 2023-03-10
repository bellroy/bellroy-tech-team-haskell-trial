{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Control.Exception
import Control.Exception.Base (try)
import Control.Monad.Trans.Class
import DB
import Data.Aeson hiding (json)
import Data.Text
import Database.SQLite.Simple (ToRow (toRow))
import qualified Database.SQLite.Simple as SQLite
import Debug.Trace
import GHC.Generics (Generic)
import Network.HTTP.Types
import Network.Wai.Middleware.RequestLogger
import Web.Scotty

data ShippingRate = ShippingRate Text Text

instance SQLite.FromRow ShippingRate where
  fromRow = ShippingRate <$> SQLite.field <*> SQLite.field

instance ToJSON ShippingRate where
  toJSON (ShippingRate reg exp) =
    object
      [ "regular" .= reg,
        "express" .= exp
      ]

data ShippingRateForm = ShippingRateForm
  { name :: Text,
    code :: Text,
    regular_shipping_rate :: Text,
    express_shipping_rate :: Text
  }
  deriving (Show, Eq, Generic, FromJSON)

instance SQLite.ToRow ShippingRateForm where
  toRow (ShippingRateForm name code regular_shipping_rate express_shipping_rate) =
    toRow (name, code, regular_shipping_rate, express_shipping_rate)

main :: IO ()
main = do
  c <- initDB
  (`finally` SQLite.close c) . scotty 8080 $ do
    middleware logStdoutDev

    get "/shipping_rates" $ do
      country_code :: Text <- param "country_code"
      rate :: [ShippingRate] <-
        lift $
          SQLite.query
            c
            "SELECT regular_shipping_rate, express_shipping_rate \
            \FROM country WHERE code = ?"
            (SQLite.Only country_code)
      case rate of
        [r] -> json r
        [] -> do
          status notFound404
          json $ object ["error" .= String "Not found"]
        _ -> do
          status internalServerError500
          json $ object ["error" .= String "Something went wrong"]
    post "/shipping_rates" $ do
      body' <- body
      case eitherDecode body' of
        Left err -> do
          status badRequest400
          json $ object ["error" .= String (pack $ "invalid input" <> show err)]
        Right (form :: ShippingRateForm) -> do
          result :: Either SomeException () <-
            lift $
              try $
                SQLite.execute
                  c
                  "INSERT INTO country \
                  \(name, code, regular_shipping_rate, regular_shipping_rate) \
                  \VALUES (?, ?, ?, ?)"
                  form
          case result of
            Left ex -> do
              status badRequest400
              json $ object ["error" .= String (pack $ show ex)]
            Right _ -> do
              status ok200
