{
  lib,
  pkgs,
  config,
  ...
}:

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

  virtualisation.docker.enable = true;

  programs = {
    dconf.enable = true;
  };

  environment.systemPackages =
    with pkgs;
    let
      copy = pkgs.writeShellScriptBin "copy" ''
        ${pkgs.xclip}/bin/xclip -sel clip
      '';

      hc-ssh = pkgs.writeShellScriptBin "hc_ssh" ''
        ssh-keygen -f "/home/james/.ssh/known_hosts" -R "192.168.5.1"
        ssh -oStrictHostKeyChecking=no root@192.168.5.1
      '';
      hc-ssh-home = pkgs.writeShellScriptBin "hc_ssh_home" ''
        ssh-keygen -f "/home/james/.ssh/known_hosts" -R "192.168.0.59"
        ssh -oStrictHostKeyChecking=no root@192.168.0.59
      '';
      hc-ssh-installer-api = pkgs.writeShellScriptBin "hc_ssh_installer_api" ''
        ssh-keygen -f "/home/james/.ssh/known_hosts" -R "192.168.5.1"
        ssh -oStrictHostKeyChecking=no root@192.168.5.1 'journalctl -fu installer-api'
      '';
      hc-serial = pkgs.writeShellScriptBin "hc_serial" ''
        ${pkgs.minicom}/bin/minicom --device /dev/ttyUSB0 --baudrate 115200 --color on
      '';
      # TODO: switch to FDH2/UxPlay
      airplay = pkgs.writeShellScriptBin "airplay" ''
        ${pkgs.unstable.uxplay}/bin/uxplay -p -reset 0
      '';
      base64Decode = pkgs.writeShellScriptBin "base_64_decode" ''
        ${pkgs.nodePackages.nodejs}/bin/node -e "console.log(Buffer.from(process.argv[1], 'base64').toString('utf8'))" -- "$@"
      '';
      base64Encode = pkgs.writeShellScriptBin "base_64_encode" ''
        ${pkgs.nodePackages.nodejs}/bin/node -e "console.log(Buffer.from(process.argv[1], 'utf8').toString('base64'))" -- "$@"
      '';
    in
    [
      adoptopenjdk-bin
      unstable.ngrok
      unstable.postman
      unstable.libimobiledevice
      airplay
      copy
      hc-serial
      hc-ssh
      hc-ssh-home
      hc-ssh-installer-api
      screen
      base64Decode
      base64Encode
    ];

  networking = {
    firewall = {
      allowedTCPPorts = [
        # metro
        8080
        8081
        9001
        9002
        # uxplay
        7100
        7000
        7001

        # tmp: mitmproxy non-default port (which is 8080) to not conflict with metro
        8082
      ];
      allowedUDPPorts = [
        # metro
        8080
        8081
        9001
        9002
        # uxplay
        6000
        6001
        7011
      ];
    };
  };

  services = {
    # avahi.hostName = "hc";
    kolide-launcher = {
      enable = true;
      enrollSecretDirectory = "/home/james/secrets/kolide-k2";
    };
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
  };
}
