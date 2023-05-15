{-# LANGUAGE OverloadedStrings #-}

module DB where

import Data.Text (Text)
import qualified Database.SQLite.Simple as SQLite

initDB :: IO SQLite.Connection
initDB = do
  c <- SQLite.open ":memory:"
  createTable c
  seed c
  pure c

createTable :: SQLite.Connection -> IO ()
createTable c =
  SQLite.execute_
    c
    "CREATE TABLE country(\
    \name TEXT,\
    \code TEXT,\
    \regular_shipping_rate TEXT,\
    \express_shipping_rate TEXT)"

seed :: SQLite.Connection -> IO ()
seed c =
  SQLite.executeMany
    c
    "INSERT INTO country \
    \(name, code, regular_shipping_rate, express_shipping_rate) \
    \VALUES (?, ?, ?, ?)"
    values
  where
    values :: [(Text, Text, Text, Text)]
    values =
      [ ("Australia", "AU", "20.00", "50.00"),
        ("United States", "US", "40.00", "60.00")
      ]
