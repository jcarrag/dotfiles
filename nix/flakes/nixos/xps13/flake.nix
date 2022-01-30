{
  description = "A flake for my XPS 13 9310 2-in-1";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
  inputs.unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, unstable }:
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
        colour = "${self}/nix/flakes/nixos/colours/0f111a.png";
      };

      pkgs = import nixpkgs {
        inherit system; overlays = [ packageOverlays ];
      };
    in
      {
        packages.x86_64-linux.vim = pkgs.my-neovim;
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
