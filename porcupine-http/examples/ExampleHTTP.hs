{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DeriveAnyClass        #-}
{-# LANGUAGE DeriveGeneric         #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE OverloadedLabels      #-}
{-# LANGUAGE OverloadedStrings     #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeApplications      #-}

-- The same example than example1 in 'porcupine-core', but with http access
-- enabled by 'runPipelineTask'. Don't forget to map locations to http urls in
-- the 'exampleHTTP.yaml' generated by calling 'exampleHTTP write-config-template',
-- or else it will act exactly like example1.
--
-- Don't forget to enable OverloadedLabels and import Data.Locations.Accessors.AWS

import           Data.Aeson
import           Data.DocRecord
-- import qualified Data.HashMap.Strict           as HM
import qualified Data.Text                     as T
import           GHC.Generics
import           Porcupine.Run
import           Porcupine.Serials
import           Porcupine.Tasks
import           Prelude                       hiding (id, (.))

import           Data.Locations.Accessors.HTTP


data Move = Move { name :: T.Text }
  deriving (Generic, FromJSON)

newtype Move' = Move' { move :: Move }
  deriving (Generic, FromJSON)

data Pokemon = Pokemon { name  :: T.Text
                       , moves :: [Move'] }
  deriving (Generic, FromJSON)

-- | How to load pokemons.
pokemonFile :: DataSource Pokemon
pokemonFile = dataSource ["Inputs", "Pokemon"]
                         (somePureDeserial JSONSerial)
-- See https://pokeapi.co/api/v2/pokemon/25 for instance

data Analysis = Analysis { moveCount :: Int }
  deriving (Generic, ToJSON)

-- | How to write analysis
analysisFile :: DataSink Analysis
analysisFile = dataSink ["Outputs", "Analysis"]
                        (somePureSerial JSONSerial)

analyzePokemon :: Pokemon -> Analysis
analyzePokemon = Analysis . length . moves

-- | The task combining the three previous operations.
--
-- This task may look very opaque from the outside, having no parameters and no
-- return value. But we will be able to reuse it over different users without
-- having to change it at all.
analyseOnePokemon :: (LogThrow m) => PTask m () ()
analyseOnePokemon =
  loadData pokemonFile >>> arr analyzePokemon >>> writeData analysisFile

mainTask :: (LogThrow m) => PTask m () ()
mainTask =
  -- First we get the ids of the users that we want to analyse. We need only one
  -- field that will contain a range of values, see IndexRange. By default, this
  -- range contains just one value, zero.
  getOption ["Settings"] (docField @"pokemonIds" (oneIndex (1::Int)) "The indice of the pokemon to load")
  -- We turn the range we read into a full lazy list:
  >>> arr enumIndices
  -- Then we just map over these ids and call analyseOnePokemon each time:
  >>> parMapTask_ (repIndex "pokemonId") analyseOnePokemon

main :: IO ()
main = runPipelineTask (FullConfig "exampleHTTP" "exampleHTTP.yaml" "exampleHTTP_files")
                       (  #http <-- useHTTP
                            -- We just add #http on top of the baseContexts.
                       :& baseContexts "")
                       mainTask ()
