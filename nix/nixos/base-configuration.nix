{ pkgs, config, ... }:

let
  unstable = pkgs.unstable;
in
{

  imports = [
    ../modules/neovim.nix
    ../modules/anki.nix
  ];

  boot = {
    kernelPackages = unstable.linuxPackages_latest;
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  environment.systemPackages = with pkgs;
    [
      ### Communication
      unstable.discord
      unstable.signal-desktop
      skypeforlinux
      unstable.slack
      # unstable.zoom-us
      ### eGPU
      unstable.intel-gpu-tools
      unstable.glxinfo
      unstable.radeontop
      unstable.vulkan-tools
      ### Misc
      aoe-2-de
      brave
      calibre
      unstable.chiaki
      entr
      evince
      firefox
      google-chrome
      unstable.hypnotix
      mpv # needed for anki
      sunshine
      spotify
      unstable.starship
      unstable.syncplay
      unstable.telegram-desktop
      vlc
      ### Programming
      pkg-config
      (openssl.dev)
      unstable.saleae-logic-2
      ## C++
      ccls
      gcc
      ## Rust
      unstable.rust-analyzer
      unstable.cargo
      unstable.rustc
      unstable.rustfmt
      ## Javascript
      nix-npm-install
      nodejs-18_x
      nodePackages.node2nix
      ## Nix
      unstable.nil
      unstable.nixpkgs-fmt
      ## Python
      python3Minimal
      ## Scala
      sbt
      scala
      ### Services
      unstable.awscli
      sshfs
      unstable.tailscale
      tmate-connect
      unstable._1password-gui
      tmux
      ### Networking
      socat
      tcpdump
      traceroute
      wireshark
      ### System
      alock
      arandr
      d-spy # d-bus monitor
      bustle # d-bus monitor
      dunst
      dnsmasq
      file
      gnome2.gnome_icon_theme
      gnome3.adwaita-icon-theme
      gnome3.zenity
      gnupg
      gparted
      hfsprogs # gparted dep
      inotify-tools
      unstable.lurk
      ntfsprogs # gparted dep
      hicolor-icon-theme
      libsecret
      lm_sensors
      nix-index
      nix-prefetch-scripts
      openvpn
      pulseaudioFull
      paprefs # pulseaudio preferences
      pasystray # pulseaudio systray
      pavucontrol # pulseaudio volume control
      unstable.helvum # pipewire
      rofi
      taffybar-my
      alacritty
      update-resolv-conf
      xclip
      ### Util
      asciicharts
      bat
      binutils-unwrapped
      briss # pdf crop
      # k2pdfopt # pdf crop for kindle [broken]
      cntr
      dig
      unstable.direnv
      dhcpdump
      ffmpeg-full
      fq
      jq
      jqp
      gitAndTools.gitFull
      git-crypt
      glances
      gnome-connections # vnc client
      htop
      fd
      libnotify
      lshw
      input-utils
      lsof
      mitmproxy
      ncdu
      yarn # needed for coc.nvim's post-install step
      p7zip
      pciutils
      powertop
      remmina
      rename
      ripgrep
      stow
      tldr
      tree
      unrar
      unzip
      usbutils
      watchexec
      which
      zip
    ] ++ scripts;

  fonts = {
    fonts = with pkgs; [
      (nerdfonts.override { fonts = [ "Hack" ]; })
      noto-fonts-cjk
      font-awesome
      feather-font
      gnome3.adwaita-icon-theme
    ];
  };

  hardware = {
    saleae-logic.enable = true;
    bluetooth = {
      enable = true;
      package = pkgs.bluez.overrideAttrs (
        oldAttrs: {
          configureFlags = oldAttrs.configureFlags ++ [ "--enable-sixaxis" ];
        }
      );
    };
    opengl = {
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = [
        pkgs.intel-media-driver
        pkgs.vaapiIntel
      ];
    };
    xpadneo.enable = true;
  };

  i18n = {
    defaultLocale = "en_GB.UTF-8";
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [ fcitx5-mozc ];
    };
  };

  location.provider = "geoclue2";

  networking = {
    enableIPv6 = false;
    resolvconf.dnsExtensionMechanism = false; # this broke wifi for a hostel router
    firewall = {
      allowedTCPPorts = [
        5000 # airplay
        5001 # airplay
        6001 # airplay
        6002 # airplay
        8000 # python -m SimpleHTTPServer
        7000 # airplay
        # https://portforward.com/moonlight-game-streaming/
        47984 # sunshine
        47989 # sunshine
        48010 # sunshine
      ];
      allowedUDPPorts = [
        6001 # airplay
        6002 # airplay
        7000 # airplay
        47998 # sunshine
        47999 # sunshine
        48000 # sunshine
        48002 # sunshine
        48010 # sunshine
      ];
      checkReversePath = "loose";
    };
    nameservers = [ "8.8.8.8" ];
    networkmanager = {
      enable = true;
      plugins = [
        pkgs.networkmanager-openvpn
      ];
    };
    search = [ "tail7f031.ts.net" ];
  };

  nix = {
    nixPath = pkgs.lib.mapAttrsToList
      (key: value: "${key}=${value.to.path}")
      (pkgs.lib.filterAttrs (key: value: value ? to.path) config.nix.registry);
    package = pkgs.unstable.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      auto-optimise-store = true;
      substituters = [
        "https://cache.nixos.org/"
      ];
      trusted-substituters = [
        "https://cache.iog.io"
        "https://jcarrag.cachix.org"
      ];
      trusted-users = [ "root" "james" ];
    };
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
    permittedInsecurePackages = [
      "mupdf-1.17.0" # k2pdfopt dep
    ];
  };

  powerManagement.resumeCommands = ''
    ${pkgs.dunst}/bin/dunstctl set-paused true
    ${pkgs.alock}/bin/alock
  '';

  programs = {
    anki = {
      enable = true;
      addons = [
        {
          ankiWebId = "3918629684";
          patches = [ pkgs.ankiJapanesePatch ];
          sha256 = "sha256-yvhTyuu3FPM6P2rjWeV87jujnke8tBi+Pj1hGUDeOa8=";
        }
        {
          ankiWebId = "2413435972";
          patches = [ pkgs.ankiJapaneseExampleSentencesPatch ];
          addonConfig = {
            maxPermanent = 2;
            maxShow = 2;
            noteTypes = [ "Japanese (recognition&recall)" ];
          };
          sha256 = "sha256-V3R/diLJCIgZRmz35/5QBTztf10hqhryvTp69UrWfj4=";
        }
        {
          # True retention
          ankiWebId = "613684242";
          sha256 = "sha256-MDDscb6XoJDkXyx7puY9y7EbOxZVGZXcmD1R1g2207g=";
        }
        {
          # Edit field during review
          ankiWebId = "385888438";
          sha256 = "sha256-o/6kUXPU7TyMRRne43tJD4DQmhakjm1hyoKUorb+thU=";
        }
      ];
    };
    autojump.enable = true;
    bash.enableCompletion = true;
    fzf = {
      keybindings = true;
      fuzzyCompletion = true;
    };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    light.enable = true;
    nm-applet.enable = true;
    noisetorch.enable = true;
    steam.enable = true;
  };

  security = {
    rtkit.enable = true;
    sudo.extraConfig = ''
      Defaults timestamp_timeout=-1
    '';
  };

  services = {
    actkbd = {
      enable = true;
      bindings =
        [
          {
            # enter+left_ctrl
            keys = [ 28 29 ];
            events = [ "key" ];
            command = "/run/current-system/sw/bin/runuser -l james -c 'XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.alacritty}/bin/alacritty --class console --title console' &>> /home/james/wut";
          }

        ] ++ (map
          (keys: {
            inherit keys;
            events = [ "key" ];
            command = "/run/current-system/sw/bin/runuser -l james -c 'DISPLAY=:0 DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus ${pkgs.dunst}/bin/dunstctl close'";
          }) [
          [ 29 57 ] # left_ctrl+space
          [ 97 57 ] # right_ctrl+space
          [ 58 57 ] # caps_lock+space
        ]);
    };
    avahi = {
      enable = true;
      nssmdns = true;
      publish.enable = true;
      publish.userServices = true;
    };
    blueman.enable = true;
    dbus.enable = true;
    fwupd.enable = true;
    geoclue2.enableDemoAgent = true;
    gnome.gnome-keyring.enable = true;
    hardware.bolt.enable = true;
    localtimed.enable = true;
    redshift.enable = true;
    openssh.enable = true;
    openvpn = {
      servers = {
        express-vpn-uk = {
          autoStart = false;
          config =
            ''
              config /home/james/vpn/my_expressvpn_uk_-_east_london_udp.ovpn

              auth-user-pass /home/james/vpn/my_expressvpn_uk_-_east_london_udp.conf

              script-security 2
              up ${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved
              up-restart
              down ${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved
              down-pre
            '';
        };
        express-vpn-us = {
          autoStart = false;
          config =
            ''
              config /home/james/vpn/my_expressvpn_usa_-_new_jersey_-_3_udp.ovpn

              auth-user-pass /home/james/vpn/my_expressvpn_usa_-_new_jersey_-_3_udp.conf

              script-security 2
              up ${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved
              up-restart
              down ${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved
              down-pre
            '';
        };
      };
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    printing = {
      enable = true;
      browsing = true;
      drivers = [ ];
    };
    resolved = {
      enable = true;
      domains = [
        "8.8.8.8"
        "2001:4860:4860::8844"
      ];
      # mDNS is provided by avahi
      extraConfig = ''
        MulticastDNS=no
      '';
    };
    switcherooControl.enable = true;
    udev = {
      # https://yulistic.gitlab.io/2017/12/linux-keymapping-with-udev-hwdb
      # https://wiki.archlinux.org/title/map_scancodes_to_keycodes
      # (trailing newline between rules & all-caps in ids are needed)
      extraHwdb = ''
        # magicforce
        evdev:input:b0003v04D9p0024*
          KEYBOARD_KEY_700e3=leftalt
          KEYBOARD_KEY_700e2=leftmeta
      '';
      extraRules = ''
        ATTRS{idVendor}=="239a", ATTRS{idProduct}=="8087", TAG+="uaccess"

        ATTRS{idVendor}=="239a", ENV{ID_MM_DEVICE_IGNORE}="1"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="239a", MODE="0666"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="239a", MODE="0666"

        # PS4 compat
        # This rule is needed for basic functionality of the controller in Steam and keyboard/mouse emulation
        SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", MODE="0666"
        # This rule is necessary for gamepad emulation
        KERNEL=="uinput", MODE="0660", GROUP="users", OPTIONS+="static_node=uinput"
        # Valve HID devices over USB hidraw
        KERNEL=="hidraw*", ATTRS{idVendor}=="28de", MODE="0666"
        # Valve HID devices over bluetooth hidraw
        KERNEL=="hidraw*", KERNELS=="*28DE:*", MODE="0666"
        # DualShock 4 over USB hidraw
        KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="05c4", MODE="0666"
        # DualShock 4 wireless adapter over USB hidraw
        KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ba0", MODE="0666"
        # DualShock 4 Slim over USB hidraw
        KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", MODE="0666"
        # DualShock 4 over bluetooth hidraw
        KERNEL=="hidraw*", KERNELS=="*054C:05C4*", MODE="0666"
        # DualShock 4 Slim over bluetooth hidraw
        KERNEL=="hidraw*", KERNELS=="*054C:09CC*", MODE="0666"

        # This rules are based on the udev rules from the OpenOCD project, with unsupported probes removed.
        # See http://openocd.org/ for more details.

        # SEGGER J-Link mini
        ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0101", MODE="0666", TAG+="uaccess", GROUP="users"
      '';
    };
    xserver = {
      enable = true;
      exportConfiguration = true;
      libinput = {
        enable = true;
        touchpad = {
          disableWhileTyping = true;
          accelSpeed = "0.0";
        };
      };
      serverLayoutSection = ''
        Option "StandbyTime" "0"
        Option "SuspendTime" "0"
        Option "OffTime"     "0"
      '';
      layout = "us";
      # xkbOptions list: https://gist.github.com/jcarrag/aa6c72c76d8664ff3f1c752bbf543af7
      xkbOptions = "shift:both_capslock,ctrl:nocaps";
      desktopManager = {
        xterm.enable = true;
        plasma5 = {
          enable = true;
          useQtScaling = true;
        };
      };
      displayManager = {
        defaultSession = "plasma";
        sessionCommands = ''
          ${pkgs.xorg.xsetroot}/bin/xsetroot -solid black
          ${pkgs.xcape}/bin/xcape -e 'Control_L=Escape' -t 175
          ${pkgs.xorg.xset}/bin/xset s 10800 10800
          ${pkgs.picom}/bin/picom &
          ${pkgs.xbanish}/bin/xbanish &
          ${pkgs.haskellPackages.status-notifier-item}/bin/status-notifier-watcher &
          ${pkgs.dunst}/bin/dunst &
          ${pkgs.networkmanagerapplet}/bin/nm-applet --sm-disable --indicator &
        '';
      };
      windowManager.xmonad = {
        enable = true;
        config = pkgs.xmonad-config;
        enableContribAndExtras = true;
        enableConfiguredRecompile = true;
        extraPackages = hpkgs: [
          hpkgs.data-default
          hpkgs.dbus
          hpkgs.xmonad-extras
          hpkgs.xmonad-contrib
          hpkgs.xmonad
        ];
      };
    };
  };

  sound = {
    enable = true;
    mediaKeys.enable = true;
  };

  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;

  # this disables the KDE window manager so xmonad can run instead
  systemd.user.services.plasma-kwin_x11.wantedBy = pkgs.lib.mkForce [ ];
  # this starts xmonad but uses the built xmonad package from "services.windowManager.xmonad"
  # (which is configured via xmonad.hs)
  systemd.user.services.xmonad-plasma =
    let
      ExecStart = pkgs.lib.pipe config.services.xserver.windowManager.session [
        (builtins.filter (e: e.name == "xmonad"))
        (e: builtins.elemAt e 0)
        (e: e.start)
        (builtins.match ".*(/nix/store/.*/bin/xmonad).*")
        (e: builtins.elemAt e 0)
      ];
    in
    {
      description = "Plasma XMonad Window Manager";
      before = [ "plasma-workspace.target" ];
      wantedBy = [ "plasma-workspace.target" ];
      environment = {
        DISPLAY = ":0";
        DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
        # /run/wrappers/bin for sudo
        # /run/current-system/sw/bin for rofi etc.
        PATH = pkgs.lib.mkForce "PATH:/run/wrappers/bin:/run/current-system/sw/bin";
      };

      serviceConfig = {
        inherit ExecStart;
        Type = "simple";
        Restart = "on-failure";
        Slice = "session.slice";
      };
    };

  users.extraUsers.james = {
    createHome = true;
    extraGroups = [ "wheel" "video" "audio" "disk" "networkmanager" "docker" "dialout" ];
    group = "users";
    home = "/home/james";
    # allow emby-server access to ~/emby-library
    homeMode = "770";
    isNormalUser = true;
    uid = 1000;
  };


  xdg.mime.defaultApplications = {
    "text/html" = "brave-browser.desktop";
    "x-scheme-handler/http" = "brave-browser.desktop";
    "x-scheme-handler/https" = "brave-browser.desktop";
    "x-scheme-handler/about" = "brave-browser.desktop";
    "x-scheme-handler/unknown" = "brave-browser.desktop";
  };

  environment.etc =
    let
      json = pkgs.formats.json { };
    in
    {
      "pipewire/pipewire.conf.d/92-raop-discover.conf".source = json.generate "92-raop-discover.conf" {
        "context.modules" = [
          {
            name = "libpipewire-module-raop-discover";
          }
        ];
      };
    };

  system.stateVersion = "20.09";
}
