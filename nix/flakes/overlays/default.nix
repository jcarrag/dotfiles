self: super:

with super.lib;
let
  overlays = map import [
    ./anki.nix
    ./ferdi.nix
    ./nix-npm-install.nix
    ./scripts.nix
    ./parsec.nix
    ./polar-bookshelf.nix
    ./virtualbox.nix
  ];
in
foldr (x: y: composeExtensions x y) (self: super: {}) overlays self super
