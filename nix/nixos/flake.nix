{
  description = "A flake for my systems";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

  inputs.unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.xremap.url = "github:xremap/nix-flake";

  inputs.parsec.url = "github:jcarrag/parsec-gaming-nix";

  inputs.ynab-updater.url = "github:jcarrag/ynab-updater";

  outputs = { self, nixpkgs, unstable, flake-utils, xremap, parsec, ynab-updater }:
    let
      packageOverlays = import ../overlays;

      mkNixos = hostname: system: modules:
        let
          extrasOverlay = _: _: {
            unstable = import unstable {
              system = system;
              config = {
                allowUnfree = true;
                segger-jlink.acceptLicense = true;
              };
              nixpkgs.overlays = [ packageOverlays ];
            };
            _self = self;
          };
          rebuild = (import nixpkgs { inherit system; }).writeShellScriptBin "rebuild" ''
            set -x
            sudo nixos-rebuild switch --flake ~/dotfiles/#${hostname} "$@"
          '';
        in
        nixpkgs.lib.nixosSystem {
          system = system;
          modules =
            [
              (xremap.nixosModules.default)
              (ynab-updater.nixosModules.ynab-updater)
              (import ./base-configuration.nix)
              {
                environment.systemPackages = [
                  parsec.packages.${system}.parsecgaming
                  rebuild
                ];
                networking.hostName = hostname;
                nixpkgs.overlays = [ extrasOverlay packageOverlays ];
                nix.registry = {
                  self.flake = self;
                  nixpkgs.flake = nixpkgs;
                  unstable.flake = unstable;
                };
              }
            ] ++ (map import modules);
        };
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        {
          packages = flake-utils.lib.flattenTree {
            neovim = (mkNixos "nixos" system [ ]).options.programs.neovim.finalPackage.value;
            tmate = (import nixpkgs { inherit system; overlays = [ packageOverlays ]; }).tmate-my;
          };
        }
      ) // {
      nixosConfigurations = {
        xps = mkNixos "xps" "x86_64-linux"
          [
            ./xps/hardware-configuration.nix
            ./xps/configuration.nix
            ../modules/moixa.nix
          ];
        mbp = mkNixos "mbp" "x86_64-linux"
          [
            ./mbp/hardware-configuration.nix
            ./mbp/configuration.nix
          ];
        nuc = mkNixos "nuc" "x86_64-linux"
          [
            ./nuc/hardware-configuration.nix
            ./nuc/configuration.nix
          ];
        hm90 = mkNixos "hm90" "x86_64-linux"
          [
            ./hm90/hardware-configuration.nix
            ./hm90/configuration.nix
          ];
        fwk = mkNixos "fwk" "x86_64-linux"
          [
            ./fwk/hardware-configuration.nix
            ./fwk/configuration.nix
          ];
      };
    };
}
