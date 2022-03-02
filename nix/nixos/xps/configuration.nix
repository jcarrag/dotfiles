# XPS 13 9310 2-in-1
{ config, pkgs, ... }:

{
  services = {
    udev = {
      # swap left alt with meta on magic keyboard
      extraHwdb = ''
        evdev:input:b0011v0001p0001*
          KEYBOARD_KEY_db=leftalt
          KEYBOARD_KEY_38=leftmeta
      '';
    };
    xserver.videoDrivers = [
      "modesetting"
    ];
  };

  users.extraGroups.vboxusers.members = [ "james" ];
}
