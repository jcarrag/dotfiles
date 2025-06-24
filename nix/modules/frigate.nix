{ ... }:

{
  # configure the PoE switch
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1; # don't drop packets meant for NAT'd interface
  services.dnsmasq = {
    # DNS is useful to let cameras discover & join network, but they will be given a static IP (for frigate to use)
    enable = true;
    settings = {
      port = 0; # disable DNS (to prevent :53 conflict with resolved)
      interface = "enp6s0"; # "2.5G LAN"
      bind-interfaces = true;
      dhcp-range = "192.168.1.100,192.168.1.200,12h"; # default dahua address is 192.168.1.108
      dhcp-option = [
        "3,192.168.1.1" # Gateway
      ];
    };
  };
  networking = {
    nat = {
      enable = true;
      externalInterface = "eno1"; # 🖧
      internalInterfaces = [
        "enp6s0" # "2.5G LAN"
      ];
    };
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
  fileSystems."/var/lib/frigate" = {
    device = "/dev/disk/by-uuid/9a356958-a691-4287-b093-87d401ffc318"; # 256GB SSD
    fsType = "ext4";
  };
  systemd.tmpfiles.rules = [
    "z /var/lib/frigate 0755 frigate frigate"
  ];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    80 # frigate nginx
  ];

  # configure frigate
  services.frigate = {
    enable = true;
    hostname = "frigate.carragher.dev";
    settings = {
      environment_vars = {
        LIBVA_DRIVER_NAME = "radeonsi";
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
        retain = {
          # TODO once 4TB SSD installed (also update SSD mount config):
          # ~3GB/h * 24h * 6d * 8 cameras -> 3456 GB
          # days = 10;
          # Until then (on 256GB SSD):
          # ~3GB/h * 24h * 3d * 1 camera -> 216 GB
          days = 3;
          mode = "all";
        };
        alerts = {
          retain = {
            days = 30;
            mode = "motion";
          };
        };
        detections = {
          retain = {
            days = 30;
            mode = "motion";
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
        # hostname: 9H0F184PAG0D108
        front_porch_cam = {
          detect = {
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
          ];
          webui_url = "http://192.168.1.2";
        };
      };
    };
  };
}
