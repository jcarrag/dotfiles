self: super:

with super.lib;
let
  overlays = map import [
    ./ferdi.nix
    ./haskell-language-server.nix
    ./metals.nix
    ./nix-npm-install.nix
    ./parsec.nix
    ./taffybar.nix
  ];
in
foldr (x: y: composeExtensions x y) (self: super: {}) overlays self super
