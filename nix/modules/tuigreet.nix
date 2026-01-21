# https://discourse.nixos.org/t/automatically-unlocking-the-gnome-keyring-using-luks-key-with-greetd-and-hyprland/54260/11?u=jcarrag
{ pkgs, lib, ... }:

let
  tuigreetBin = "${pkgs.tuigreet}/bin/tuigreet";
  # session = "start-hyprland > /dev/null";
  session = "systemd-cat -t hyprland ${lib.getExe pkgs.hyprland}";
  username = "james"; # Change this to your username

  # Theme colors and spacing
  containerColor = "darkgray";
  borderColor = "lightblue";
  containerPadding = "3";
  timeFormat = "'%I:%M %p | %a • %h | %F'";

  # Package for pam_fde_boot_pw - retrieves LUKS password from systemd
  # https://git.sr.ht/~kennylevinsen/pam_fde_boot_pw
  pam_fde_boot_pw = pkgs.stdenv.mkDerivation {
    pname = "pam_fde_boot_pw";
    version = "0.1.0";

    src = pkgs.fetchzip {
      url = "https://git.sr.ht/~kennylevinsen/pam_fde_boot_pw/archive/master.tar.gz";
      sha256 = "sha256-dS9ufryg3xfxgUzJKDgrvMZP2qaYH+WJQFw1ogl1isc=";
    };

    nativeBuildInputs = [
      pkgs.pkg-config
      pkgs.meson
      pkgs.ninja
    ];
    buildInputs = [
      pkgs.pam
      pkgs.systemd
      pkgs.keyutils
    ];
  };
in
{

  environment.systemPackages = with pkgs; [
    tuigreet
    libsecret
    gnome-keyring
    libgnome-keyring
  ];

  # CRITICAL: Required for pam_fde_boot_pw to work
  # Stores the LUKS password in systemd so it can be retrieved later
  boot.initrd.systemd.enable = true;

  # Enable gnome-keyring service
  services.gnome.gnome-keyring.enable = true;

  # Enable the graphical frontend for managing keyring
  programs.seahorse.enable = true;

  # PAM Configuration
  # The key insight: greetd's initial_session (autologin) doesn't call PAM auth,
  # so we inject the LUKS password during the session phase instead using pam_fde_boot_pw.
  # See: https://lists.sr.ht/~kennylevinsen/greetd-devel/%3CCAOVAYzup8rEVtq1q4Bw5jZS=tf1WyeWwhHB0jgHvoZyhUuGZeg@mail.gmail.com%3E
  security.pam.services.greetd = {
    enableGnomeKeyring = true;

    # Add pam_fde_boot_pw rule BEFORE gnome_keyring in the session phase
    # This ensures the LUKS password is injected before gnome-keyring tries to unlock
    # Order 12600: gnome_keyring is typically at 12700, so this runs before it
    rules.session.fde_boot_pw = {
      order = 12500;
      # order = 12600;
      enable = true;
      control = "optional";
      modulePath = "${pam_fde_boot_pw}/lib/security/pam_fde_boot_pw.so";
      args = [ "inject_for=gkr" ];
    };
  };

  # Enable gnome-keyring for other PAM services
  security.pam.services = {
    greetd-password.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
    gdm-password.enableGnomeKeyring = true;
  };

  # greetd configuration
  services.greetd = {
    enable = true;
    settings = {
      # initial_session is used for autologin
      initial_session = {
        command = "${session}";
        user = "${username}";
      };
      # default_session is used for manual login
      default_session = {
        command = "${tuigreetBin} --remember --asterisks --container-padding ${containerPadding} --time --time-format ${timeFormat} --cmd '${session}' --theme 'container=${containerColor};border=${borderColor}'";
        user = "greeter";
      };
    };
  };

  # greetd systemd service configuration
  # CRITICAL for autologin to work properly
  # https://www.reddit.com/r/NixOS/comments/u0cdpi/tuigreet_with_xmonad_how/
  systemd.services.greetd.serviceConfig = {
    Type = "idle"; # DO NOT CHANGE - "simple" breaks autologin!
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
    KeyringMode = lib.mkForce "inherit";
  };

  # Disable getty@tty1 to prevent TTY interference
  # https://github.com/NixOS/nixpkgs/issues/103746
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # SSH agent configuration
  # programs.ssh.startAgent = false;
  # environment.sessionVariables = {
  #   SSH_AUTH_SOCK = "/run/user/1000/gcr/ssh";
  # };
}
