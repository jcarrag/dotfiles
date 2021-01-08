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
  };
}
