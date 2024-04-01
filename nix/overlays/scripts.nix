self: super:

with self.pkgs;
let
  moonlight-qt-pipewire = writeScriptBin "moonlight" ''
    # moonlight crashes when run as regular user, but works when run as sudo
    # debugged by comparing the difference in runtime env vars, recorded via:
    # for sudo: sudo /nix/store/fg7gdbmxrijkc2g93dx55b4s4bqg200z-moonlight-qt-5.0.1/bin/moonlight & sudo cat /proc/$(pgrep moonlight)/environ --show-nonprinting | tr '^@' '\n' | tr : '\n' > moonlight_sudo_env_vars.txt
    # for user: /nix/store/fg7gdbmxrijkc2g93dx55b4s4bqg200z-moonlight-qt-5.0.1/bin/moonlight & sudo cat /proc/$(pgrep moonlight)/environ --show-nonprinting | tr '^@' '\n' | tr : '\n' > moonlight_james_env_vars.txt
    # there were many QT related env vardifferences, but $QML2_IMPORT_PATH was set for user, but not sudo.
    # unsetting is "fixed" moonlight launching without sudo
    #
    # this has only been an issue since switching to kde, but there seem to be other issues too:
    # https://discourse.nixos.org/t/appimage-run-fails-loading-qt-platform-plugin-xcb/29293/2
    #
    # for reference, these are the log lines when crashing as user:
    #   > /nix/store/fg7gdbmxrijkc2g93dx55b4s4bqg200z-moonlight-qt-5.0.1/bin/moonlight
    #   > 00:00:00 - SDL Info (0): Compiled with SDL 2.30.0
    #   > 00:00:00 - SDL Info (0): Running with SDL 2.30.0
    #   > 00:00:00 - Qt Info: No translation available for "en_GB"
    #   > 00:00:00 - Qt Warning: QQmlApplicationEngine failed to load component
    #   > 00:00:00 - Qt Warning: qrc:/gui/main.qml:47:5: Type ToolTip unavailable
    #   > 00:00:00 - Qt Warning: file:///nix/store/89v0isbf00114gdsp8b25mkx9r7x3z4d-qtquickcontrols2-5.15.12-bin/lib/qt-5.15.12/qml/QtQuick/Controls.2/Material/qmldir: plugin cannot be loaded for module "QtQuick.Controls.Material": Cannot install element 'Material' into protected module 'QtQuick.Controls.Material' version '2'
    unset QML2_IMPORT_PATH

    # as of 28/02/24 without this env var moonlight audio crashes:
    # 00:00:09 - SDL Info (0): Audio packet queue overflow
    # 00:00:09 - SDL Info (0): Audio packet queue overflow
    # ...
    SDL_AUDIODRIVER=pipewire ${unstable.moonlight-qt}/bin/moonlight
  '';
  toggleRotateScreen = with xorg; writeScriptBin "toggleRotateScreen" ''
    #!${stdenv.shell}
    #
    # rotate_desktop.sh
    # https://gist.github.com/mildmojo/48e9025070a2ba40795c
    #
    # Rotates modern Linux desktop screen and input devices to match. Handy for
    # convertible notebooks. Call this script from panel launchers, keyboard
    # shortcuts, or touch gesture bindings (xSwipe, touchegg, etc.).
    #
    # Using transformation matrix bits taken from:
    #   https://wiki.ubuntu.com/X/InputCoordinateTransformation
    #

    # Configure these to match your hardware (names taken from `xinput` output).
    TOUCHPAD='DLL09FF:01 06CB:CE39 Touchpad'
    TOUCHSCREEN='Wacom HID 48EE Finger'

    function do_rotate
    {
      ${xrandr}/bin/xrandr --output $1 --rotate $2

      TRANSFORM='Coordinate Transformation Matrix'

      case "$2" in
        normal)
          [ ! -z "$TOUCHPAD" ]    && ${xinput}/bin/xinput set-prop "$TOUCHPAD"    "$TRANSFORM" 1 0 0 0 1 0 0 0 1
          [ ! -z "$TOUCHSCREEN" ] && ${xinput}/bin/xinput set-prop "$TOUCHSCREEN" "$TRANSFORM" 1 0 0 0 1 0 0 0 1
          ;;
        inverted)
          [ ! -z "$TOUCHPAD" ]    && ${xinput}/bin/xinput set-prop "$TOUCHPAD"    "$TRANSFORM" -1 0 1 0 -1 1 0 0 1
          [ ! -z "$TOUCHSCREEN" ] && ${xinput}/bin/xinput set-prop "$TOUCHSCREEN" "$TRANSFORM" -1 0 1 0 -1 1 0 0 1
          ;;
        left)
          [ ! -z "$TOUCHPAD" ]    && ${xinput}/bin/xinput set-prop "$TOUCHPAD"    "$TRANSFORM" 0 -1 1 1 0 0 0 0 1
          [ ! -z "$TOUCHSCREEN" ] && ${xinput}/bin/xinput set-prop "$TOUCHSCREEN" "$TRANSFORM" 0 -1 1 1 0 0 0 0 1
          ;;
        right)
          [ ! -z "$TOUCHPAD" ]    && ${xinput}/bin/xinput set-prop "$TOUCHPAD"    "$TRANSFORM" 0 1 0 -1 0 1 0 0 1
          [ ! -z "$TOUCHSCREEN" ] && ${xinput}/bin/xinput set-prop "$TOUCHSCREEN" "$TRANSFORM" 0 1 0 -1 0 1 0 0 1
          ;;
      esac
    }

    XDISPLAY=`${xrandr}/bin/xrandr --current | grep primary | sed -e 's/ .*//g'`
    XROT=`${xrandr}/bin/xrandr --current --verbose | grep primary | egrep -o ' (normal|left|inverted|right) '`

    if [ "$(head -n1 <<< $XROT)" = " normal " ]; then
      ${xorg.xset}/bin/xset s off -dpms
      do_rotate $XDISPLAY "left"
      exit 0
    else
      ${xorg.xset}/bin/xset s on +dpms
      do_rotate $XDISPLAY "normal"
      exit 0
    fi
  '';
in
{
  scripts = [
    moonlight-qt-pipewire
    toggleRotateScreen
  ];
}
