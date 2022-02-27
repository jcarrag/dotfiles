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

      # darwinPkgs = import nixpkgs {
      #   system = "x86_64-darwin";
      #   overlays = [ extrasOverlay ];
      # };

      # neovimConfig = import "${self}/nix/flakes/modules/neovim.nix" { pkgs = darwinPkgs; };

      # neovimModuleSrc = import "${nixpkgs}/nixos/modules/programs/neovim.nix" {
      #   config = neovimConfig;
      #   lib = darwinPkgs.lib;
      #   pkgs = darwinPkgs;
      # };

      # darwinNeovim = (pkgs.lib.debug.traceVal neovimModuleSrc.config.content).programs.neovim.finalPackage;
      osx = nixpkgs.lib.nixosSystem {
          system = "x86_64-darwin";
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
        packages.x86_64-darwin.neovim = osx.options.programs.neovim.finalPackage.value;
        packages.x86_64-linux.neovim = nixos.options.programs.neovim.finalPackage.value;
        nixosConfigurations.nixos = nixos;
      };
}
