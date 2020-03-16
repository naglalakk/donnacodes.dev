module Component.HTML.BlogPost where

import Prelude
import Data.Array                           (length)
import Data.Maybe                           (Maybe(..))
import Data.Newtype                         (unwrap)
import Halogen                              as H
import Halogen.HTML                         as HH
import Halogen.HTML.CSS                     as HCSS
import Halogen.HTML.Properties              as HP
import Timestamp                            (formatToDateStr)

import Component.HTML.Utils                 (css)
import CSS.Utils                            (backgroundCover)
import Data.BlogPost                        (BlogPost(..)
                                            ,BlogPostArray)
import Data.Image                           (Image(..))

renderBlogPost :: forall i p. BlogPost -> HH.HTML i p 
renderBlogPost (BlogPost post) = 
  HH.div
    [ css $ "post cover-" <> (show post.isCover) ]
    [ case post.isCover of
      true ->
        HH.div
          [ css "cover-image" 
          , case post.featuredImage of
            Just (Image image) -> HCSS.style $ backgroundCover image.src
            Nothing -> css "no-cover"
          ]
          [ HH.div
            [ css "title" ]
            [ HH.h1
              []
              [ HH.text post.title ]
            , HH.div [ css "title-line" ] []
            , case post.showDate of
              true -> 
                HH.div
                  [ css "post-date" ]
                  [ HH.text $ formatToDateStr post.publishTime ]
              false -> HH.div [] []
            ]
          ]
      false ->
        HH.div
          [ css "title" ]
          [ HH.h1
            []
            [ HH.text post.title ]
          , HH.div [ css "title-line" ] []
          , case post.showDate of
            true -> 
              HH.div
                [ css "post-date" ]
                [ HH.text $ formatToDateStr post.publishTime ]
            false -> HH.div [] []
          ]
    , HH.div
      [ css "post-content" 
      , HP.ref (H.RefLabel ("element-" <> (show $ unwrap post.id)))
      ]
      []
    , case length post.images of
        0 -> HH.div [] []
        _ -> 
          HH.div
            [ css "lightgallery" ]
            (map (\(Image image) -> 
              HH.a
                [ HP.href image.src ]
                [ HH.img
                  [ case image.thumbnail of
                    Just thumb -> HP.src thumb
                    Nothing -> HP.src image.src
                  ]
                ]) post.images )
    ]