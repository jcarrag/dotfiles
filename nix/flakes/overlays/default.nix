self: super:

with super.lib;
let
  overlays = map import [
    ./ferdi.nix
    ./haskell-language-server.nix
    ./nix-npm-install.nix
    ./taffybar.nix
  ];
in
foldr (x: y: composeExtensions x y) (self: super: {}) overlays self super
