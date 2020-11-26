{ config, pkgs, unstable, colour, ... }:

{

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    extraModprobeConfig = ''
      xpad
    '';
  };

  environment.systemPackages = with pkgs;
    [
      ### Communication
      discord
      ferdi
      skype
      zoom-us
      ### Misc
      anki
      brave
      calibre
      parsec
      spotify
      steam
      vlc
      zotero
      ### Programming
      ## C++
      unstable.ccls
      ## Haskell
      cabal-install
      ghc
      haskell-language-server
      ## Javascript
      nix-npm-install
      nodejs
      ## Nix
      cachix
      rnix-lsp
      ### Services
      awscli
      ### System
      alock
      arandr
      kitty
      gnome2.gnome_icon_theme
      gnome3.adwaita-icon-theme
      gnome3.zenity
      gnupg
      hicolor-icon-theme
      libsecret
      nix-prefetch-scripts
      openvpn
      paprefs # pulseaudio preferences
      pasystray # pulseaudio systray
      pavucontrol # pulseaudio volume control
      rofi
      taffybar
      update-resolv-conf
      xclip
      ### Util
      bat
      direnv
      jq
      gitAndTools.gitFull
      htop
      libnotify
      lsof
      neovim
      yarn # needed for coc.nvim's post-install step
      powertop
      ripgrep
      stow
      tree
      unzip
      usbutils
      watchexec
      which
      zip
    ];

  fonts = {
    fonts = with pkgs; [
      emojione
      (nerdfonts.override { fonts = [ "Hack" ]; })
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
    ];
  };

  hardware = {
    facetimehd.enable = true;
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
  };

  i18n = {
    inputMethod = {
      enabled = "fcitx";
      fcitx.engines = with pkgs.fcitx-engines; [ anthy mozc ];
    };
  };

  location.provider = "geoclue2";

  networking = {
    hostName = "nixos";
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
    binaryCaches = [
      "https://cache.nixos.org/"
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
    autojump.enable = true;
    bash.enableCompletion = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    light.enable = true;
  };

  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=-1
  '';

  services = {
    actkbd = with pkgs; {
      enable = true;
      bindings = [
        { keys = [ 225 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -A 5"; }
        { keys = [ 224 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -U 5"; }
        { keys = [ 67 ]; events = [ "key" ]; command = "${alsaUtils}/bin/amixer -q set Master toggle"; }
        { keys = [ 68 ]; events = [ "key" "rep" ]; command = "${alsaUtils}/bin/amixer -q set Master ${config.sound.mediaKeys.volumeStep}- unmute"; }
        { keys = [ 69 ]; events = [ "key" "rep" ]; command = "${alsaUtils}/bin/amixer -q set Master ${config.sound.mediaKeys.volumeStep}+ unmute"; }
      ];
    };
    avahi = {
      enable = true;
      nssmdns = true;
      publish.enable = true;
      publish.userServices = true;
    };
    blueman.enable = true;
    dbus = {
      enable = true;
      socketActivated = true;
    };
    gnome3.gnome-keyring.enable = true;
    localtime.enable = true;
    openvpn.servers = {
      anonine-swe = {
        config = ''config /home/james/vpn/anonine-swe.ovpn'';
        autoStart = false;
      };
      anonine-uk = {
        config = ''config /home/james/vpn/anonine-uk-iplayer.ovpn'';
        autoStart = false;
      };
    };
    printing = {
      enable = true;
      browsing = true;
      drivers = [];
    };
    redshift.enable = true;
    upower.enable = true;
    udev.extraRules = ''
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
    xserver = {
      enable = true;
      exportConfiguration = true;
      startDbusSession = true;
      libinput = {
        enable = true;
        disableWhileTyping = true;
        accelSpeed = "0.0";
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
        };
      };
      displayManager = {
        defaultSession = "xfce+xmonad";
        lightdm = {
          background = colour;
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
          ${pkgs.taffybar}/bin/taffybar &
        '';
      };
      windowManager.xmonad = {
        enable = true;
        enableContribAndExtras = true;
        extraPackages = hpkgs: [
          hpkgs.taffybar
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

  system.autoUpgrade.enable = true;
  system.stateVersion = "20.09";
}