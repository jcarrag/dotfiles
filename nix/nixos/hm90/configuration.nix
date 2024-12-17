# EliteMini HM90
{ pkgs, config, ... }:

{
  imports = [
    ../../modules/emby-server.nix
    ../../modules/tailscale-funnel.nix
  ];

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };

  programs = {
    emby-server = {
      enable = true;
      user = "emby-server";
      group = "users";
      openFirewall = true;
    };
    ynab-updater = {
      enable = true;
      configDir = "/home/james/.config/ynab-updater";
    };
    tailscale-funnel.services = {
      calibre-web = {
        enable = true;
        port = config.services.calibre-web.listen.port;
        path = "/";
      };
    };
  };

  networking = {
    firewall = {
      allowedUDPPorts = [
        51820 # wireguard
      ];
      interfaces."tailscale0".allowedTCPPorts = [
        5000 # harmonia
      ];
    };
    wireguard = {
      enable = true;
      interfaces.wg0 = {
        ips = [ "10.13.13.3" ];
        listenPort = 51820;
        privateKeyFile = "/home/james/secrets/wireguard/hm90_private";
        peers = [
          {
            # hades - downloaded config
            endpoint = "45.86.221.100:24762";
            publicKey = "aG/hA+lURm/3OjOBJU7S2FSvyZ9z1VjuBer6fasWOyM=";
            presharedKeyFile = "/home/james/secrets/wireguard/hades_hm90_presharedkey";
            allowedIPs = [ "10.13.13.1/32" ];
            persistentKeepalive = 25;
            dynamicEndpointRefreshSeconds = 25;
          }
        ];
      };
    };
  };

  services = {
    calibre-web = {
      enable = true;
      listen.ip = "0.0.0.0";
      options = {
        enableBookUploading = true;
        calibreLibrary = "/home/james/Calibre Library";
      };
      user = "james";
      group = "users";
    };
    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
    };
    harmonia = {
      enable = false;
      # nix-store --generate-binary-cache-key hm90.tail7f031.ts.net harmonia.pem harmonia.pub
      signKeyPath = /home/james/secrets/harmonia.pem;
      settings = {
        bind = "100.65.97.33:5000";
      };
    };
    xserver.displayManager.autoLogin = {
      enable = true;
      user = "james";
    };
  };

  systemd = pkgs.systemd-services;
}
