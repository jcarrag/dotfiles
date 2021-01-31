self: super:

with super.lib;
let
  overlays = map import [
    ./ferdi.nix
    ./nix-npm-install.nix
    ./parsec.nix
    ./virtualbox.nix
  ];
in
foldr (x: y: composeExtensions x y) (self: super: {}) overlays self super
