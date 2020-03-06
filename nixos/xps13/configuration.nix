{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../base-configuration.nix
    ];

  services.xserver = {
    xrandrHeads = [
      { output = "eDP-1";
        primary = true;
        monitorConfig = ''
          Option "PreferredMode" "2048x1152"
          Option "Position" "4000 984"
        '';
      }
      { output = "DP-1";
        monitorConfig = ''
          Option "PreferredMode" "2560x1440"
          Option "Position" "1440 496"
        '';
      }
      { output = "DP-2";
        monitorConfig = ''
          Option "PreferredMode" "2560x1440"
          Option "Position" "0 0"
	  Option "Rotate" "right"
        '';
      }
    ];
    resolutions = [
      { x = 2048; y = 1152; }
      { x = 1920; y = 1080; }
      { x = 2560; y = 1440; }
      { x = 3072; y = 1728; }
      { x = 3840; y = 2160; }
    ];
  };
}
