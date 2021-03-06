module Main where

import Prelude

import Affjax (printError, request)
import Api.Endpoint as API
import Api.Request (RequestMethod(..), defaultRequest)
import AppM (runAppM)
import Component.Router as Router
import Config (environment, apiURL)
import Control.Monad.Error.Class (class MonadError)
import Data.Argonaut (JsonDecodeError, decodeJson, encodeJson, printJsonDecodeError)
import Data.Auth (APIAuth(..), readToken)
import Data.Bifunctor (bimap)
import Data.Either (Either(..), hush)
import Data.Environment (Env, UserEnv, toEnvironment)
import Data.Foldable (traverse_)
import Data.Maybe (Maybe(..))
import Data.Route (routeCodec)
import Data.String (drop)
import Data.URL (BaseURL(..))
import Data.User (User)
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Aff.Bus as Bus
import Effect.Aff.Class (class MonadAff)
import Effect.Class.Console (log, logShow)
import Effect.Ref as Ref
import Foreign as Foreign
import Halogen as H
import Halogen.Aff as HA
import Halogen.HTML as HH
import Halogen.VDom.Driver (runUI)
import Routing.Duplex (parse)
import Routing.PushState (makeInterface, matchesWith)
import Simple.JSON (read_)

main :: Effect Unit
main = HA.runHalogenAff do
  body <- HA.awaitBody
  
  currentUser <- H.liftEffect $ Ref.new Nothing
  userBus <- H.liftEffect Bus.make
  interface <- H.liftEffect makeInterface 

  H.liftEffect readToken >>= traverse_ \token -> do
    let 
      requestOptions = 
        { endpoint: API.UserLogin
        , method: Get 
        , auth: Just $ Basic token
        }
    res <- H.liftAff $ request $ defaultRequest (BaseURL apiURL) requestOptions

    case res of
      Right json -> do
        let 
          user = (decodeJson json.body) :: Either JsonDecodeError User
        case user of
          Right u -> H.liftEffect $ Ref.write (Just u) currentUser
          Left err -> do
            logShow $ printJsonDecodeError err
            pure unit
      Left err -> do
        logShow $ printError err
        pure unit

  let 
    environ = toEnvironment environment
    url     = BaseURL apiURL
    env :: Env
    env = 
      { environment: environ
      , apiURL: url
      , userEnv: userEnv
      , pushInterface: interface
      }
      where
        userEnv :: UserEnv
        userEnv = { currentUser, userBus }

    rootComponent :: H.Component HH.HTML Router.Query Unit Void Aff
    rootComponent = H.hoist (runAppM env) Router.component

  halogenIO <- runUI rootComponent unit body

  void $ H.liftEffect $ interface.listen \location -> do
    let
      new  = hush $ parse routeCodec $ drop 1 location.pathname
    case new of
      Just r -> launchAff_ $ halogenIO.query $ H.tell $ Router.Navigate r
      Nothing -> pure unit
  pure unit
