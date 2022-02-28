{
  description = "A flake for my systems";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.05";

  inputs.unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.parsec.url = "github:DarthPJB/parsec-gaming-nix";

  outputs = { self, nixpkgs, unstable, flake-utils, parsec }:
    let
      packageOverlays = import ../overlays;

      mkNixos = hostname: system:
        let
          laptopConfig = import ./${hostname}/configuration.nix;

          extrasOverlay = _: _: {
            unstable = import unstable {
              system = system;
              config.allowUnfree = true;
              nixpkgs.overlays = [ packageOverlays ];
            };
            colour = "${self}/nix/flakes/nixos/colours/0f111a.png";
            _self = self;
          };
        in
        nixpkgs.lib.nixosSystem {
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
              ({ ... }: {
                networking.hostName = hostname;
                environment.systemPackages = [ parsec.packages.${system}.parsecgaming ];
              })
            ];
        };
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        {
          packages = flake-utils.lib.flattenTree {
            neovim = (mkNixos "xps" system).options.programs.neovim.finalPackage.value;
          };
        }
      ) // {
      nixosConfigurations = {
        xps = mkNixos "xps" "x86_64-linux";
        mbp = mkNixos "mbp" "x86_64-linux";
        nuc = mkNixos "nuc" "x86_64-linux";
      };
    };
}
