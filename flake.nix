{
  description = "A flake for my systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    xremap.url = "github:xremap/nix-flake";
    # ynab-updater.url = "git+file:///home/james/dev/my/ynab_updater";
    ynab-updater.url = "github:jcarrag/ynab-updater";
    neovim = {
      url = "github:jcarrag/neovim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kolide-launcher = {
      url = "github:/kolide/nix-agent/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      unstable,
      flake-utils,
      ...
    }:
    let
      packageOverlays = import ./nix/overlays;
      mkNixos =
        hostname: system: modules: importModules:
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
          rebuild =
            with (import nixpkgs { inherit system; });
            writeShellScriptBin "rebuild" ''
              set -x
              EXTRA_ARGS="$@"
              sudo sh -c "nixos-rebuild switch \
              --flake /home/james/dotfiles#${hostname} \
              --accept-flake-config \
              --log-format internal-json \
              --verbose \
              ''${EXTRA_ARGS} \
              |& ${nix-output-monitor}/bin/nom --json"
            '';
          nixosSystem = import (nixpkgs + "/nixos/lib/eval-config.nix");
        in
        nixosSystem {
          system = system;
          modules =
            [
              inputs.xremap.nixosModules.default
              (import ./nix/nixos/base-configuration.nix)
              {
                environment.systemPackages = [
                  rebuild
                  inputs.neovim.packages.${system}.neovim
                ];
                networking.hostName = hostname;
                nixpkgs.overlays = [
                  extrasOverlay
                  packageOverlays
                ];
                nix.registry = {
                  self.flake = self;
                  nixpkgs.flake = nixpkgs;
                  unstable.flake = unstable;
                };
              }
            ]
            ++ modules
            ++ (map import importModules);
        };
    in
    flake-utils.lib.eachDefaultSystem (system: {
      packages = flake-utils.lib.flattenTree {
        neovim = inputs.neovim.packages.${system}.neovim;
        tmate =
          (import nixpkgs {
            inherit system;
            overlays = [ packageOverlays ];
          }).tmate-my;
      };
    })
    // {
      nixosConfigurations = {
        mbp =
          mkNixos "mbp" "x86_64-linux"
            [ ]
            [
              ./nix/nixos/mbp/hardware-configuration.nix
              ./nix/nixos/mbp/configuration.nix
            ];
        nuc =
          mkNixos "nuc" "x86_64-linux"
            [ ]
            [
              ./nix/nixos/nuc/hardware-configuration.nix
              ./nix/nixos/nuc/configuration.nix
            ];
        hm90 =
          mkNixos "hm90" "x86_64-linux"
            [
              inputs.ynab-updater.nixosModules.ynab-updater
            ]
            [
              ./nix/nixos/hm90/hardware-configuration.nix
              ./nix/nixos/hm90/configuration.nix
            ];
        fwk =
          mkNixos "fwk" "x86_64-linux"
            [
              inputs.ynab-updater.nixosModules.ynab-updater
            ]
            [
              ./nix/nixos/fwk/hardware-configuration.nix
              ./nix/nixos/fwk/configuration.nix
            ];
        lunar-fwk =
          mkNixos "lunar-fwk" "x86_64-linux"
            [
              inputs.kolide-launcher.nixosModules.kolide-launcher
            ]
            [
              ./nix/nixos/lunar_fwk/hardware-configuration.nix
              ./nix/nixos/lunar_fwk/configuration.nix
              ./nix/modules/moixa.nix
            ];
      };
    };
}
