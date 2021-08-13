{ config, pkgs, ... }:

let
  unstable = pkgs.unstable;
in
{

  imports = [
    ../../modules/anki.nix
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
      skype
      unstable.slack
      zoom-us
      ### Misc
      unstable.brave
      calibre
      spotify
      unstable.syncplay
      vlc
      zotero
      ### Programming
      ## C++
      unstable.ccls
      ## Haskell
      unstable.cabal-install
      unstable.ghc
      unstable.haskellPackages.haskell-language-server
      ## Javascript
      nix-npm-install
      nodejs
      ## Nix
      unstable.cachix
      unstable.rnix-lsp
      ## Scala
      openjdk
      sbt
      scala
      ### Services
      unstable.awscli
      ### System
      alock
      arandr
      gnome2.gnome_icon_theme
      gnome3.adwaita-icon-theme
      gnome3.zenity
      gnupg
      hicolor-icon-theme
      libsecret
      mypolybar
      nix-prefetch-scripts
      openvpn
      paprefs # pulseaudio preferences
      pasystray # pulseaudio systray
      pavucontrol # pulseaudio volume control
      rofi
      termite
      update-resolv-conf
      xclip
      xfce.xfce4-power-manager
      ### Util
      asciicharts
      bat
      cntr
      direnv
      jq
      gitAndTools.gitFull
      git-crypt
      glances
      htop
      fd
      libnotify
      lsof
      ncdu
      usbutils
      unstable.neovim
      yarn # needed for coc.nvim's post-install step
      p7zip
      pciutils
      powertop
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
    };
    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
    };
    xpadneo.enable = true;
  };

  i18n = {
    inputMethod = {
      enabled = "fcitx";
      fcitx.engines = with pkgs.fcitx-engines; [ anthy mozc ];
    };
  };

  location.provider = "geoclue2";

  networking = {
    resolvconf.dnsExtensionMechanism = false; # this broke wifi for a hostel router
    networkmanager = {
      enable = true;
      packages = [
        pkgs.networkmanager-openvpn
        pkgs.networkmanagerapplet
      ];
    };
  };

  nix = {
    autoOptimiseStore = true;
    binaryCaches = [
      "https://cache.nixos.org/"
    ];
    trustedBinaryCaches = [
      "https://hydra.iohk.io"
      "https://jcarrag.cachix.org"
    ];
    trustedUsers = [ "root" "james" ];
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes ca-references
    '';
  };

  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
  };

  powerManagement.resumeCommands = ''
    ${pkgs.killall}/bin/killall -SIGUSR1 dunst
    ${pkgs.alock}/bin/alock
  '';

  programs = {
    anki = {
      enable = true;
      addons = [
        {
          ankiWebId = "3918629684";
          patches = [ pkgs.ankiJapanesePatch ];
          buildInputs = with pkgs; [ mecab kakasi ];
          sha256 = "yvhTyuu3FPM6P2rjWeV87jujnke8tBi+Pj1hGUDeOa8=";
        }
        {
          ankiWebId = "2413435972";
          patches = [ pkgs.ankiJapaneseExampleSentencesPatch ];
          addonConfig = {
            maxPermanent = 2;
            noteTypes = [ "Japanese (recognition&recall)" ];
          };
          sha256 = "V3R/diLJCIgZRmz35/5QBTztf10hqhryvTp69UrWfj4=";
        }
        {
          # True retention
          ankiWebId = "613684242";
          sha256 = "MDDscb6XoJDkXyx7puY9y7EbOxZVGZXcmD1R1g2207g=";
        }
        {
          # Edit field during review
          ankiWebId = "385888438";
          sha256 = "o/6kUXPU7TyMRRne43tJD4DQmhakjm1hyoKUorb+thU=";
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
    steam.enable = true;
  };

  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=-1
  '';

  services = {
    actkbd.enable = true;
    avahi = {
      enable = true;
      nssmdns = true;
      publish.enable = true;
      publish.userServices = true;
    };
    blueman.enable = true;
    dbus.enable = true;
    gnome.gnome-keyring.enable = true;
    localtime.enable = true;
    printing = {
      enable = true;
      browsing = true;
      drivers = [];
    };
    upower.enable = true;
    udev = {
      # swap left alt with meta on magicforce keyboard
      extraHwdb = ''
        evdev:input:b0003v04D9p0024*
          KEYBOARD_KEY_700e3=leftalt
          KEYBOARD_KEY_700e2=leftmeta
      '';
      extraRules = ''
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
      xkbOptions = "shift:both_capslock, caps:ctrl_modifier";
      desktopManager = {
        xterm.enable = true;
        xfce = {
          enable = true;
          noDesktop = true;
          enableXfwm = false;
          thunarPlugins = [ pkgs.xfce.thunar-archive-plugin pkgs.xfce.thunar-volman ];
        };
      };
      displayManager = {
        defaultSession = "xfce+xmonad";
        lightdm = {
          background = pkgs.colour;
          enable = true;
        };
        sessionCommands = ''
          ${pkgs.xorg.xsetroot}/bin/xsetroot -solid black
          ${pkgs.xorg.xmodmap}/bin/xmodmap -e 'Caps_Lock=Escape'
          ${pkgs.xcape}/bin/xcape -e 'Caps_Lock=Escape'
          ${pkgs.xorg.xinput}/bin/xinput disable 12 # Disable touchscreen
          ${pkgs.xorg.xset}/bin/xset s 10800 10800
          ${pkgs.picom}/bin/picom &
          ${pkgs.xbanish}/bin/xbanish &
          ${pkgs.haskellPackages.status-notifier-item}/bin/status-notifier-watcher &
          ${pkgs.dunst}/bin/dunst &
          ${pkgs.networkmanagerapplet}/bin/nm-applet --sm-disable --indicator &
          ${pkgs.redshift}/bin/redshift-gtk &
          ${pkgs.mypolybar}/bin/polybar &
        '';
      };
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
        extraPackages = hpkgs: [
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

  users.extraUsers.james = {
    createHome = true;
    extraGroups = [ "wheel" "video" "audio" "disk" "networkmanager" "docker" ];
    group = "users";
    home = "/home/james";
    isNormalUser = true;
    uid = 1000;
  };

  virtualisation.docker.enable = true;

  system.autoUpgrade.enable = true;
  system.stateVersion = "20.09";
}
