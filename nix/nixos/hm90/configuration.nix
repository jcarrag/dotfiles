# EliteMini HM90
{
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ../../modules/emby-server.nix
    ../../modules/frigate.nix
    ../../modules/sunshine.nix
  ];

  environment.systemPackages = [
    pkgs.mergerfs
  ];

  fileSystems."/home/james/emby-library" = {
    depends = [
      "/home/james/emby-library_not_mergerfs"
      "/mnt/2TBm2enclosure"
    ];
    device = "/mnt/2TBm2enclosure:/home/james/emby-library_not_mergerfs";
    fsType = "mergerfs";
    options = [
      "nofail"
      "x-systemd.device-timeout=5s"
      "defaults"
      "fsname=mergerfs-emby-library"
    ];
  };

  nix.gc.automatic = true;

  programs = {
    emby-server.enable = true;
    ynab-updater = {
      enable = true;
      configDir = "/home/james/.config/ynab-updater";
    };
    sunshine.enable = true;
  };

  networking = {
    firewall = {
      interfaces.tailscale0 = {
        allowedUDPPorts = [
          22000 # syncthing
          21027 # syncthing
        ];
        allowedTCPPorts = [
          5001 # harmonia
          8384 # syncthing
          22000 # syncthing
        ];
      };
    };
  };

  services = {
    calibre-web = {
      enable = true;
      listen.ip = "100.65.97.33";
      options = {
        enableBookUploading = true;
        calibreLibrary = "/home/james/Calibre Library";
      };
      user = "james";
      group = "users";
    };
    displayManager.autoLogin = {
      enable = true;
      user = "james";
    };
    harmonia = {
      enable = true;
      # nix-store --generate-binary-cache-key hm90.tail7f031.ts.net harmonia.pem harmonia.pub
      signKeyPaths = [ "/home/james/secrets/harmonia.pem" ];
      settings = {
        bind = "100.65.97.33:5001";
      };
    };
    syncthing = {
      enable = true;
      group = "users";
      user = "james";
      dataDir = "/home/james/syncthing";
      guiAddress = "100.65.97.33:8384"; # hm90.tail7f031.ts.net
      settings = {
        devices = {
          hm90 = {
            id = "IEYHIZK-64FMYVQ-BUFCRXV-H5HXUE3-GI6LX52-6MKQTWA-TKBG4CD-DEBK5AY";
            autoAcceptFolders = true;
          };
          fwk = {
            id = "YJUN6RQ-M6J4OLM-AHX5T5E-R3EQZL2-63Y7SYJ-234K2G2-LZEXEON-6HDYUAX";
            autoAcceptFolders = true;
          };
          lunar-fwk = {
            id = "LE2NRU6-MD4PBOO-VEOTVRO-6GUGP53-2C2LL3L-WHU6MFN-2L3657P-MZHN2Q4";
            autoAcceptFolders = true;
          };
          sm-x510 = {
            id = "Z6RHLYN-DXGQCL2-O4LT7AA-6SVG4KF-2OQDN36-M5D7RCT-S6EM6VS-KSGTDQ7";
            autoAcceptFolders = true;
          };
        };
        folders = {
          "Calibre Library" = {
            path = "/home/james/Calibre Library";
            versioning = {
              type = "simple";
              params.keep = "1";
            };
            devices = [
              "fwk"
              "lunar-fwk"
              "sm-x510"
            ];
          };
          "storyteller" = {
            path = "/home/james/storyteller";
            type = "sendonly";
            versioning = {
              type = "simple";
              params.keep = "1";
            };
            devices = [
              "fwk"
              "lunar-fwk"
            ];
          };
        };
      };
    };
    tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
      extraSetFlags = [ "--accept-routes" ];
      useRoutingFeatures = "both";
    };
  };

  systemd = pkgs.systemd-services // {
    # wait for tailscale for bind
    services.storyteller.serviceConfig.ExecStartPre = lib.mkForce [
      "${pkgs.bash}/bin/bash -c 'until ${pkgs.iproute2}/bin/ip addr show dev tailscale0 | ${pkgs.gnugrep}/bin/grep -q -E \"inet 100(\.[0-9]{1,3}){3}\"; do sleep 1; done'"
    ];
    services.storyteller.after = lib.mkForce [
      "network-online.target"
      "tailscaled.service"
    ];
    services.storyteller.wants = lib.mkForce [
      "network-online.target"
      "tailscaled.service"
    ];
    # wait for tailscale for bind
    services.calibre-web.serviceConfig.ExecStartPre = lib.mkForce [
      "${pkgs.bash}/bin/bash -c 'until ${pkgs.iproute2}/bin/ip addr show dev tailscale0 | ${pkgs.gnugrep}/bin/grep -q -E \"inet 100(\.[0-9]{1,3}){3}\"; do sleep 1; done'"
    ];
  };

  users.extraUsers.james.extraGroups = [ "podman" ];
  virtualisation.containers.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      storyteller = {
        serviceName = "storyteller";
        image = "registry.gitlab.com/storyteller-platform/storyteller:latest";
        ports = [
          "100.65.97.33:8001:8001"
        ];
        volumes = [
          "/home/james/storyteller:/data:rw"
          "/home/james/secrets/storyteller:/run/secrets/secret_key"
        ];
        environment = {
          STORYTELLER_SECRET_KEY_FILE = "/run/secrets/secret_key";
        };
        extraOptions = [
          "--cidfile=/home/james/storyteller.ctr-id"
        ];
      };
    };
  };
}
