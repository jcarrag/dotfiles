self: super:

with super.lib;
let
  overlays = map import [
    ./aoe2de.nix
    ./anki.nix
    ./asciichart.nix
    ./feather-font/feather-font.nix
    ./ferdi.nix
    ./nix-npm-install.nix
    ./scripts.nix
    ./tmate.nix
    ./virtualbox.nix
  ];
in
foldr (x: y: composeExtensions x y) (self: super: { }) overlays self super
