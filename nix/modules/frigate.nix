{ ... }:

{
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1; # don't drop packets meant for NAT'd subnet

  # environment.systemPackages = with pkgs; [
  #   # used for network bandwidth monitoring
  #   nethogs
  # ];

  services.dnsmasq = {
    enable = true;
    settings = {
      port = 0; # disable DNS (to prevent :53 conflict with resolved)
      interface = "enp6s0";
      bind-interfaces = true;
      dhcp-range = "192.168.1.100,192.168.1.200,12h"; # default dahua address is 192.168.1.108
      dhcp-option = [
        "3,192.168.1.1" # Gateway
        "6,8.8.8.8,1.1.1.1" # DNS servers
      ];
    };
  };

  networking = {
    firewall.interfaces.tailscale0.allowedTCPPorts = [
      5000 # frigate nginx
    ];
    nat = {
      enable = true;
      # FIXME replace with final eth interface
      externalInterface = "wlp5s0";
      internalInterfaces = [
        "en01" # "2.5G LAN"
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

  hardware.coral.usb.enable = true;

  # https://docs.frigate.video/configuration
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
      # FIXME this needs nethogs, which isn't packaged, and adding it to PATH doesn't work
      # telemetry.stats.network_bandwidth = true;
      record = {
        enabled = true;
        retain = {
          # FIXME increase to correct retention duration
          days = 1;
          mode = "motion";
        };
        alerts = {
          retain = {
            days = 30;
          };
        };
        detections = {
          retain = {
            days = 30;
          };
        };
      };
      camera_groups = {
        front = {
          cameras = [
            "driveway_cam"
          ];
          icon = "LuCar";
          order = 0;
        };
      };
      cameras = {
        # FIXME replace hostname & ip with camera's final location (also set on camera)
        # FIXME configure new camera's encoding:
        #   - http://192.168.1.108/#/index/camera/imgset
        #   - https://docs.frigate.video/frigate/camera_setup/#example-camera-configuration
        # hostname: HDW3549H
        driveway_cam = {
          detect = {
            width = 1280;
            height = 720;
            fps = 5;
          };
          # FIXME: use statically assigned IP (also set on camera)
          ffmpeg.inputs = [
            {
              # subtype=0 for higher resolution stream
              path = "rtsp://frigate:U9W4pCfYZdHE@192.168.1.108:554/cam/realmonitor?channel=1&subtype=0&unicast=true";
              roles = [
                "record"
              ];
            }
            {
              # subtype=1 for lower resolution stream
              path = "rtsp://frigate:U9W4pCfYZdHE@192.168.1.108:554/cam/realmonitor?channel=1&subtype=1&unicast=true";
              roles = [
                "detect"
              ];
            }
          ];
          motion.mask = [
            # ignore timestamp overlay
            "0.55,0.034,0.551,0.088,0.957,0.088,0.956,0.034"
          ];
          # FIXME replace w/ static ip
          webui_url = "http://192.168.1.108";
        };
      };
    };
  };
}
