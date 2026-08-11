{
  pkgs,
  ...
}:

{
  # Allow services to bind to IPs (like Tailscale) before the interface is fully up
  boot.kernel.sysctl."net.ipv4.ip_nonlocal_bind" = 1;

  environment.systemPackages = [
    pkgs.mergerfs
  ];

  services = {
    chrony = {
      enable = true;
      # Allow devices on the camera subnet to query this NTP server
      extraConfig = ''
        allow 192.168.1.0/24
      '';
    };
    dnsmasq = {
      enable = true;
      settings = {
        port = 0; # disable DNS (to prevent :53 conflict with resolved)
        interface = "enp6s0"; # label: 2.5G LAN (vs. label: 🖧 )
        bind-interfaces = true;
        dhcp-range = "192.168.1.100,192.168.1.200,12h"; # default dahua address is 192.168.1.108
        dhcp-option = [
          # "3,192.168.1.1" # Gateway (commented to deny the camera internet access)
          "42,192.168.1.1" # NTP
        ];
        # to access the webui: ssh -L 8080:192.168.1.2:80 hm90
        dhcp-host = "fc:5f:49:41:9b:4e,192.168.1.2,front_porch_cam,infinite";
      };
    };
  };
  networking = {
    firewall.interfaces.enp6s0.allowedUDPPorts = [
      123 # NTP
    ];
    interfaces.enp6s0 = {
      ipv4.addresses = [
        {
          address = "192.168.1.1";
          prefixLength = 24;
        }
      ];
    };
  };

  # setup hardware
  hardware.coral.usb.enable = true;
  fileSystems."/var/lib/frigate/recordings" = {
    depends = [
      "/mnt/256GBssd"
      "/mnt/1TBsandisk"
      "/mnt/600GBssd"
    ];
    device = "/mnt/256GBssd:/mnt/1TBsandisk:/mnt/600GBssd";
    fsType = "mergerfs";
    options = [
      "nofail"
      "x-systemd.device-timeout=5s"
      "defaults"
      "fsname=mergerfs-frigate-recordings"
      # mergerfs refuses to create files on a branch with less than minfreespace
      # free, but statvfs on the pool still reports that reserve as free space.
      # At the 4G default, all 3 branches park at 4G free and every write fails
      # with ENOSPC while frigate's storage maintainer sees 3*4G=12G free, decides
      # there is over an hour of headroom, and never runs a cleanup. Frigate only
      # cleans up below ~1h of recording (~5GB), so keep 3*minfreespace under that
      # to guarantee frigate reclaims space before mergerfs starts rejecting writes.
      "minfreespace=1G"
      # on ENOSPC mid-write, relocate the file to the branch with the most free
      # space and retry rather than failing the write
      "moveonenospc=mfs"
      # default epmfs only considers branches where the parent dir already exists,
      # which fills branches unevenly; mfs always picks the emptiest branch
      "category.create=mfs"
    ];
  };
  systemd.tmpfiles.rules = [
    "z /var/lib/frigate 0755 frigate frigate"
  ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    80 # frigate nginx
  ];

  # nginx lacks permission to read the recordings directory otherwise
  users.extraUsers.frigate.extraGroups = [ "nginx" ];
  users.extraUsers.nginx.extraGroups = [ "frigate" ];

  # configure frigate
  services.frigate = {
    enable = true;
    hostname = "frigate.carragher.dev";
    settings = {
      environment_vars = {
        LIBVA_DRIVER_NAME = "radeonsi";
      };
      auth = {
        refresh_time = 2700000; # ~1 month
        failed_login_rate_limit = "1/second;5/minute;20/hour";
      };
      ffmpeg = {
        hwaccel_args = "preset-vaapi";
      };
      detectors.coral = {
        type = "edgetpu";
        device = "usb";
      };
      semantic_search = {
        enabled = true;
        model_size = "large";
      };
      objects = {
        track = [
          "person"
          "car"
          "dog"
          "cat"
        ];
      };
      notifications = {
        enabled = true;
        email = "james@carragher.dev";
      };
      # TODO this needs nethogs, which isn't packaged, and adding it to environment.systemPackages doesn't work
      # telemetry.stats.network_bandwidth = true;
      record = {
        enabled = true;
        # Retention must be the constraint that bounds disk usage, NOT frigate's
        # out-of-space cleanup: that cleanup compares statvfs free space against 1h
        # of bandwidth, and on a mergerfs pool the per-branch minfreespace reserve
        # makes the pool look non-full even when writes are already failing. Size
        # these so steady-state usage leaves real headroom on the 1.85TB pool.
        #
        # 9d/30d previously requested ~1.79TB against a 1.85TB pool -> permanently
        # wedged at 100% full. 7d/21d gives ~1.3TB, leaving ~25% headroom for the
        # bitrate variance that comes with scene activity.
        retain = {
          # ~5GB/h * 24h * 7d * 1 camera -> 840 GB
          days = 7;
          mode = "all";
        };
        # 14 days beyond the continuous window, motion segments only -> ~480 GB
        alerts = {
          retain = {
            days = 21;
            mode = "motion";
          };
        };
        detections = {
          retain = {
            days = 21;
            mode = "motion";
          };
        };
        # Retention only deletes files that have a row in the recordings table, so
        # anything orphaned (db rebuilt, files moved between branches, unclean
        # shutdown) is never reclaimed and silently eats the pool. This reconciles
        # both directions -- db rows with no file, and files with no db row -- fully
        # on startup, then over the last 36h daily at 03:00.
        sync_recordings = true;
      };
      # Snapshots save to /var/lib/frigate/clips on the root filesystem (not on the
      # mergerfs recordings pool)
      snapshots = {
        enabled = true;
        # unannotated copy written alongside the boxed one -- overlays land on top
        # of whatever you are trying to read
        clean_copy = true;
        bounding_box = true;
        timestamp = false;
        # keep the whole frame; cropping to the object throws away the context
        # needed to tell what actually happened
        crop = false;
        quality = 95;
        retain = {
          default = 30;
          objects = {
            car = 60;
          };
        };
      };
      camera_groups = {
        front = {
          cameras = [
            "front_porch_cam"
          ];
          icon = "LuCar";
          order = 0;
        };
      };
      # TODO replace hostname & ip with cameras' final locations (also set on cameras)
      # TODO configure new cameras' encoding:
      #   - http://192.168.1.108/#/index/camera/imgset
      #   - https://docs.frigate.video/frigate/camera_setup/#example-camera-configuration
      cameras = {
        # hostname: 9H0F184PAG0D108, ip: 192.168.1.2
        # $ ssh -L 8080:192.168.1.2:80 hm90
        front_porch_cam = {
          detect = {
            enabled = true;
            width = 1280;
            height = 720;
            fps = 5;
          };
          ffmpeg.inputs = [
            {
              # subtype=0 for higher resolution stream
              path = "rtsp://frigate:U9W4pCfYZdHE@192.168.1.2:554/cam/realmonitor?channel=1&subtype=0&unicast=true";
              roles = [
                "record"
              ];
            }
            {
              # subtype=1 for lower resolution stream
              path = "rtsp://frigate:U9W4pCfYZdHE@192.168.1.2:554/cam/realmonitor?channel=1&subtype=1&unicast=true";
              roles = [
                "detect"
              ];
            }
          ];
          motion.mask = [
            # timestamp overlay
            "0.55,0.034,0.551,0.088,0.957,0.088,0.956,0.034"
            # top
            "0.148,0,0.14,0.069,0.161,0.101,0.189,0.131,0.218,0.139,0.248,0.154,0.3,0.139,0.332,0.136,0.362,0.131,0.387,0.127,0.421,0.116,0.446,0.107,0.467,0.104,0.497,0.107,0.54,0.097,0.573,0.106,0.612,0.094,0.659,0.104,0.72,0.103,0.728,0.147,0.728,0.186,0.789,0.208,0.85,0.215,0.918,0.21,0.955,0"
            # left
            "0,0,0.041,0.086,0.05,0.024,0.075,0.036,0.078,0.074,0.085,0.091,0.102,0.131,0.107,0.162,0.109,0.186,0.105,0.21,0.09,0.249,0.085,0.276,0.021,0.307,0,0.278"
            # bottom left
            "0,0.765,0.037,0.778,0.057,0.816,0.062,0.868,0.08,0.896,0.081,0.929,0.096,0.962,0.08,1,0,1"
            # bottom right
            "0.975,1,0.978,0.9,1,0.86,1,1"
            # road
            "0.068,0.193,0.202,0.119,0.19,0.174,0.139,0.206,0.144,0.331,0.116,0.375,0.11,0.228"
          ];
          webui_url = "http://192.168.1.2";
        };
      };
    };
  };
}
