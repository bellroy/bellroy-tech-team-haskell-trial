{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Control.Exception
import Control.Monad.Trans.Class
import DB
import Data.Aeson hiding (json)
import Data.Text
import qualified Database.SQLite.Simple as SQLite
import Network.HTTP.Types
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

main :: IO ()
main = do
  c <- initDB
  (`finally` SQLite.close c) . scotty 3000 $
    get "/shipping_rates" $ do
      country_code :: Text <- queryParam "country_code"
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
