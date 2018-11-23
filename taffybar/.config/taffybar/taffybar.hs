--import System.Taffybar
--
--import System.Taffybar.Systray
--import System.Taffybar.TaffyPager
--import System.Taffybar.SimpleClock
--import System.Taffybar.Battery
--import System.Taffybar.NetMonitor
--import System.Taffybar.FreedesktopNotifications
--import System.Taffybar.MPRIS
--
--import System.Taffybar.Widgets.PollingBar
--import System.Taffybar.Widgets.PollingGraph
--
--import System.Information.Memory
--import System.Information.CPU
--
--memCallback = do
--  mi <- parseMeminfo
--  return [memoryUsedRatio mi]
--
--cpuCallback = do
--  (userLoad, systemLoad, totalLoad) <- cpuLoad
--  return [totalLoad, systemLoad]
--
--main = do
--  let memCfg = defaultGraphConfig { graphDataColors = [(1, 0, 0, 1)]
--                                  , graphLabel = Just "mem"
--                                  }
--      cpuCfg = defaultGraphConfig { graphDataColors = [ (0, 1, 0, 1)
--                                                      , (1, 0, 1, 0.5)
--                                                      ]
--                                  , graphLabel = Just "cpu"
--                                  }
--  let clock = textClockNew Nothing "<span fgcolor='orange'>%a %b %_d %H:%M</span>" 1
--      battery = batteryBarNew defaultBatteryConfig 60
--      net = netMonitorNew 2 "wlp3s0"
--      pager = taffyPagerNew defaultPagerConfig
--      note = notifyAreaNew defaultNotificationConfig
--      mpris = mprisNew defaultMPRISConfig
--      mem = pollingGraphNew memCfg 1 memCallback
--      cpu = pollingGraphNew cpuCfg 0.5 cpuCallback
--      tray = systrayNew
--  defaultTaffybar defaultTaffybarConfig { startWidgets = [ pager, note ]
--                                        , endWidgets = [ tray, clock, mem, cpu, battery, net, mpris ]
--                                        }
-- -*- mode:haskell -*-
{-# LANGUAGE OverloadedStrings #-}
module Main where

import System.Taffybar
import System.Taffybar.Hooks
import System.Taffybar.Information.CPU
import System.Taffybar.Information.Memory
import System.Taffybar.SimpleConfig
import System.Taffybar.Widget
import System.Taffybar.Widget.Generic.PollingGraph
import System.Taffybar.Widget.Generic.PollingLabel
import System.Taffybar.Widget.Text.NetworkMonitor
import System.Taffybar.Widget.Util
import System.Taffybar.Widget.Workspaces

transparent = (0.0, 0.0, 0.0, 0.0)
yellow1 = (0.9453125, 0.63671875, 0.2109375, 1.0)
yellow2 = (0.9921875, 0.796875, 0.32421875, 1.0)
green1 = (0, 1, 0, 1)
green2 = (1, 0, 1, 0.5)
taffyBlue = (0.129, 0.588, 0.953, 1)

myGraphConfig =
  defaultGraphConfig
  { graphPadding = 0
  , graphBorderWidth = 0
  , graphWidth = 75
  , graphBackgroundColor = transparent
  }

netCfg = myGraphConfig
  { graphDataColors = [yellow1, yellow2]
  , graphLabel = Just "net"
  }

memCfg = myGraphConfig
  { graphDataColors = [taffyBlue]
  , graphLabel = Just "mem"
  }

cpuCfg = myGraphConfig
  { graphDataColors = [green1, green2]
  , graphLabel = Just "cpu"
  }

memCallback :: IO [Double]
memCallback = do
  mi <- parseMeminfo
  return [memoryUsedRatio mi]

cpuCallback = do
  (_, systemLoad, totalLoad) <- cpuLoad
  return [totalLoad, systemLoad]

main = do
  let myWorkspacesConfig =
        defaultWorkspacesConfig
        { minIcons = 1
        , widgetGap = 0
        , showWorkspaceFn = hideEmpty
        }
      workspaces = workspacesNew myWorkspacesConfig
      cpu = pollingGraphNew cpuCfg 0.5 cpuCallback
      mem = pollingGraphNew memCfg 1 memCallback
      net = networkGraphNew netCfg Nothing
      clock = textClockNew Nothing "%a %b %_d %r" 1
      layout = layoutNew defaultLayoutConfig
      windows = windowsNew defaultWindowsConfig
          -- See https://github.com/taffybar/gtk-sni-tray#statusnotifierwatcher
          -- for a better way to set up the sni tray
      tray = sniTrayThatStartsWatcherEvenThoughThisIsABadWayToDoIt
      myConfig = defaultSimpleTaffyConfig
        { startWidgets =
            workspaces : map (>>= buildContentsBox) [ layout, windows ]
        , endWidgets = map (>>= buildContentsBox)
          [ textBatteryNew "$percentage$%_$status$($time$)"
          , clock
          , tray
          , cpu
          , mem
          , net
          , networkMonitorNew defaultNetFormat Nothing
          , mpris2New
          ]
        , barPosition = Top
        , barPadding = 0
        , barHeight = 25
        , widgetSpacing = 0
        }
  dyreTaffybar $ withBatteryRefresh $ withLogServer $ withToggleServer $ toTaffyConfig myConfig
