{ config, pkgs, ... }:

# Framework 13 fingerprint sensor (Goodix 27c6:609c, in the power button).
# Enroll once per host: `fprintd-enroll`, check with `fprintd-verify`.
# Firmware updates come via fwupd (`fwupdmgr get-updates`).
{
  services.fprintd.enable = true;

  # NixOS adds pam_fprintd as "sufficient" to every PAM service by default.
  # Opt the ones out where a *typed* password matters:
  security.pam.services = {
    # greetd/login: on lunar-fwk pam_fde_boot_pw + pam_gnome_keyring need the
    # typed password to unlock the login keyring; a fingerprint login would
    # leave it locked. fwk has no such hand-off, so allow it there (the
    # keyring just prompts on first use instead).
    greetd.fprintAuth = config.networking.hostName == "fwk";
    login.fprintAuth = false;
    # hyprlock talks to fprintd itself (auth { fingerprint { enabled = true } }
    # in hyprlock.conf) so finger and password are accepted concurrently.
    # Via PAM, pam_fprintd would block the password prompt until timeout.
    hyprlock.fprintAuth = false;
  };
  # Left on (defaults): sudo, polkit-1 (e.g. 1Password's system-auth unlock).

  # polkit authentication agent for the Hyprland session. Without one nothing
  # can show a polkit prompt (1Password "unlock using system authentication",
  # udisks mounts from Thunar, fwupd...), so the polkit-1 PAM stack above --
  # and its fingerprint rule -- never gets exercised. The package ships a
  # user unit (WantedBy=graphical-session.target, which uwsm manages); NixOS
  # ignores [Install] sections so the wantedBy is restated here.
  systemd.packages = [ pkgs.unstable.hyprpolkitagent ];
  systemd.user.services.hyprpolkitagent.wantedBy = [ "graphical-session.target" ];
}
