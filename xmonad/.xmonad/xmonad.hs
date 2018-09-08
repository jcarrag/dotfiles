import System.IO (hClose)

import XMonad
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.ManageDocks
import XMonad.Util.EZConfig (mkNamedKeymap)
import XMonad.Util.NamedActions (NamedAction(..), addDescrKeys, (^++^), subtitle, addName, showKm)
import XMonad.Util.Run (spawnPipe, hPutStr)
import System.Taffybar.Hooks.PagerHints (pagerHints)

main = 
  xmonad
  $ addDescrKeys ((mod4Mask, xK_F1), showKeybindings) myKeys
  $ docks
  $ ewmh
  $ pagerHints
  $ myConfig
  
myConfig = def
    { terminal = "kitty"
    , modMask = mod4Mask
    , borderWidth = 3
    , startupHook = spawn "taffybar"
    }

myKeys config =
   keySet "Launchers"
     [ key "Launcher" "M-<Space>" $ spawn myLauncher
     ]
   ^++^
   keySet "Audio"
     [ key "Mute"         "<XF86AudioMute>"        $ spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle"
     , key "Raise Volume" "<XF86AudioRaiseVolume>" $ spawn "pactl set-sink-volume @DEFAULT_SINK@ +5%"
     , key "Lower Volume" "<XF86AudioLowerVolume>" $ spawn "pactl set-sink-volume @DEFAULT_SINK@ -5%"
     ]
   ^++^
   keySet "Windows"
     [ key "Kill"             "M-<Backspace>"   $ kill
     , key "Switch to window" "M-w"             $ spawn "rofi -show window"
     ]
   where
     keySet s ks = subtitle s : mkNamedKeymap config ks
     key n k a = (k, addName n a)

showKeybindings :: [((KeyMask, KeySym), NamedAction)] -> NamedAction
showKeybindings x = addName "Show Keybindings" $ io $ do
  h <- spawnPipe "zenity --text-info --font=terminus"
  hPutStr h (unlines $ showKm x)
  hClose h
  return ()

myLauncher = "rofi -matching fuzzy -modi combi -show combi -combi-modi run,drun"

