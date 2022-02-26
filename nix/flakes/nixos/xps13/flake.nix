{
  description = "A flake for my XPS 13 9310 2-in-1";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";
  inputs.unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.parsec.url = "github:DarthPJB/parsec-gaming-nix";

  outputs = { self, nixpkgs, unstable, parsec }:
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
	_self = self;
      };

      pkgs = import nixpkgs {
        inherit system; overlays = [ packageOverlays ];
      };

      nixos = nixpkgs.lib.nixosSystem {
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
              ({ ... }: { environment.systemPackages = [ parsec.packages.${system}.parsecgaming ]; })
            ];
        };
    in
      {
        packages.x86_64-darwin.neovim = nixos.options.programs.neovim.finalPackage.value.overrideAttrs (_: {
          system = "x86_64-darwin";
        });
        packages.x86_64-linux.neovim = nixos.options.programs.neovim.finalPackage;
        nixosConfigurations.nixos = nixos;
      };
}
