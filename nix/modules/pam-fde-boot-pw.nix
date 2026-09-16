{ pkgs, ... }:

pkgs.stdenv.mkDerivation {
  pname = "pam_fde_boot_pw";
  version = "unstable-2024";

  src = pkgs.fetchzip {
    url = "https://git.sr.ht/~kennylevinsen/pam_fde_boot_pw/archive/master.tar.gz";
    hash = "sha256-dS9ufryg3xfxgUzJKDgrvMZP2qaYH+WJQFw1ogl1isc=";
  };

  nativeBuildInputs = with pkgs; [
    meson
    ninja
    pkg-config
  ];
  buildInputs = with pkgs; [
    pam
    keyutils
  ];

  meta = with pkgs.lib; {
    description = "PAM module that transfers the LUKS passphrase from the kernel keyring to unlock gnome-keyring/kwallet on session open";
    homepage = "https://git.sr.ht/~kennylevinsen/pam_fde_boot_pw";
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
