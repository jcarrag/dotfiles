{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.03";
  inputs.unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.overlays.url = "overlays";

  outputs = { self, nixpkgs, unstable, overlays }:
    let
      configuration = import ../../../nixos/macbook/configuration.nix;
      system = "x86_64-linux";
    in
      {
        nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
          system = system;
          modules =
            [
              (
                { pkgs, ... }: {
                  nixpkgs.overlays = [ overlays.overlays ];
                  nix.registry.nixpkgs.flake = nixpkgs;
                }
              )
              (
                args@{ pkgs, ... }:
                  configuration (args // { unstable = unstable.legacyPackages.${system}; })
              )
            ];
        };
      };
}
