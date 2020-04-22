# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModprobeConfig = ''
    xpad
  '';

  networking.hostName = "nixos"; # Define your hostname.
  networking.resolvconf.dnsExtensionMechanism = false; # this broke wifi for a hostel router
  networking.extraHosts = ''
    127.0.0.1       akka1
    127.0.0.1       cassandra
    127.0.0.1       elastic
    127.0.0.1       elastic5
    127.0.0.1       elastic6
    127.0.0.1       kafka
    127.0.0.1       redis
    127.0.0.1       consumers
    127.0.0.1       merchants
    127.0.0.1       messages
    127.0.0.1       webhooks
    127.0.0.1       pts
  '';
  networking.networkmanager = {
    enable = true;
    packages = [ pkgs.networkmanager-openvpn (import <unstable> {}).networkmanagerapplet ];
  };

  i18n = {
    inputMethod = {
      enabled = "fcitx";
      fcitx.engines = with pkgs.fcitx-engines; [ anthy mozc ];
    };
  };

  # Set your time zone.
  time.timeZone = "Asia/Tokyo"; #"Europe/London";

  hardware.bluetooth = {
    enable = true;
    package = pkgs.bluezFull.overrideAttrs (oldAttrs: {
      configureFlags = oldAttrs.configureFlags ++ [ "--enable-sixaxis" ];
    });
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
    binaryCaches = [
      "https://cache.nixos.org/"
      "https://all-hies.cachix.org"
    ];
    binaryCachePublicKeys = [
      "all-hies.cachix.org-1:JjrzAOEUsD9ZMt8fdFbzo3jNAyEWlPAwdVuHw4RD43k="
    ];
    trustedUsers = [ "root" "james" ];
    nixPath = [
      "/nix/var/nix/profiles/per-user/root/channels"
      "nixpkgs=/home/james/nix-channels/19.09/nixpkgs"
      "nixos-config=/etc/nixos/configuration.nix"
    ];
  };

  services.udev.extraRules = ''
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
    fonts = with pkgs; [ 
      hack-font
      fira
      fira-code
      fira-mono
      powerline-fonts

      noto-fonts
      noto-fonts-cjk

      noto-fonts-emoji
      emojione
    ];
  };
  
  environment.systemPackages = with pkgs; let
    all-hies = import (fetchTarball "https://github.com/infinisil/all-hies/tarball/master") {};
    easyPS = import (fetchFromGitHub {
      owner = "justinwoo";
      repo = "easy-purescript-nix";
      rev = "6cb5825430ab44719139f28b93d50c5810891366";
      sha256 = "1awsywpw92xr4jmkwfj2s89wih74iw4ppaifc97n9li4pyds56h4";
    }) {};
  in
    [
      libnotify
      unstable.awscli
      cachix
      cassandra
      dolphin
      dfeet
      unstable.bustle
      wget
      tree
      vim
      texlive.combined.scheme-small
      hicolor-icon-theme
      gnome2.gnome_icon_theme
      gnome3.adwaita-icon-theme
      unstable.gnome3.seahorse
      libsecret
      wireshark
      my-neovim
      redshift
      vlc
      unstable.firefox
      unstable.google-chrome
      calibre
      zip
      unzip
      my-terraform.terraform_0_12_6
      openvpn
      update-resolv-conf
      tor-browser-bundle-bin
      electrum
      dropbox
      pavucontrol # pulseaudio volume control
      paprefs # pulseaudio preferences
      pasystray # pulseaudio systray
      spotify
      unstable.steam
      parsec
      unstable.discord
      skype
      unstable.slack
      xclip
      stow
      gnupg
      photon
      gcc
      taffybar
      ripgrep
      gnumake
      cmake
      clang
      clang-tools
      cquery
      jdk
      direnv
      # Javascript
      unstable.nodejs
      yarn
      nodePackages.node2nix
      nix-npm-install
      # Scala
      scala
      sbt
      # Python
      python
      nix-pip-install
      # Clojure
      clojure
      leiningen
      # Haskell
      #haskellPackages.ghc-mod
      (all-hies.selection { selector = p: { inherit (p) ghc844; }; })
      #haskell.compiler.ghc861
      #ghc
      #unstable.stack
      #haskellPackages.hoogle
      #cabal-install
      docker_compose
      watchexec
      lsof
      unstable.kitty
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
      haskellPackages.niv
      nix-prefetch-scripts
      which
      remmina
      okular
      libreoffice
      zotero
      tdesktop
      gnome3.pomodoro
      anki
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
  programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  programs.fish.enable = true;
  programs.autojump.enable = true;

  # List services that you want to enable:
  services.blueman.enable = true;
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
  services.lorri.enable = true;

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  virtualisation.docker.enable = true;

  # Enable sound.
  sound.enable = true;
  sound.mediaKeys.enable = true;

  services.upower.enable = true;
  powerManagement.resumeCommands = ''
    ${pkgs.killall}/bin/killall -SIGUSR1 dunst
    ${pkgs.alock}/bin/alock
  '';
  systemd.services.upower.enable = true;

  location.provider = "geoclue2";
  services.redshift = {
    enable = true;
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    startDbusSession = true;
    libinput = {
      enable = true;
      disableWhileTyping = true;
    };
    serverLayoutSection = ''
      Option "StandbyTime" "0"
      Option "SuspendTime" "0"
      Option "OffTime"     "0"
    '';
    layout = "us";
    xkbOptions = "shift:both_capslock, caps:ctrl_modifier";
    desktopManager = {
      default = "xfce";
      xterm.enable = true;
      xfce = {
        enable = true;
	noDesktop = true;
	enableXfwm = false;
      };
    };
    displayManager = {
      lightdm = {
        enable = true;
      };
      sessionCommands = ''
        ${pkgs.xorg.xmodmap}/bin/xmodmap -e 'Caps_Lock=Escape'
        ${pkgs.xcape}/bin/xcape -e 'Caps_Lock=Escape'
        ${pkgs.xorg.xinput}/bin/xinput disable 12 # Disable touchscreen
        ${pkgs.xorg.xset}/bin/xset s 10800 10800
	${pkgs.haskellPackages.status-notifier-item}/bin/status-notifier-watcher &
        ${pkgs.dunst}/bin/dunst &
        ${pkgs.networkmanagerapplet}/bin/nm-applet --sm-disable --indicator &
        ${pkgs.taffybar}/bin/taffybar &
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
	hpkgs.xmonad
      ];
    };
  };

  services.dbus.enable = true;
  services.dbus.socketActivated = true;

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
  };

  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=-1
  '';

  system.autoUpgrade.enable = true;
  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

}
