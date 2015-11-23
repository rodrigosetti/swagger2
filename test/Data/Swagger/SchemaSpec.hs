{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE QuasiQuotes #-}
module Data.Swagger.SchemaSpec where

import Data.Aeson
import Data.Aeson.QQ
import Data.Char
import Data.Proxy
import GHC.Generics

import Data.Swagger
import Data.Swagger.Schema

import SpecCommon
import Test.Hspec

checkToSchema :: ToSchema a => Proxy a -> Value -> Spec
checkToSchema proxy js = toSchema proxy <~> js

spec :: Spec
spec = do
  describe "Generic ToSchema" $ do
    context "Person" $ checkToSchema (Proxy :: Proxy Person) personSchemaJSON
    context "ISPair" $ checkToSchema (Proxy :: Proxy ISPair) ispairSchemaJSON
    context "Point (fieldLabelModifier)" $ checkToSchema (Proxy :: Proxy Point) pointSchemaJSON
    context "Unary records" $ do
      context "Email (unwrapUnaryRecords)"  $ checkToSchema (Proxy :: Proxy Email)  emailSchemaJSON
      context "UserId (non-record newtype)" $ checkToSchema (Proxy :: Proxy UserId) userIdSchemaJSON
      context "Player (unary record)" $ checkToSchema (Proxy :: Proxy Player) playerSchemaJSON
  describe "toSchemaBoundedEnum" $ do
    context "Color" $ checkToSchema (Proxy :: Proxy Color) colorSchemaJSON

main :: IO ()
main = hspec spec

-- ========================================================================
-- Person (simple record with optional fields)
-- ========================================================================
data Person = Person
  { name  :: String
  , phone :: Integer
  , email :: Maybe String
  } deriving (Generic, ToSchema)

personSchemaJSON :: Value
personSchemaJSON = [aesonQQ|
{
  "type": "object",
  "properties":
    {
      "name":   { "type": "string"  },
      "phone":  { "type": "integer" },
      "email":  { "type": "string"  }
    },
  "required": ["name", "phone"]
}
|]

-- ========================================================================
-- ISPair (non-record product data type)
-- ========================================================================
data ISPair = ISPair Integer String
  deriving (Generic, ToSchema)

ispairSchemaJSON :: Value
ispairSchemaJSON = [aesonQQ|
{
  "type": "array",
  "items":
    [
      { "type": "integer" },
      { "type": "string"  }
    ]
}
|]

-- ========================================================================
-- Point (record data type with custom fieldLabelModifier)
-- ========================================================================
data Point = Point
  { pointX :: Double
  , pointY :: Double
  } deriving (Generic)

instance ToSchema Point where
  toSchema = genericToSchema defaultSchemaOptions
    { fieldLabelModifier = map toLower . drop (length "point") }

pointSchemaJSON :: Value
pointSchemaJSON = [aesonQQ|
{
  "type": "object",
  "properties":
    {
      "x": { "type": "number" },
      "y": { "type": "number" }
    },
  "required": ["x", "y"]
}
|]


-- ========================================================================
-- Point (record data type with custom fieldLabelModifier)
-- ========================================================================
data Color
  = Red
  | Green
  | Blue
  deriving (Generic, Enum, Bounded, ToJSON)

instance ToSchema Color where
  toSchema = toSchemaBoundedEnum

colorSchemaJSON :: Value
colorSchemaJSON = [aesonQQ|
{
  "type": "string",
  "enum": ["Red", "Green", "Blue"]
}
|]

-- ========================================================================
-- Email (newtype with unwrapUnaryRecords set to True)
-- ========================================================================

newtype Email = Email { getEmail :: String }
  deriving (Generic)

instance ToSchema Email where
  toSchema = genericToSchema defaultSchemaOptions
    { unwrapUnaryRecords = True }

emailSchemaJSON :: Value
emailSchemaJSON = [aesonQQ|
{
  "type": "string"
}
|]

-- ========================================================================
-- UserId (non-record newtype)
-- ========================================================================

newtype UserId = UserId Integer
  deriving (Generic, ToSchema)

userIdSchemaJSON :: Value
userIdSchemaJSON = [aesonQQ|
{
  "type": "integer"
}
|]

-- ========================================================================
-- Player (record newtype)
-- ========================================================================

newtype Player = Player
  { position :: Point
  } deriving (Generic, ToSchema)

playerSchemaJSON :: Value
playerSchemaJSON = [aesonQQ|
{
  "type": "object",
  "properties":
    {
      "position":
        {
          "type": "object",
          "properties":
            {
              "x": { "type": "number" },
              "y": { "type": "number" }
            },
          "required": [ "x", "y" ]
        }
    },
  "required": ["position"]
}
|]
