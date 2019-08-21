# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  networking.extraHosts = ''
    127.0.0.1       akka1
    127.0.0.1       cassandra
    127.0.0.1       elastic
    127.0.0.1       elastic5
    127.0.0.1       elastic6
    127.0.0.1       redis
    127.0.0.1       consumers
    127.0.0.1       merchants
    127.0.0.1       messages
    127.0.0.1       webhooks
    127.0.0.1       pts
  '';
  #networking.nameservers = [ "8.8.8.8" ];
  #networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager = {
    enable = true;
    packages = [ pkgs.networkmanager-openvpn pkgs.networkmanagerapplet ];
  };

  # Select internationalisation properties.
  i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [ anthy mozc uniemoji ];
    };
  };

  # Set your time zone.
  time.timeZone =  "Asia/Tokyo"; #"Europe/London";

  #hardware.powermanagement = {
  #  enable = true;
  #  cpuFreqGovernor = "ondemand";
  #};

  hardware.bluetooth = {
    enable = true;
    extraConfig = ''
      [General]
      Enable=Source,Sink,Media,Socket
    '';
  };

  hardware.opengl = {
    driSupport = true;
    driSupport32Bit = true;
  };

  hardware.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  nix = {
    nixPath = [
      "/etc/nixos"
      "/nix/var/nix/profiles/per-user/root/channels"
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs"
      "nixos-config=/etc/nixos/configuration.nix"
      "nixpkgs-overlays=/home/james/.config/nixpkgs/overlays"
    ];
  };

  #services.resolved.enable = true;
  #services.resolved.fallbackDns = [
  #  "8.8.8.8"
  #  "172.26.0.2" # hack to paidy-fargate-non-production vpn working
  #];
  #systemd.services.systemd-resolved.environment.SYSTEMD_LOG_LEVEL = "debug";

  services.openvpn.servers = {
    anonine-swe = {
      config = ''config /home/james/vpn/anonine-swe.ovpn'';
      autoStart = false;
    };
    anonine-uk = {
      config = ''config /home/james/vpn/anonine-uk-iplayer.ovpn'';
      autoStart = false;
    };
  };

  fonts = {
    #enableFontDir = true;
    #enableCoreFonts = true;
    #enableGhostscriptFonts = true;
    #fonts = with pkgs; [
    #  anonymousPro
    #  emojione
    #  corefonts
    #  dejavu_fonts
    #  freefont_ttf
    #  google-fonts
    #  inconsolata
    #  liberation_ttf
    #  powerline-fonts
    #  source-code-pro
    #  terminus_font
    #  ttf_bitstream_vera
    #  ubuntu_font_family
    #];
    #fontconfig.ultimate.enable = false;
    fonts = with pkgs; [ 
      emojione
      ipafont
      powerline-fonts
      ubuntu_font_family
      google-fonts
      inconsolata
      baekmuk-ttf
      kochi-substitute
      carlito
    ];

    fontconfig = { 
      defaultFonts = {
        monospace = [ 
          "DejaVu Sans Mono for Powerline"
          "IPAGothic"
          "Baekmuk Dotum"
	  "EmojiOne Color"
        ];
        serif = [ 
          "DejaVu Serif"
          "IPAPMincho"
          "Baekmuk Batang"
	  "EmojiOne Color"
        ];
        sansSerif = [
          "DejaVu Sans"
          "IPAPGothic"
          "Baekmuk Dotum"
	  "EmojiOne Color"
        ];
      };
    };
  };
  
  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; let
  in
    [
      cassandra
      dolphin
      dfeet
      wget
      tree
      vim
      texlive.combined.scheme-small
      hicolor-icon-theme
      gnome2.gnome_icon_theme
      gnome3.adwaita-icon-theme
      unstable.gnome3.seahorse
      libsecret
      networkmanagerapplet
      my-neovim
      redshift
      vlc
      firefox
      google-chrome
      unstable.chromium
      zip
      unzip
      unstable.terraform
      ammonite
      openvpn
      update-resolv-conf
      tor-browser-bundle-bin
      electrum
      dropbox
      blueman
      pavucontrol # pulseaudio volume control
      paprefs # pulseaudio preferences
      pasystray # pulseaudio systray
      spotify
      unstable.steam
      discord
      skype
      slack
      xclip
      stow
      gnupg
      photon
      #haskell.compiler.ghc861
      ghc
      unstable.stack
      haskellPackages.hoogle
      taffybar
      ripgrep
      gnumake
      cmake
      clang
      clang-tools
      cquery
      nodejs
      yarn
      nodePackages.node2nix
      nix-npm-install
      psc-package
      scala
      python
      clojure
      leiningen
      jdk
      nodePackages.pulp
      nodePackages.bower
      #haskellPackages.ghc-mod
      #hies
      watchexec
      cabal-install
      sbt
      nodejs
      docker_compose
      lsof
      kitty
      rofi
      arandr
      gnome3.zenity
      shutter
      my-postman
      mitmproxy
      gitAndTools.gitFull
      git-hub
      htop
      alock
      nix-prefetch-scripts
      which
      remmina
      okular
      libreoffice
      zotero
      tdesktop
      gnome3.pomodoro
      unstable.anki
      mecab
      kakasi
      signal-desktop
      unstable.idea.idea-community
    ];
  nixpkgs.config = {
    allowUnfree = true;
    allowBroken = true;
    packageOverrides = pkgs: {
      unstable = import <unstable> 
        { 
            # pass the nixpkgs config to the unstable alias
            # to ensure `allowUnfree = true;` is propagated:
            config = config.nixpkgs.config; 
        };
    };
  };
  nixpkgs.overlays =
      let
        path = "/home/james/.config/nixpkgs/overlays";
      in with builtins;
      map (n: import (path + ("/" + n)))
          (filter (n: match ".*\\.nix" n != null ||
                      pathExists (path + ("/" + n + "/default.nix")))
          (attrNames (readDir path)));

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.bash.enableCompletion = true;
  # programs.mtr.enable = true;
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  programs.fish.enable = true;
  programs.autojump.enable = true;

  # List services that you want to enable:
  services.printing = {
    enable = true;
    browsing = true;
    drivers = [];
  };
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish.enable = true;
    publish.userServices = true;
  };
  services.gnome3.gnome-keyring.enable = true;

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  virtualisation.docker.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable sound.
  sound.enable = true;
  sound.mediaKeys.enable = true;

  services.upower.enable = true;
  powerManagement.resumeCommands = ''
    ${pkgs.alock}/bin/alock
  '';
  systemd.services.upower.enable = true;

  services.redshift = {
    enable = true;
    provider = "manual";
    longitude = "139.69";
    latitude = "35.69";
  };

  # Enable the KDE Desktop Environment.
  #services.xserver.displayManager.sddm.enable = true;
  #services.xserver.desktopManager.plasma5.enable = true;
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    startDbusSession = true;
    libinput = {
      enable = true;
      disableWhileTyping = true;
  #    accelSpeed = "0.5";
    };
    serverLayoutSection = ''
      Option "StandbyTime" "0"
      Option "SuspendTime" "0"
      Option "OffTime"     "0"
    '';
    xrandrHeads = [
      { output = "eDP1";
        primary = true;
        monitorConfig = ''
          Option "PreferredMode" "2048x1152"
          Option "Position" "512 1784"
        ''; }
      { output = "DP1";
        monitorConfig = ''
          Option "PreferredMode" "2560x1440"
          Option "Position" "0 344"
        ''; }
      { output = "DP2";
        monitorConfig = ''
          Option "Rotate" "left"
          Option "PreferredMode" "2560x1440"
          Option "Position" "2560 0"
        ''; }
    ];
    resolutions = [
      { x = 2048; y = 1152; }
      { x = 1920; y = 1080; }
      { x = 2560; y = 1440; }
      { x = 3072; y = 1728; }
      { x = 3840; y = 2160; }
    ];
    layout = "us";
    xkbOptions = "shift:both_capslock, caps:ctrl_modifier";
    #xkbOptions = "ctrl:nocaps, caps:ctrl_modifier";
    desktopManager = {
      default = "none";
      xterm.enable = false;
    };
    displayManager = {
      lightdm = {
        enable = true;
      };
      sessionCommands = ''
        ## Make space Super_L
        #${pkgs.xorg.xmodmap}/bin/xmodmap -e "keycode 65 = Hyper_L"
        #${pkgs.xorg.xmodmap}/bin/xmodmap -e "remove mod4 = Hyper_L" # hyper_l is mod4 by default
        #${pkgs.xorg.xmodmap}/bin/xmodmap -e "add Super_L = Hyper_L"
        ## Map space to an unused keycode (to keep it around for xcape to use).
        #${pkgs.xorg.xmodmap}/bin/xmodmap -e "keycode any = space"
        ## Finally use xcape to cause the space bar to generate a space when tapped.
        #${pkgs.xcape}/bin/xcape -e "Hyper_L=space"

        ${pkgs.xorg.xmodmap}/bin/xmodmap -e 'Caps_Lock=Escape'
        ${pkgs.xcape}/bin/xcape -e 'Caps_Lock=Escape'
        ${pkgs.xorg.xinput}/bin/xinput disable 12 # Disable touchscreen
      '';
    };
    windowManager.default = "xmonad";
    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      extraPackages = hpkgs: [
        hpkgs.taffybar
        hpkgs.xmonad-extras
        hpkgs.xmonad-contrib
      ];
    };
  };

  services.dbus.enable = true;
  services.dbus.socketActivated = true;

  systemd.user.services.status-notifer-watcher =
    let
      unstable = import <unstable> {};
    in
      {
        enable = true;
        description = "Status Notifier Watcher";
        wantedBy = [ "graphical-session.target" ];
        after = [ "graphical-session-pre.target" ];
        partOf = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = [ "${unstable.haskellPackages.status-notifier-item}/bin/status-notifier-watcher" ];
        };
        environment = {
          DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
        };
      };

  systemd.user.services.taffybar = {
    enable = true;
    description = "Taffybar status bar";
    wantedBy = [ "graphical-session.target" ];
    after = [ "status-notifier-watcher.service" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = [ "${pkgs.taffybar}/bin/taffybar" ];
    };
    environment = {
      DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
    };
  };

  systemd.user.services.ibus = {
    enable = true;
    description = "Ibus";
    wantedBy = [ "graphical-session.target" ];
    after = [ "taffbar.service" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = [ "${pkgs.ibus-with-plugins}/bin/ibus-daemon -d -r" ];
    };
    environment = {
      DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
    };
  };

  systemd.user.services.network-manager-applet = {
    enable = true;
    description = "Network Manager applet";
    wantedBy = [ "graphical-session.target" ];
    after = [ "taffybar.service" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = toString (
        [
          "${pkgs.networkmanagerapplet}/bin/nm-applet"
          "--sm-disable"
	  "--indicator"
        ]
      );
    };
    environment = {
      DBUS_SESSION_BUS_ADDRESS = "unix:path=/run/user/1000/bus";
    };
  };

  systemd.services.alock = {
    enable = true;
    requires = [
      "display-manager.service"
    ];
    description = "Alock";
    serviceConfig = {
      Type = "oneshot";
      StandardOutput = "syslog";
      ExecStart = "${pkgs.alock}/bin/alock";
    };
  };

  programs.light.enable = true;
  services.actkbd = with pkgs; {
    enable = true;
    bindings = [
      { keys = [ 225 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -A 5"; }
      { keys = [ 224 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -U 5"; }
      { keys = [ 67 ]; events = [ "key" ]; command = "${alsaUtils}/bin/amixer -q set Master toggle"; }
      { keys = [ 68 ]; events = [ "key" "rep" ]; command = "${alsaUtils}/bin/amixer -q set Master ${config.sound.mediaKeys.volumeStep}- unmute"; }
      { keys = [ 69 ]; events = [ "key" "rep" ]; command = "${alsaUtils}/bin/amixer -q set Master ${config.sound.mediaKeys.volumeStep}+ unmute"; }
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.james = {
    createHome = true;
    extraGroups = ["wheel" "video" "audio" "disk" "networkmanager" "docker"];
    group = "users";
    home = "/home/james";
    isNormalUser = true;
    uid = 1000;
    #shell = "/run/current-system/sw/bin/fish";
  };

  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=-1
  '';

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?

}
