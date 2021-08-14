{
  description = "A flake for my NUC NUC9i7QNX";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
  inputs.unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.colours = {
    url = "github:jcarrag/dotfiles?dir=nix/flakes/nixos/colours";
    flake = false;
  };

  outputs = { self, nixpkgs, unstable, colours }:
    let
      system = "x86_64-linux";

      laptopConfig = import ./configuration.nix;

      packageOverlays = import ../../overlays;

      extrasOverlay = _: _: {
        unstable = import unstable {
          system = system;
          config.allowUnfree = true;
          nixpkgs.overlays = [ packageOverlays ];
        };
        colour = "${colours}/0f111a.png";
      };
    in
      {
        nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
          system = system;
          modules =
            [
              {
                nixpkgs.overlays = [ extrasOverlay packageOverlays ];
                nix.registry = {
                  self.flake = self;
                  nixpkgs.flake = nixpkgs;
                  unstable.flake = unstable;
                };
              }
              laptopConfig
            ];
        };
      };
}
