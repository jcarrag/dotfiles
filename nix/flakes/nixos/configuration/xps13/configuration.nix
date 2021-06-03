# XPS 13 9310 2-in-1
{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ../base-configuration.nix
    ];

  networking.hostName = "james";

  services = {
    udev = {
      # swap left alt with meta on keyboard
      extraHwdb = ''
        evdev:input:b0011v0001p0001*
          KEYBOARD_KEY_db=leftalt
          KEYBOARD_KEY_38=leftmeta
      '';
    };
    xserver.videoDrivers = [
      "amdgpu"
      "modesetting"
    ];
  };

  users.extraGroups.vboxusers.members = [ "james" ];
}
