{
  description = "A flake for my systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    xremap.url = "github:xremap/nix-flake";
    # ynab-updater.url = "git+file:///home/james/dev/my/ynab_updater";
    ynab-updater.url = "github:jcarrag/ynab-updater";
    kolide-launcher = {
      url = "github:/kolide/nix-agent/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://jcarrag.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "jcarrag.cachix.org-1:FA5BLvAZdzLaJztyyou115tAQjT1cQsiAG03dm0AdvI="
    ];
  };

  outputs =
    inputs@{ self
    , nixpkgs
    , unstable
    , flake-utils
    , ...
    }:
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
              inputs.xremap.nixosModules.default
              inputs.ynab-updater.nixosModules.ynab-updater
              inputs.kolide-launcher.nixosModules.kolide-launcher
              (import ./nix/nixos/base-configuration.nix)
              {
                environment.systemPackages = [
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
    inputs.flake-utils.lib.eachDefaultSystem
      (system:
      {
        packages = inputs.flake-utils.lib.flattenTree {
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
