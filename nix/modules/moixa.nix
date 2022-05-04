{ lib, pkgs, config, ... }:

{

  # https://alexbakker.me/post/nixos-pci-passthrough-qemu-vfio.html
  boot.initrd.availableKernelModules = [ "vfio-pci" ];
  # boot.initrd.preDeviceCommands = ''
  #   # 00:14.0 USB controller: Intel Corporation Tiger Lake-LP USB 3.2 Gen 2x1 xHCI Host Controller (rev 20)
  #   DEVS="0000:00:14.0"
  #   for DEV in $DEVS; do
  #     echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
  #   done
  #   modprobe -i vfio-pci
  # '';

  virtualisation.libvirtd = {
    enable = true;
    qemu.ovmf.enable = true;
    onBoot = "ignore";
    onShutdown = "shutdown";
  };

  programs = {
    dconf.enable = true;
  };

  environment.systemPackages = with pkgs;
    let
      hc-ssh = pkgs.writeShellScriptBin "hc_ssh" ''
        ssh-keygen -f "/home/james/.ssh/known_hosts" -R "192.168.0.35"
        ssh -oStrictHostKeyChecking=no root@192.168.0.35
      '';
      hc-serial = pkgs.writeShellScriptBin "hc_serial" ''
        ${pkgs.minicom}/bin/minicom --device /dev/ttyUSB0
      '';
    in
    [
      foreman
      virt-manager
      unstable.quickemu
      unstable.drawio
      unstable.tmate
      unstable.libimobiledevice
      unstable.ifuse
      ntfs3g
      hc-serial
      hc-ssh
    ];

  networking = {
    firewall.allowedTCPPorts = [ 8080 8081 9001 9002 ];
    firewall.allowedUDPPorts = [ 8080 8081 9001 9002 ];
  };

  services = {
    udev = {
      # work keyboards
      extraHwdb = ''
        evdev:name:Logitech USB Keyboard:*
         KEYBOARD_KEY_700e3=leftalt # leftmeta -> leftalt
         KEYBOARD_KEY_700e2=leftmeta # leftalt -> leftmeta

        evdev:name:LiteOn Lenovo Traditional USB Keyboard:*
         KEYBOARD_KEY_700e3=leftalt # leftmeta -> leftalt
         KEYBOARD_KEY_700e2=leftmeta # leftalt -> leftmeta
      '';
    };
    usbmuxd.enable = true;
    xserver.videoDrivers = [
      "modesetting"
    ];
  };
}
