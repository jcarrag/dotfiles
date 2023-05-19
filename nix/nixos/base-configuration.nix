{ config, pkgs, ... }:

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
      unstable.zoom-us
      ### eGPU
      unstable.intel-gpu-tools
      unstable.glxinfo
      unstable.radeontop
      unstable.switcheroo-control
      unstable.vulkan-tools
      ### Misc
      aoe-2-de
      unstable.brave
      calibre
      entr
      evince
      unstable.fzf
      spotify
      unstable.starship
      unstable.syncplay
      vlc
      zotero
      ### Programming
      ## C++
      unstable.ccls
      unstable.gcc
      ## Rust
      unstable.rust-analyzer
      unstable.cargo
      unstable.rustc
      unstable.rustfmt
      ## Haskell
      unstable.cabal-install
      unstable.ghc
      unstable.haskellPackages.haskell-language-server
      ## Javascript
      nix-npm-install
      nodejs-16_x
      nodePackages.node2nix
      ## Nix
      unstable.cachix
      unstable.nil
      ## Python
      python3Minimal
      ## Scala
      sbt
      scala
      ### Services
      unstable.awscli
      unstable.overmind
      tailscale
      tmate-connect
      unstable._1password-gui
      unstable.tmux
      ### Networking
      socat
      tcpdump
      traceroute
      ### System
      alock
      arandr
      dunst
      gnome2.gnome_icon_theme
      gnome3.adwaita-icon-theme
      gnome3.zenity
      gnupg
      gparted
      hfsprogs # gparted dep
      ntfsprogs # gparted dep
      hicolor-icon-theme
      libsecret
      nix-index
      nix-prefetch-scripts
      openvpn
      paprefs # pulseaudio preferences
      pasystray # pulseaudio systray
      pavucontrol # pulseaudio volume control
      rofi
      taffybar-my
      alacritty
      update-resolv-conf
      xclip
      xfce.xfce4-power-manager
      ### Util
      asciicharts
      bat
      binutils-unwrapped
      cntr
      dig
      unstable.direnv
      jq
      gitAndTools.gitFull
      git-crypt
      glances
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
    ] ++ scripts.all;

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
    bluetooth = {
      enable = true;
      package = pkgs.bluezFull.overrideAttrs (
        oldAttrs: {
          configureFlags = oldAttrs.configureFlags ++ [ "--enable-sixaxis" ];
        }
      );
    };
    opengl = {
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = [ pkgs.intel-media-driver ];
    };
    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
    };
    xpadneo.enable = true;
  };

  i18n = {
    inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = with pkgs; [ fcitx5-mozc ];
    };
  };

  networking = {
    resolvconf.dnsExtensionMechanism = false; # this broke wifi for a hostel router
    firewall = {
      allowedTCPPorts = [
        8000 # python -m SimpleHTTPServer
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
  };

  nix = {
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
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    light.enable = true;
    nm-applet.enable = true;
    noisetorch.enable = true;
    steam.enable = true;
    thunar.plugins = [ pkgs.xfce.thunar-archive-plugin pkgs.xfce.thunar-volman ];
  };

  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=-1
  '';

  services = {
    actkbd = {
      enable = true;
      bindings =
        [
          {
            # enter+left_ctrl
            keys = [ 28 29 ];
            events = [ "key" ];
            # command = "DISPLAY=:0 XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.alacritty}/bin/alacritty --class console --title console &>> /home/james/wut";
            command = "/run/current-system/sw/bin/runuser -l james -c 'XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.alacritty}/bin/alacritty --class console --title console' &>> /home/james/wut";
            # command = "echo wut >> /home/james/wut";
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
    gnome.gnome-keyring.enable = true;
    openssh.enable = true;
    openvpn = {
      servers = {
        express-vpn-us = {
          autoStart = false;
          config =
            let credentials = "";
            in
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
    };
    switcherooControl.enable = true;
    tailscale.enable = true;
    upower.enable = true;
    udev = {
      # swap left alt with meta on magicforce keyboard
      extraHwdb = ''
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

        ACTION!="add|change", GOTO="probe_rs_rules_end"

        SUBSYSTEM=="gpio", MODE="0660", GROUP="plugdev", TAG+="uaccess"

        SUBSYSTEM!="usb|tty|hidraw", GOTO="probe_rs_rules_end"

        # SEGGER J-Link mini
        ATTRS{idVendor}=="1366", ATTRS{idProduct}=="0101", MODE="660", GROUP="plugdev", TAG+="uaccess"

        LABEL="probe_rs_rules_end"
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
        xfce = {
          enable = true;
          noDesktop = true;
          enableXfwm = false;
        };
      };
      displayManager = {
        defaultSession = "xfce+xmonad";
        lightdm = {
          enable = true;
          greeters.gtk.extraConfig = ''
            background = #0F111A
          '';
        };
        sessionCommands = ''
          ${pkgs.xorg.xsetroot}/bin/xsetroot -solid black
          ${pkgs.xcape}/bin/xcape -e 'Control_L=Escape' -t 175
          ${pkgs.xorg.xinput}/bin/xinput disable 12 # Disable touchscreen
          ${pkgs.xorg.xset}/bin/xset s 10800 10800
          ${pkgs.picom}/bin/picom &
          ${pkgs.xbanish}/bin/xbanish &
          ${pkgs.haskellPackages.status-notifier-item}/bin/status-notifier-watcher &
          ${pkgs.dunst}/bin/dunst &
          ${pkgs.networkmanagerapplet}/bin/nm-applet --sm-disable --indicator &
          ${pkgs.redshift}/bin/redshift-gtk &
          ${pkgs.taffybar-my}/bin/taffybar-my &
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

  systemd.services.upower.enable = true;

  time.timeZone = "Europe/London";

  users.extraUsers.james = {
    createHome = true;
    extraGroups = [ "wheel" "video" "audio" "disk" "networkmanager" "docker" "dialout" ];
    group = "users";
    home = "/home/james";
    isNormalUser = true;
    uid = 1000;
  };

  virtualisation.docker.enable = true;

  xdg.mime.defaultApplications = {
    "text/html" = "brave-browser.desktop";
    "x-scheme-handler/http" = "brave-browser.desktop";
    "x-scheme-handler/https" = "brave-browser.desktop";
    "x-scheme-handler/about" = "brave-browser.desktop";
    "x-scheme-handler/unknown" = "brave-browser.desktop";
  };

  system.autoUpgrade.enable = true;
  system.stateVersion = "20.09";
}
