# XPS 13 9320
{ pkgs, ... }:

{
  boot.initrd.luks.devices."luks-b6ee5065-b576-407b-9419-4651b91daad9".device = "/dev/disk/by-uuid/b6ee5065-b576-407b-9419-4651b91daad9";
  # 20/09/24: pipewire broken for linux 6.10.{8,9}
  # https://bbs.archlinux.org/viewtopic.php?pid=2194400#p2194400
  # already fixed upstream, waiting for nixpkgs
  # TODO: remove when fix released into nixpkgs
  boot.kernelPatches = [
    {
      name = "fix pipewire";
      patch = builtins.fetchurl {
        url = "https://patchwork.kernel.org/project/alsa-devel/patch/20240909164746.136629-1-krzysztof.kozlowski@linaro.org/raw";
        sha256 = "sha256:0ims0cwmdyna1lpx2vb37a17wmv91afyhbay02d9bnr41wbvjriz";
      };
    }
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    5000 # harmonia
  ];

  services = {
    # the SDD is LUKS encrypted so a password is already required
    getty.autologinUser = "james";
    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
    };
    harmonia = {
      enable = false;
      # nix-store --generate-binary-cache-key xps-1.tail7f031.ts.net harmonia.pem harmonia.pub
      signKeyPath = /home/james/secrets/harmonia.pem;
      settings = {
        bind = "100.121.186.109:5000";
      };
    };
    displayManager.autoLogin = {
      enable = true;
      user = "james";
    };
    xserver = {
      displayManager = {
        lightdm.greeter.enable = false;
      };
      xrandrHeads = [
        {
          output = "eDP-1";
          primary = true;
          monitorConfig = ''
            Option "PreferredMode" "1920x1200"
          '';
        }
      ];
      resolutions = [
        { x = 2560; y = 1600; }
        { x = 2048; y = 1280; }
        { x = 1920; y = 1200; }
        { x = 1280; y = 800; }
        { x = 1024; y = 640; }
      ];
    };
  };

  systemd = {
    user.services = pkgs.systemd.user;
  };

  users.extraGroups.vboxusers.members = [ "james" ];
}
