{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, unstable }:
    let
      configuration = import ./configuration/macbook/configuration.nix;
      overlays = import ../overlays;
      system = "x86_64-linux";
    in
      {
        nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
          system = system;
          modules =
            [
              (
                { pkgs, ... }: {
                  nixpkgs.overlays = [ overlays ];
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
