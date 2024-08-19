{ pkgs, config, ... }:

let
  unstable = pkgs.unstable;
in
{

  imports = [
    #../modules/neovim.nix
    ../overlays/neovim
    ../modules/anki.nix
  ];

  boot = {
    kernelPackages = unstable.linuxPackages_latest;
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  environment.systemPackages = with pkgs;
    [
      # _neovim
      vim-language-server
      lua-language-server
      vscode-langservers-extracted # JSON lsp
      nodePackages.typescript-language-server
      dockerfile-language-server-nodejs
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
      unstable.atuin
      unstable.blesh
      brave
      calibre
      unstable.chiaki
      entr
      evince
      firefox
      google-chrome
      unstable.hypnotix
      mpv # needed for anki
      unstable.obsidian
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
      comma # run any program without installation
      dunst
      dnsmasq
      file
      gnome2.gnome_icon_theme
      gnome3.adwaita-icon-theme
      gnome3.zenity
      gnupg
      gparted
      grim # wayland screenshots
      hfsprogs # gparted dep
      unstable.hyprshade # hyprland blue light filter
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
      rofi-wayland
      slurp # wayland paste to stdout
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
      wl-clipboard # wayland clipboard
      zip
    ] ++ scripts;

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "Hack" "NerdFontsSymbolsOnly" ]; })
    noto-fonts
    noto-fonts-emoji
    noto-fonts-cjk
    font-awesome
    feather-font
    powerline-fonts
    powerline-symbols
    gnome3.adwaita-icon-theme
  ];

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
    brillo.enable = true;
    opengl = {
      enable = true;
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
      fcitx5 = {
        addons = with pkgs; [ fcitx5-mozc ];
        waylandFrontend = true;
      };
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
    extraOptions = ''
      experimental-features = nix-command flakes
      connect-timeout = 1
    '';
    settings = {
      auto-optimise-store = true;
      substituters = [
        # disabled because: https://github.com/NixOS/nix/issues/6901
        # "http://hm90.tail7f031.ts.net:5000" # harmonia
        # "http://fwk.tail7f031.ts.net:5000" # harmonia
        # "http://xps-1.tail7f031.ts.net:5000" # harmonia
        "https://cache.nixos.org/"
      ];
      trusted-substituters = [
        "https://cache.iog.io"
        "https://jcarrag.cachix.org"
      ];
      trusted-public-keys = [
        "hm90.tail7f031.ts.net:MCfNHw7zYy994pMsO/bq1aduiMirFR5tuXYNv4/LAj8=" # harmonia
        "fwk.tail7f031.ts.net:VH6U0MFW2pggLXy51YiAGvr8gnC37HYLsM+6Nm1ivZU=" # harmonia
        "xps-1.tail7f031.ts.net:3Ltju5+Q1rszLnD2ti4eitAXrE3cit9Ck84BSsz/K/I=" # harmonia
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
    # necessary for wayland
    # https://github.com/NixOS/nixpkgs/issues/162562#issuecomment-1229444338
    packageOverrides = pkgs: {
      steam = pkgs.steam.override {
        extraPkgs = pkgs: with pkgs; [
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXScrnSaver
          libpng
          libpulseaudio
          libvorbis
          stdenv.cc.cc.lib
          libkrb5
          keyutils
        ];
      };
    };

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
    command-not-found.dbPath = "/home/james/.cache/nix-index/files";
    fzf = {
      keybindings = true;
      fuzzyCompletion = true;
    };
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    hyprland = {
      enable = true;
      package = unstable.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-wlr;
      xwayland.enable = true;
    };
    hyprlock.enable = true;
    light.enable = true;
    nm-applet = {
      enable = true;
      indicator = true;
    };
    noisetorch.enable = true;
    steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
    thunar.enable = true;
    waybar.enable = true;
  };

  security = {
    rtkit.enable = true;
    sudo.extraConfig = ''
      Defaults timestamp_timeout=-1
    '';
  };

  services = {
    avahi = {
      enable = true;
      nssmdns4 = true;
      publish.enable = true;
      publish.userServices = true;
    };
    blueman.enable = true;
    dbus.enable = true;
    fwupd.enable = true;
    geoclue2.enableDemoAgent = true;
    gnome.gnome-keyring.enable = true;
    hardware.bolt.enable = true;
    libinput = {
      enable = true;
      touchpad = {
        disableWhileTyping = true;
        accelSpeed = "0.0";
      };
    };
    localtimed.enable = true;
    logind.extraConfig = ''
      # don’t shutdown when power button is short-pressed
      HandlePowerKey=ignore
    '';
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
      extraConfig.pipewire = {
        "92-raop-discover.conf" = {
          "context.modules" = [
            {
              name = "libpipewire-module-raop-discover";
            }
          ];
        };
      };
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
      extraHwdb = '''';
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

        # ZSA Voyager
        # Rules for Oryx web flashing and live training
        KERNEL=="hidraw*", ATTRS{idVendor}=="3297", MODE="0664", GROUP="plugdev"

        # Keymapp Flashing rules for the Voyager
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="3297", MODE:="0666", SYMLINK+="ignition_dfu"
      '';
    };
    xserver = {
      enable = true;
      exportConfiguration = true;
      serverLayoutSection = ''
        Option "StandbyTime" "0"
        Option "SuspendTime" "0"
        Option "OffTime"     "0"
      '';
    };
    xremap = {
      watch = true;
      serviceMode = "user";
      userName = "james";
      withWlroots = true;
      config.modmap = [
        {
          name = "ctrl=caps_lock";
          device.not = [ "ZSA Technology Labs Voyager" ];
          remap = {
            "CapsLock" = {
              held = "Ctrl_L";
              alone = "Esc";
              aloneTimeout = 500;
            };
          };
        }
        {
          name = "swap alt_l / meta_l";
          device.not = [ "ZSA Technology Labs Voyager" ];
          application.not = [
            ".gamescope-wrapped"
            "com.moonlight_stream.Moonlight"
          ];
          remap = {
            "KEY_LEFTMETA" = "KEY_LEFTALT";
          };
        }
        {
          name = "swap meta_l / alt_l";
          device.not = [ "ZSA Technology Labs Voyager" ];
          application.not = [
            ".gamescope-wrapped"
            "com.moonlight_stream.Moonlight"
          ];
          remap = {
            "KEY_LEFTALT" = "KEY_LEFTMETA";
          };
        }
      ];
    };
  };

  sound = {
    enable = true;
    mediaKeys.enable = true;
  };

  # https://github.com/NixOS/nixpkgs/issues/180175
  systemd.services.NetworkManager-wait-online.enable = false;

  users.extraUsers.james = {
    createHome = true;
    extraGroups = [ "wheel" "users" "video" "audio" "disk" "networkmanager" "docker" "dialout" ];
    group = "users";
    home = "/home/james";
    # allow emby-server access to ~/emby-library
    homeMode = "770";
    isNormalUser = true;
    uid = 1000;
  };

  xdg =
    {
      mime.defaultApplications = {
        "text/html" = "brave-browser.desktop";
        "x-scheme-handler/http" = "brave-browser.desktop";
        "x-scheme-handler/https" = "brave-browser.desktop";
        "x-scheme-handler/about" = "brave-browser.desktop";
        "x-scheme-handler/unknown" = "brave-browser.desktop";
      };
    };

  environment.sessionVariables = {
    # hyprland/wayland
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
  };

  system.stateVersion = "20.09";
}
