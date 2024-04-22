{
  description = "A flake for my systems";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

  inputs.unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.xremap.url = "github:xremap/nix-flake";

  inputs.parsec.url = "github:jcarrag/parsec-gaming-nix";

  # inputs.ynab-updater.url = "git+file:///home/james/dev/my/ynab_updater";
  inputs.ynab-updater.url = "github:jcarrag/ynab-updater";

  outputs = { self, nixpkgs, unstable, flake-utils, xremap, parsec, ynab-updater }:
    let
      packageOverlays = import ./nix/overlays;

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
            sudo nixos-rebuild switch --flake ~/dotfiles/nix#${hostname} "$@"
          '';
        in
        nixpkgs.lib.nixosSystem {
          system = system;
          modules =
            [
              (xremap.nixosModules.default)
              (ynab-updater.nixosModules.ynab-updater)
              (import ./nix/nixos/base-configuration.nix)
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
            ./nix/nixos/xps/hardware-configuration.nix
            ./nix/nixos/xps/configuration.nix
            ./nix/modules/moixa.nix
          ];
        mbp = mkNixos "mbp" "x86_64-linux"
          [
            ./nix/nixos/mbp/hardware-configuration.nix
            ./nix/nixos/mbp/configuration.nix
          ];
        nuc = mkNixos "nuc" "x86_64-linux"
          [
            ./nix/nixos/nuc/hardware-configuration.nix
            ./nix/nixos/nuc/configuration.nix
          ];
        hm90 = mkNixos "hm90" "x86_64-linux"
          [
            ./nix/nixos/hm90/hardware-configuration.nix
            ./nix/nixos/hm90/configuration.nix
          ];
        fwk = mkNixos "fwk" "x86_64-linux"
          [
            ./nix/nixos/fwk/hardware-configuration.nix
            ./nix/nixos/fwk/configuration.nix
          ];
      };
    };
}
