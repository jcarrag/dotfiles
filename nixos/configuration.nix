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
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;
  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];

  # Select internationalisation properties.
  i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enabled = "ibus";
      ibus.engines = with pkgs.ibus-engines; [ anthy ];
    };
  };

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  hardware.opengl = {
    driSupport = true;
    driSupport32Bit = true;
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

  fonts = {
    enableFontDir = true;
    enableCoreFonts = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      anonymousPro
      emojione
      corefonts
      dejavu_fonts
      font-droid
      freefont_ttf
      google-fonts
      inconsolata
      liberation_ttf
      powerline-fonts
      source-code-pro
      terminus_font
      ttf_bitstream_vera
      ubuntu_font_family
    ];
    fontconfig.ultimate.enable = false;
  };
  
  services.zerotierone = {
    enable = true;
    #port = 9993;
  };
  services.openvpn.servers = {
    anonine-swe  = {
      config = "config /home/james/Downloads/swe.ovpn";
      updateResolvConf = true;
      autoStart = false;
    };
    ec2gaming  = {
      config = "config /home/james/Downloads/ec2gaming.ovpn";
      updateResolvConf = true;
      autoStart = false;
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    tree
    vim
    hicolor-icon-theme
    gnome3.adwaita-icon-theme
    neovim
    idea.idea-community
    redshift
    vlc
    firefox
    tor-browser-bundle-bin
    zip
    unzip
    openvpn
    #network-manager-openvpn
    dropbox
    spotify
    steam
    discord
    slack
    xclip
    stow
    gnupg
    #haskell.compiler.ghc861
    ghc
    taffybar
    gnumake
    clang
    nodejs
    purescript
    nodePackages.pulp
    nodePackages.bower
    #haskellPackages.ghc-mod
    cabal-install
    sbt
    nodejs
    docker_compose
    lsof
    kitty
    rofi
    arandr
    gnome3.zenity
    git
    htop
    alock
    #networkmanagerapplet
    nix-prefetch-scripts
    which
    remmina
    tdesktop
    anki
    signal-desktop
  ];
  nixpkgs.config.allowUnfree = true;
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

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  virtualisation.docker.enable = false;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  sound.mediaKeys.enable = true;

  services.upower.enable = true;
  systemd.services.upower.enable = true;

  services.redshift = {
    enable = true;
    provider = "geoclue2";
  };
  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    layout = "us";
    xkbOptions = "eurosign:e";
    desktopManager = {
      default = "none";
      xterm.enable = false;
    };
    displayManager = {
      lightdm = {
        enable = true;
      };
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

  # Enable touchpad support.
  services.xserver.libinput.enable = true;

  programs.light.enable = true;
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 225 ]; events = [ "key" ]; command = "/run/wrappers/bin/light -A 10"; }
      { keys = [ 224 ]; events = [ "key" ]; command = "/run/wrappers/bin/light -U 10"; }
      #{ keys = [ 113 ]; events = [ "key" ]; command = "${pkgs.amixer} -q set Master toggle"; }
      #{ keys = [ 114 ]; events = [ "key" "rep" ]; command = "${pkgs}/bin/amixer -q set Master ${config.sound.mediaKeys.volumeStep}- unmute"; }
      #{ keys = [ 115 ]; events = [ "key" "rep" ]; command = "${pkgs}/bin/amixer -q set Master ${config.sound.mediaKeys.volumeStep}- unmute"; }
    ];
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.james = {
    createHome = true;
    extraGroups = ["wheel" "video" "audio" "disk" "networkmanager"];
    group = "users";
    home = "/home/james";
    isNormalUser = true;
    uid = 1000;
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
