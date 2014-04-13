#include "SDL_mixer.h"
module Sound.SDL.Mixer
  ( version
  , initFLAC
  , initMOD
  , initMODPLUG
  , initMP3
  , initOGG
  , initFLUIDSYNTH
  , init
  , quit
  , openAudio
  , allocateChannels
  ) where

import Foreign
import Prelude hiding (init)
import Graphics.UI.SDL.Audio (AudioFormat(..), fromAudioFormat)
import Graphics.UI.SDL.Error (getError)

-- Error handling until something better is decided on in the main lib.
handleErrorI :: (Num a, Ord a) => String -> a -> (a -> IO b) -> IO b
handleErrorI fname i fn
  | i < 0     = fn i
  | otherwise = (\err -> error $ fname ++ ": " ++ show err) =<< getError
{-# INLINE handleErrorI #-}

-- | (Major, Minor, Patchlevel)
version :: (Int, Int, Int)
version = ( #{const SDL_MIXER_MAJOR_VERSION}
          , #{const SDL_MIXER_MINOR_VERSION}
          , #{const SDL_MIXER_PATCHLEVEL}
          )

newtype MixInitFlag
      = MixInitFlag { unwrapMixInitFlag :: #{type int} }

#{enum MixInitFlag, MixInitFlag
 , initFLAC = MIX_INIT_FLAC
 , initMOD = MIX_INIT_MOD
 , initMODPLUG = MIX_INIT_MODPLUG
 , initMP3 = MIX_INIT_MP3
 , initOGG = MIX_INIT_OGG
 , initFLUIDSYNTH = MIX_INIT_FLUIDSYNTH
 }

combineMixInitFlag :: [MixInitFlag] -> MixInitFlag
combineMixInitFlag = MixInitFlag . foldr ((.|.) . unwrapMixInitFlag) 0

foreign import ccall unsafe "Mix_Init"
  mixInit' :: #{type int} -> IO ()

init :: [MixInitFlag] -> IO ()
init flags =
  let flags' = unwrapMixInitFlag $ combineMixInitFlag flags
  in mixInit' flags'

foreign import ccall unsafe "Mix_Quit"
  quit :: IO ()

foreign import ccall unsafe "Mix_OpenAudio"
  mixOpenAudio' :: #{type int} -> #{type Uint16} -> #{type int} -> #{type int} -> IO #{type int}

openAudio :: Int -> AudioFormat -> Int -> Int -> IO ()
openAudio freq format channels chunksize = do
  let freq'      = fromIntegral freq
      format'    = fromAudioFormat format
      channels'  = fromIntegral channels
      chunksize' = fromIntegral chunksize
  ret <- mixOpenAudio' freq' format' channels' chunksize'
  handleErrorI "openAudio" ret (const $ return ())

foreign import ccall unsafe "Mix_AllocateChannels"
  mixAllocateChannels' :: #{type int} -> IO #{type int}

allocateChannels :: Int -> IO ()
allocateChannels numchans = do
  ret <- mixAllocateChannels' (fromIntegral numchans)
  handleErrorI "allocateChannels" ret (const $ return ())
