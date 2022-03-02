{
  description = "A flake for my systems";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";

  inputs.unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.parsec.url = "github:DarthPJB/parsec-gaming-nix";

  outputs = { self, nixpkgs, unstable, flake-utils, parsec }:
    let
      packageOverlays = import ../overlays;

      mkNixos = hostname: system: extraModules:
        let
          extrasOverlay = _: _: {
            unstable = import unstable {
              system = system;
              config.allowUnfree = true;
              nixpkgs.overlays = [ packageOverlays ];
            };
            colour = "${self}/nix/nixos/colours/0f111a.png";
            _self = self;
          };
        in
        nixpkgs.lib.nixosSystem {
          system = system;
          modules =
            [
              (import ./base-configuration.nix)
              {
                environment.systemPackages = [ parsec.packages.${system}.parsecgaming ];
                networking.hostName = hostname;
                nixpkgs.overlays = [ extrasOverlay packageOverlays ];
                nix.registry = {
                  self.flake = self;
                  nixpkgs.flake = nixpkgs;
                  unstable.flake = unstable;
                };
              }
            ] ++ extraModules;
        };
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        {
          packages = flake-utils.lib.flattenTree {
            neovim = (mkNixos "nixos" system [ ]).options.programs.neovim.finalPackage.value;
          };
        }
      ) // {
      nixosConfigurations = {
        xps = mkNixos "xps" "x86_64-linux"
          (map import [
            ./xps/hardware-configuration.nix
            ./xps/configuration.nix
            ../modules/moixa.nix
          ]);
        mbp = mkNixos "mbp" "x86_64-linux"
          (map import [
            ./mbp/hardware-configuration.nix
            ./mbp/configuration.nix
          ]);
        nuc = mkNixos "nuc" "x86_64-linux"
          (map import [
            ./nuc/hardware-configuration.nix
            ./nuc/configuration.nix
          ]);
      };
    };
}
