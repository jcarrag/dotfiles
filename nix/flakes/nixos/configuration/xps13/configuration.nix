{ config, pkgs, unstable, colour, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../base-configuration.nix
    ];
  _module.args.unstable = unstable;
  _module.args.colour = colour;

  services = {
    udev = {
      # swap left alt with meta on keyboard
      extraHwdb = ''
        evdev:input:b0011v0001p0001*
          KEYBOARD_KEY_db=leftalt
          KEYBOARD_KEY_38=leftmeta
      '';
    };
    xserver = {
      xrandrHeads = [
        {
          output = "eDP-1";
          primary = true;
          monitorConfig = ''
            Option "PreferredMode" "1920x1200"
            Option "Position" "3840 437"
          '';
        }
        {
          output = "DP-1";
          monitorConfig = ''
            Option "PreferredMode" "3840x2160"
            Option "Position" "0 0"
          '';
        }
      ];
    };
  };
}
