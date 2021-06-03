self: super:

with super.lib;
let
  overlays = map import [
    ./anki.nix
    ./asciichart.nix
    ./feather-font/feather-font.nix
    ./ferdi.nix
    ./nix-npm-install.nix
    ./scripts.nix
    ./polar-bookshelf.nix
    ./polybar/polybar.nix
    ./virtualbox.nix
  ];
in
foldr (x: y: composeExtensions x y) (self: super: {}) overlays self super
