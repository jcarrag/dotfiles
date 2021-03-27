self: super:

with self.pkgs;
let
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
  scripts = {
    inherit toggleRotateScreen;
    all = [
      toggleRotateScreen
    ];
  };
}
