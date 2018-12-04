{-# LANGUAGE TypeSynonymInstances #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE OverloadedLabels #-}
{-# LANGUAGE ExistentialQuantification #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# OPTIONS_GHC "-fno-warn-orphans" #-}

module Control.Monad.ReaderSoup.Katip where

import Control.Monad.ReaderSoup
import Katip
import Katip.Monadic

type instance ContextFromName "katip" = KatipContextTState

instance (Monad m) => SoupContext KatipContextTState m where
  type CtxPrefMonadT KatipContextTState = KatipContextT
  type CtxConstructorArgs KatipContextTState = (LogEnv, Namespace)
  toReaderT (KatipContextT act) = act
  fromReaderT = KatipContextT
  runPrefMonadT _ (e,n) = runKatipContextT e () n

instance (IsInSoup ctxs "katip") => Katip (ReaderSoup ctxs) where
  getLogEnv = picking #katip getLogEnv
  localLogEnv f act = scooping #katip $
    localLogEnv f (pouring #katip act)

instance (IsInSoup ctxs "katip") => KatipContext (ReaderSoup ctxs) where
  getKatipContext = picking #katip getKatipContext
  localKatipContext f act = scooping #katip $
    localKatipContext f (pouring #katip act)
  
  getKatipNamespace = picking #katip getKatipNamespace
  localKatipNamespace f act = scooping #katip $
    localKatipNamespace f (pouring #katip act)
