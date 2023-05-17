{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}

module Main where

import Control.Exception
import Control.Monad
import Control.Monad.Trans.Class
import Data.Aeson hiding (json)
import Data.Aeson.KeyMap
import Data.ByteString as BS
import Data.ByteString.Lazy as LBS
import Data.Text
import qualified Database.SQLite.Simple as SQLite
import Network.HTTP.Types
import System.IO
import Web.Scotty

data OrderLine = OrderLine Text Int Sku
  deriving (Show)

type Sku = Text

data Command = OrderLineCommand OrderLine
  deriving (Show)

instance FromJSON Command where
  parseJSON v = case v of
    Object o -> do
      case o !? "type" of
        Just (String "order_line") -> do
          orderLine <- parseJSON v
          return $ OrderLineCommand orderLine
        _ -> fail "type should be the string order_line"
    _ -> fail "should be an object"

instance FromJSON OrderLine where
  parseJSON v = case v of
    Object o -> do
      orderId <- case o !? "order_id" of
        Just (String s) -> return s
        _ -> fail "order_id should be a String"
      count <- case o !? "count" of
        Just (Number n) -> return n
        _ -> fail "count should be a Number"
      sku <- case o !? "sku" of
        Just (String s) -> return s
        _ -> fail "sku should be a String"
      return $ OrderLine orderId (floor count) sku
    _ -> fail "should be an object"

data SkuTotal = SkuTotal Sku Int
  deriving (Show)

instance ToJSON SkuTotal where
  toJSON (SkuTotal sku total) = object ["type" .= String "sku_total", "sku" .= sku, "total" .= total]

main :: IO ()
main = do
  hSetBuffering stdout LineBuffering
  hSetBuffering stderr NoBuffering
  c <- SQLite.open ":memory:"
  createTable c
  (`finally` SQLite.close c) $
    forever $ do
      inputLine <- BS.getLine
      case decode (LBS.fromStrict inputLine) of
        Nothing -> System.IO.hPutStr stderr "could not decode command\n"
        Just command -> do
          case command of
            OrderLineCommand orderLine@(OrderLine _ _ sku) -> do
              insertOrderLine c orderLine
              total <- getSkuTotal c sku
              LBS.putStr $ encode $ SkuTotal sku total
              System.IO.putStrLn ""

createTable :: SQLite.Connection -> IO ()
createTable c =
  SQLite.execute_
    c
    "CREATE TABLE order_lines(\
    \order_id TEXT,\
    \sku TEXT,\
    \count INT)"

insertOrderLine :: SQLite.Connection -> OrderLine -> IO ()
insertOrderLine c (OrderLine orderId count sku) =
  SQLite.execute
    c
    "INSERT INTO order_lines \
    \(order_id, sku, count) \
    \VALUES (?, ?, ?)"
    (orderId, sku, count)

getSkuTotal :: SQLite.Connection -> Sku -> IO Int
getSkuTotal c sku = do
  totals <- SQLite.query c "SELECT SUM(count) FROM order_lines WHERE sku = ?" (SQLite.Only sku)
  case totals of
    [[total]] -> return total
    _ -> error "SQL query returned unexpected results"
