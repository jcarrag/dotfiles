{-# OPTIONS_GHC -fno-warn-missing-signatures #-}

-------------------------------------------------------------------------------
--                                                                           --
-- XMonad Configuration                                                      --
--                                                                           --
----------------------------------------------------------------------------}}}
-- IMPORTS                                                                  {{{
-------------------------------------------------------------------------------
import           Data.Default                        (def)
import qualified Data.Map                            as M
import           Data.Monoid                         (Endo)
import           System.IO                           (hClose)
import           System.Taffybar.Support.PagerHints  (pagerHints)

import           XMonad                              hiding ((|||))

import           XMonad.Actions.ConditionalKeys      (XCond (..), bindOn)
import           XMonad.Actions.CycleWS
import           XMonad.Actions.DynamicProjects      (Project (..),
                                                      dynamicProjects)
import           XMonad.Actions.DynamicWorkspaces
import           XMonad.Actions.MessageFeedback      (tryMessage_)
import           XMonad.Actions.Navigation2D
import           XMonad.Actions.Promote
import           XMonad.Actions.SpawnOn              (manageSpawn, spawnOn)
import           XMonad.Actions.WithAll              (killAll, sinkAll)

import           XMonad.Hooks.EwmhDesktops           (ewmh)
import           XMonad.Hooks.FadeWindows
import           XMonad.Hooks.InsertPosition
import           XMonad.Hooks.ManageDocks
import           XMonad.Hooks.ManageHelpers
import           XMonad.Hooks.SetWMName

import           XMonad.Layout.Accordion
import           XMonad.Layout.BinarySpacePartition
import           XMonad.Layout.DecorationMadness
import           XMonad.Layout.Fullscreen
import           XMonad.Layout.Gaps
import           XMonad.Layout.Hidden
import           XMonad.Layout.LayoutCombinators
import           XMonad.Layout.MultiToggle
import           XMonad.Layout.MultiToggle.Instances
import           XMonad.Layout.NoFrillsDecoration
import           XMonad.Layout.PerScreen
import           XMonad.Layout.Reflect
import           XMonad.Layout.Renamed
import           XMonad.Layout.ResizableTile
import           XMonad.Layout.ShowWName
import           XMonad.Layout.Simplest
import           XMonad.Layout.Spacing
import           XMonad.Layout.SubLayouts
import           XMonad.Layout.Tabbed
import           XMonad.Layout.ThreeColumns
import           XMonad.Layout.WindowNavigation

import           XMonad.Prompt
import           XMonad.Prompt.ConfirmPrompt

import qualified XMonad.StackSet                     as W

import           XMonad.Util.EZConfig                (mkNamedKeymap)
import           XMonad.Util.NamedActions            (NamedAction (..),
                                                      addDescrKeys', addName,
                                                      showKm, subtitle, (^++^))
import           XMonad.Util.NamedScratchpad
import           XMonad.Util.Run                     (hPutStr, spawnPipe)
import           XMonad.Util.WorkspaceCompare        (getSortByIndex)
import           XMonad.Util.XSelection              (getSelection)

----------------------------------------------------------------------------}}}
-- Main                                                                     {{{
-------------------------------------------------------------------------------
main :: IO ()
main =
  xmonad $
  addDescrKeys' ((myModMask, xK_F1), showKeybindings) myKeys $
  dynamicProjects projects $
  docks $ ewmh $ pagerHints $ withNavigation2DConfig myNav2DConfig $ myConfig

myConfig =
  def
    { borderWidth = myBorderWidth
    , clickJustFocuses = myClickJustFocuses
    , focusFollowsMouse = myFocusFollowsMouse
    , normalBorderColor = myNormalBorderColor
    , focusedBorderColor = myFocusedBorderColor
    , manageHook = myManageHook
    , handleEventHook = myHandleEventHook
    , layoutHook = myLayoutHook
    , logHook = myLogHook
    , modMask = myModMask
    , mouseBindings = myMouseBindings
    , startupHook = myStartupHook
    , terminal = command myTerminal
    , workspaces = myWorkspaces
    }

myMouseBindings = mouseBindings def

myStartupHook = startupHook def >> setWMName "LG3D"

----------------------------------------------------------------------------}}}
-- theme                                                                    {{{
-------------------------------------------------------------------------------
myClickJustFocuses = False

myFocusFollowsMouse = False

-- colors
base03 = "#002b37"

base02 = "#0f111a"

base00 = "#657b83"

yellow = "#b58900"

blue = "#dc322f"--"#268bd2"

black = "#000000"

white = "#ffffff"

cActive = base03

-- sizes
sGap = 10

sBorder = 0

sPrompt = 26

sStatus = 20

myBorderWidth = 0

myNormalBorderColor = black

myFocusedBorderColor = cActive

myFont = "-*-hack-medium-*-*-*-*-360-*-*-*-*-*-*"

tPrompt =
  def
    { font = myFont
    , bgColor = base03
    , fgColor = cActive
    , fgHLight = base03
    , bgHLight = cActive
    , borderColor = base03
    , promptBorderWidth = 0
    , height = sPrompt
    , position = Top
    }

tHotPrompt = tPrompt {bgColor = yellow, fgColor = base03}

tShowWName = def {swn_fade = 0.5, swn_bgcolor = black, swn_color = white}

tTab =
  def
    { fontName = myFont
    , activeColor = cActive
    , inactiveColor = base02
    , activeBorderColor = cActive
    , inactiveBorderColor = base02
    , activeTextColor = white
    , inactiveTextColor = base00
    }

----------------------------------------------------------------------------}}}
-- Workspaces                                                               {{{
-------------------------------------------------------------------------------
wsTERM = "TERM"

wsWEB = "WEB"

wsCOM = "COM"

wsWORKTERM = "WRK:TERM"

wsWORKWEB = "WRK:WEB"

wsMEDIA = "MEDIA"

wsMONITOR = "MONITOR"

wsSYSTEM = "SYSTEM"

wsTEMP = "TEMP"

wsNSP = "NSP"

myWorkspaces =
  [ wsTERM
  , wsWEB
  , wsCOM
  , wsWORKTERM
  , wsWORKWEB
  , wsMEDIA
  , wsMONITOR
  , wsSYSTEM
  , wsTEMP
  , wsNSP
  ]

projects :: [Project]
projects =
  [ Project
      { projectName = wsTERM
      , projectDirectory = "~/"
      , projectStartHook = Just $ spawnOn wsTERM (command myTerminal)
      }
  , Project
      { projectName = wsWEB
      , projectDirectory = "~/"
      , projectStartHook = Just $ spawnOn wsWEB (command myBrowser)
      }
  , Project
      { projectName = wsWORKTERM
      , projectDirectory = "~/"
      , projectStartHook = Just $ spawnOn wsWORKTERM (command myTerminal)
      }
  , Project
      { projectName = wsMONITOR
      , projectDirectory = "~/"
      , projectStartHook = Just $ spawnOn wsMONITOR (command glances)
      }
  ]

----------------------------------------------------------------------------}}}
-- Bindings                                                                 {{{
-------------------------------------------------------------------------------
myModMask = mod4Mask

myKeys config
    -- You can get the key code using `xev`
    ---------------------------------------------------------------------------
    -- | Actions
    ---------------------------------------------------------------------------
 =
  keySet "Actions" [] ^++^
    ---------------------------------------------------------------------------
    -- | Audio
    ---------------------------------------------------------------------------
  keySet
    "Audio"
    [ key "Play" "<XF86AudioPlay>" $ spawn "playerctl play-pause"
    , key "Previous" "<XF86AudioPrev>" $ spawn "playerctl previous"
    , key "Next" "<XF86AudioNext>" $ spawn "playerctl next"
    , key "Mute" "<XF86AudioMute>" $
      spawn "pactl set-sink-mute @DEFAULT_SINK@ toggle"
    , key "Raise Volume" "<XF86AudioRaiseVolume>" $
      spawn "pactl set-sink-volume @DEFAULT_SINK@ +5%"
    , key "Lower Volume" "<XF86AudioLowerVolume>" $
      spawn "pactl set-sink-volume @DEFAULT_SINK@ -5%"
    ] ^++^
    ---------------------------------------------------------------------------
    -- | Launchers
    ---------------------------------------------------------------------------
  keySet
    "Launchers"
    [ key "Launcher" "M-e" $ spawn myLauncher
    , key "SudoLauncher" "M-S-e" $ spawn mySudoLauncher
    , key "Terminal" "M-<Return>" $ spawnApp myTerminal
    , key "Browser" "M-/" $ spawnApp myBrowser
    , key "Spotify" "M-=" $ namedScratchpadAction myScratchpads "spotify"
    , key "Mixer" "M--" $ namedScratchpadAction myScratchpads "alsamixer"
    , key "Console" "M-<Esc>" $ namedScratchpadAction myScratchpads "console"
    , key "VLC" "M-x v" $ namedScratchpadAction myScratchpads "vlc"
    , key "Slack" "M-s" $
      bindOn
        WS
        [ (wsWORKTERM, namedScratchpadAction myScratchpads "workSlack")
        , (wsWORKWEB, namedScratchpadAction myScratchpads "workSlack")
        ]
    , key "Calendar" "M-c" $
      bindOn
        WS
        [ (wsWORKTERM, namedScratchpadAction myScratchpads "workCalendar")
        , (wsWORKWEB, namedScratchpadAction myScratchpads "workCalendar")
        , ("", namedScratchpadAction myScratchpads "personalCalendar")
        ]
    , key "Mail" "M-m" $
      bindOn
        WS
        [ (wsWORKTERM, namedScratchpadAction myScratchpads "workMail")
        , (wsWORKWEB, namedScratchpadAction myScratchpads "workMail")
                                                                                  -- , ("", namedScratchpadAction myScratchpads "personalMail")
        ]
    , key "Trello" "M-t" $
      bindOn
        WS
        [ (wsWORKTERM, namedScratchpadAction myScratchpads "workTrello")
        , (wsWORKWEB, namedScratchpadAction myScratchpads "workTrello")
        , ("", namedScratchpadAction myScratchpads "personalTrello")
        ]
    ] ^++^
    ---------------------------------------------------------------------------
    -- | Layouts
    ---------------------------------------------------------------------------
  keySet
    "Layouts"
    [ key "Cycle all layouts" "M-<Tab>" $ sendMessage NextLayout
    , key "Cycle sublayout" "M-C-<Tab>" $ toSubl NextLayout
      -- , key "Reset layout"                          "M-S-<Tab>"       $ setLayout $ XMonad.layoutHook conf
    , key "Float tiled window" "M-y" $ withFocused toggleFloat
    , key "Tile all floating windows" "M-S-y" $ sinkAll
    , key "Fullscreen" "M-f" $
      sendMessage $ XMonad.Layout.MultiToggle.Toggle FULL
    , key "Decrease master windows" "M-," $ sendMessage $ IncMasterN (-1)
    , key "Increase master windows" "M-." $ sendMessage $ IncMasterN 1
    , key "Reflect/Rotate" "M-r" $
      tryMessageR Rotate (XMonad.Layout.MultiToggle.Toggle REFLECTX)
    ] ^++^
    ---------------------------------------------------------------------------
    -- | Resizing
    ---------------------------------------------------------------------------
  keySet
    "Resizing"
    [ key "Expand (L on BSP)" "M-[" $ tryMessageR (ExpandTowards L) Shrink
    , key "Expand (R on BSP)" "M-]" $ tryMessageR (ExpandTowards R) Expand
    , key "Expand (U on BSP)" "M-S-[" $
      tryMessageR (ExpandTowards U) MirrorShrink
    , key "Expand (D on BSP)" "M-S-]" $
      tryMessageR (ExpandTowards D) MirrorExpand
    , key "Shrink (L on BSP)" "M-C-[" $ tryMessageR (ShrinkFrom R) Shrink
    , key "Shrink (R on BSP)" "M-C-]" $ tryMessageR (ShrinkFrom L) Expand
    , key "Shrink (U on BSP)" "M-C-S-[" $
      tryMessageR (ShrinkFrom D) MirrorShrink
    , key "Shrink (D on BSP)" "M-C-S-]" $
      tryMessageR (ShrinkFrom U) MirrorExpand
    ] ^++^
    ---------------------------------------------------------------------------
    -- | System
    ---------------------------------------------------------------------------
  keySet
    "System"
    [ key "Restart XMonad" "M-q" $ spawn "xmonad --restart"
    , key "Rebuild & Restart XMonad" "M-C-q" $
      spawn "xmonad --recompile && xmonad --restart"
    , key "Lock Screen" "M-S-=" $
      spawn "pkill -x -SIGUSR1 dunst" >> spawn "alock"
    ] ^++^
    ---------------------------------------------------------------------------
    -- | Workspaces and Projects
    ---------------------------------------------------------------------------
  keySet
    "Workspaces & Projects"
    ([ key "Previous Non-Empty Workspace" "M-S-," $ prevNonEmptyWS
     , key "Next Non-Empty Workspace" "M-S-." $ nextNonEmptyWS
     ] ++
     keys "View Workspace" "M-" wsKeys (withNthWorkspace W.greedyView) [0 ..] ++
     keys
       "Move window to Workspace"
       "M-C-"
       wsKeys
       (withNthWorkspace W.shift)
       [0 ..]) ^++^
    ---------------------------------------------------------------------------
    -- | Screens
    ---------------------------------------------------------------------------
  keySet
    "Screens"
    ([] ++
     keys "Navigate Screens" "M-" arrowKeys (flip screenGo True) dirs ++
     keys
       "Move Window to Screen"
       "M-C-"
       arrowKeys
       (flip windowToScreen True)
       dirs ++
     keys
       "Swap Workspace to Screen"
       "M-S-C-"
       arrowKeys
       (flip screenSwap True)
       dirs) ^++^
    ---------------------------------------------------------------------------
    -- | Windows
    ---------------------------------------------------------------------------
  keySet
    "Windows"
    ([ key "Kill" "M-<Backspace>" $ kill
     , key "Kill All" "M-S-<Backspace" $
       confirmPrompt tHotPrompt "kill all" $ killAll
     , key "Promote" "M-b" $ promote
     , key "Switch to window" "M-w" $ spawn "rofi -show window"
     , key "Un-merge from Sublayout" "M-g" $ withFocused (sendMessage . UnMerge)
     , key "Merge all into Sublayout" "M-S-g" $
       withFocused (sendMessage . MergeAll)
     , key "Focus Master" "M-z m" $ windows W.focusMaster
      -- , ("M-z u"            , addName "Focus urgent"                 $ focusUrgent)
     , key "Navigate Tabs Down" "M-'" $
       bindOn LD [("Tabs", windows W.focusDown), ("", onGroup W.focusDown')]
     , key "Navigate Tabs Up" "M-;" $
       bindOn LD [("Tabs", windows W.focusUp), ("", onGroup W.focusUp')]
     , key "Swap Tab Down" "M-C-'" $ windows W.swapDown
     , key "Swap Tab Up" "M-C-;" $ windows W.swapUp
     ] ++
     keys "Navigate Window" "M-" dirKeys (flip windowGo True) dirs ++
     keys "Move Window" "M-C-" dirKeys (flip windowSwap True) dirs ++
     keys "Merge with Sublayout" "M-S-" dirKeys (sendMessage . pullGroup) dirs)
  where
    keySet s ks = subtitle s : mkNamedKeymap config ks
    key n k a = (k, addName n a)
    keys n m ks a args = zipWith (\k arg -> key n (m ++ k) (a arg)) ks args
    dirKeys = ["j", "k", "h", "l"]
    dirs = [D, U, L, R]
    wsKeys = map show [1 .. 9] -- ++ [0]
    arrowKeys = ["<D>", "<U>", "<L>", "<R>"]
    withSelection cmd = getSelection >>= spawn . cmd
    spawnApp = spawn . command
    zipM m nm ks as f = zipWith (\k d -> key nm (m ++ k) (f d)) ks as
    toggleFloat w =
      windows $ \s ->
        if M.member w (W.floating s)
          then W.sink w s
          else W.float w (W.RationalRect (1 / 5) (1 / 5) (3 / 5) (7 / 10)) s
    tryMessageR x y = sequence_ [tryMessage_ x y, refresh]
    nextNonEmptyWS =
      findWorkspace getSortByIndexNoSP Next HiddenNonEmptyWS 1 >>= \t ->
        (windows . W.view $ t)
    prevNonEmptyWS =
      findWorkspace getSortByIndexNoSP Prev HiddenNonEmptyWS 1 >>= \t ->
        (windows . W.view $ t)
    getSortByIndexNoSP =
      fmap (. namedScratchpadFilterOutWorkspace) getSortByIndex

showKeybindings :: [((KeyMask, KeySym), NamedAction)] -> NamedAction
showKeybindings x =
  addName "Show Keybindings" $
  io $ do
    h <- spawnPipe "zenity --text-info --font=terminus"
    hPutStr h (unlines $ showKm x)
    hClose h
    return ()

----------------------------------------------------------------------------}}}
-- Applications                                                             {{{
-------------------------------------------------------------------------------
data App
  = ClassApp String
             String
  | ResourceApp String
                String

command :: App -> String
command (ClassApp c _)    = c
command (ResourceApp c _) = c

isInstance :: App -> Query Bool
isInstance (ClassApp _ c)    = className =? c
isInstance (ResourceApp _ r) = resource =? r

myBrowser = ClassApp "browser" "brave"

myTerminal = ClassApp "kitty" "kitty"

spotify = ClassApp "spotify" "Spotify"

alsamixer =
  ClassApp "kitty --class alsamixer --title alsamixer alsamixer" "alsamixer"

vlc = ResourceApp "vlc" "vlc"

workSlack =
  ResourceApp
    "dex $HOME/.local/share/applications/WorkSlack.desktop"
    "crx_nfjipldfidfkljfhmnjigbhfljfpemba"

workCalendar =
  ResourceApp
    "dex $HOME/.local/share/applications/WorkCalendar.desktop"
    "crx_kjbdgfilnfhdoflbpgamdcdgpehopbep"

workMail =
  ResourceApp
    "dex $HOME/.local/share/applications/WorkMail.desktop"
    "crx_kmhopmchchfpfdcdjodmpfaaphdclmlj"

workTrello =
  ResourceApp
    "dex $HOME/.local/share/applications/WorkTrello.desktop"
    "crx_mpdjpnmmnkoappfachmpbalmgmdnmgij"

personalCalendar =
  ResourceApp
    "dex $HOME/.local/share/applications/PersonalCalendar.desktop"
    "crx_cekbafhmingmmacionoegcmednbmapkh"

-- personalMail      = ResourceApp  "dex $HOME/.local/share/applications/PersonalMail.desktop"     "crx_kmhopmchchfpfdcdjodmpfaaphdclmlj"
personalTrello =
  ResourceApp
    "dex $HOME/.local/share/applications/PersonalTrello.desktop"
    "crx_pkheepclhaffooboabnelkgnboncfbbf"

console = ClassApp "kitty --class console --title console" "console"

glances = ClassApp "kitty --class glances --title glances glances" "glances"

myLauncher = "rofi -matching fuzzy -modi combi -show combi -combi-modi run,drun"

mySudoLauncher = "SUDO_ASKPASS=/home/james/bin/askpass-rofi " ++ myLauncher ++ " -run-command 'sudo -A {cmd}'"

myScratchpads =
  [ scratchpadApp "spotify" spotify defaultFloating
  , scratchpadApp
      "alsamixer"
      alsamixer
      (customFloating $ W.RationalRect (1 / 6) (1 / 6) (2 / 3) (2 / 3))
  , scratchpadApp "vlc" vlc defaultFloating
  , scratchpadApp
      "console"
      console
      (customFloating $ W.RationalRect 0 0 1 (1 / 2))
  , scratchpadApp "workSlack" workSlack defaultFloating
  , scratchpadApp "workCalendar" workCalendar defaultFloating
  , scratchpadApp "workMail" workMail defaultFloating
  , scratchpadApp "workTrello" workTrello defaultFloating
  , scratchpadApp "personalCalendar" personalCalendar defaultFloating
  -- , scratchpadApp "personalMail"     personalMail     defaultFloating
  , scratchpadApp "personalTrello" personalTrello defaultFloating
  ]
  where
    scratchpadApp :: String -> App -> Query (Endo WindowSet) -> NamedScratchpad
    scratchpadApp n a f = NS n (command a) (isInstance a) f

----------------------------------------------------------------------------}}}
-- Navigation                                                               {{{
-------------------------------------------------------------------------------
myNav2DConfig =
  def
    { defaultTiledNavigation = centerNavigation
    , floatNavigation = centerNavigation
    , screenNavigation = lineNavigation
    , layoutNavigation = [("Full", centerNavigation)]
    , unmappedWindowRect = [("Full", singleWindowRect)]
    }

----------------------------------------------------------------------------}}}
-- Layouts                                                                  {{{
-------------------------------------------------------------------------------
myLayoutHook =
  showWorkspaceName $
  fullscreenFloat $
  fullScreenToggle $ mirrorToggle $ reflectToggle $ flex ||| tabs
  where
    showWorkspaceName = showWName' tShowWName
    fullScreenToggle = mkToggle (single FULL)
    mirrorToggle = mkToggle (single MIRROR)
    reflectToggle = mkToggle (single REFLECTX)
    -- Flex Layout
    flex =
      trimNamed 5 "Flex" $
      avoidStruts $
      windowNavigation $
      addTabs shrinkText tTab $
      subLayout [] (Simplest ||| Accordion) $
      ifWider smallMonitorWidth wideLayouts standardLayouts
    smallMonitorWidth = 1920
    wideLayouts =
      myGaps $
      mySpacing $
      (suffixed "Wide 3 Column" $ ThreeColMid 1 (1 / 20) (1 / 2)) |||
      (trimSuffixed 1 "Wide BSP" $ hiddenWindows emptyBSP)
    standardLayouts =
      myGaps $
      mySpacing $
      (suffixed "Standard 2/3" $ ResizableTall 1 (1 / 20) (2 / 3) []) |||
      (suffixed "Standard 1/2" $ ResizableTall 1 (1 / 20) (1 / 2) []) |||
      (trimSuffixed 1 "Standard BSP" $ hiddenWindows emptyBSP)
    -- Tabs Layout
    tabs =
      named "Tabs" $
      avoidStruts $ addTabs shrinkText tTab $ Simplest
    named n = renamed [(XMonad.Layout.Renamed.Replace n)]
    trimNamed w n =
      renamed
        [ (XMonad.Layout.Renamed.CutWordsLeft w)
        , (XMonad.Layout.Renamed.PrependWords n)
        ]
    suffixed n = renamed [(XMonad.Layout.Renamed.AppendWords n)]
    trimSuffixed w n =
      renamed
        [ (XMonad.Layout.Renamed.CutWordsRight w)
        , (XMonad.Layout.Renamed.AppendWords n)
        ]
    --addTopBar = noFrillsDeco shrinkText tTopBar
    myGaps = gaps [(U, sGap), (D, sGap), (L, sGap), (R, sGap)]
    mySpacing = spacing sGap

----------------------------------------------------------------------------}}}
-- LogHook                                                                  {{{
-------------------------------------------------------------------------------
myLogHook = fadeWindowsLogHook myFadeHook

myFadeHook =
  composeAll
    [ opaque
    , isUnfocused --> opacity 0.85
    , isInstance myTerminal <&&> isUnfocused --> opacity 0.9
    , (isInstance workSlack <||> isInstance workCalendar <||>
       isInstance workMail <||>
       isInstance workTrello) <&&>
      isUnfocused -->
      opaque
    , (isInstance personalCalendar <||> isInstance personalTrello) <&&>
      isUnfocused -->
      opaque
    , isInstance console --> opacity 0.9
    , isDialog --> opaque
    ]

----------------------------------------------------------------------------}}}
-- ManageHook                                                               }}}
-------------------------------------------------------------------------------
myManageHook :: ManageHook
myManageHook = manageApps <+> manageScratchpads <+> manageSpawn <+> manageDocks
  where
    manageApps =
      composeOne
      -- Applications
        [ isInstance vlc -?> doFloat
        , isInstance spotify -?> doFloat
      -- Dialogs
        , isBrowserDialog -?> forceCenterFloat
        , isFileChooserDialog -?> forceCenterFloat
        , isDialog -?> doCenterFloat
        , isPopup -?> doCenterFloat
        , isSplash -?> doCenterFloat
      -- Other
        , transience
        , isFullscreen -?> doFullFloat
        , pure True -?> tileBelow
        ]
    isBrowserDialog = isDialog <&&> isInstance myBrowser
    isFileChooserDialog = isRole =? "GtkFileChooserDialog"
    isPopup = isRole =? "pop-up"
    isSplash = isInProperty "_NET_WM_WINDOW_TYPE" "_NET_WM_WINDOW_TYPE_SPLASH"
    isRole = stringProperty "WM_WINDOW_ROLE"
    tileBelow = insertPosition Below Newer
    manageScratchpads = namedScratchpadManageHook myScratchpads
    forceCenterFloat = doFloatDep move
      where
        move :: W.RationalRect -> W.RationalRect
        move _ = W.RationalRect x y w h
        w, h, x, y :: Rational
        w = 1 / 3
        h = 1 / 2
        x = (1 - w) / 2
        y = (1 - h) / 2

----------------------------------------------------------------------------}}}
-- HandleEventHook                                                          {{{
-------------------------------------------------------------------------------
myHandleEventHook =
  fadeWindowsEventHook <+>
  handleEventHook def <+> XMonad.Layout.Fullscreen.fullscreenEventHook
----------------------------------------------------------------------------}}}
