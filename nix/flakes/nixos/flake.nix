{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.colours = {
    url = "/home/james/dotfiles/nix/flakes/nixos/colours";
    flake = false;
  };

  outputs = { self, nixpkgs, unstable, colours }:
    let
      configuration = import ./configuration/macbook/configuration.nix;
      overlays = import ../overlays;
      unstable_ = import unstable { inherit system; config.allowUnfree = true; };
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
                  configuration (
                    args // {
                      colour = "${colours}/0f111a.png";
                      unstable = unstable_;
                    }
                  )
              )
            ];
        };
      };
}
