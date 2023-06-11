{
  description = "A flake for my systems";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";

  inputs.unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  inputs.parsec.url = "github:DarthPJB/parsec-gaming-nix";

  outputs = { self, nixpkgs, unstable, flake-utils, parsec }:
    let
      packageOverlays = import ../overlays;

      mkNixos = hostname: system: modules:
        let
          extrasOverlay = _: _: {
            unstable = import unstable {
              system = system;
              config.allowUnfree = true;
              nixpkgs.overlays = [ packageOverlays ];
            };
            _self = self;
          };
          rebuild = (import nixpkgs { system = system; }).writeShellScriptBin "rebuild" ''
            set -x
            sudo nixos-rebuild switch --flake ~/dotfiles/#${hostname} "$@"
          '';
        in
        nixpkgs.lib.nixosSystem {
          system = system;
          modules =
            [
              (import ./base-configuration.nix)
              {
                environment.systemPackages = [
                  (parsec.packages.${system}.parsecgaming.overrideAttrs (old:
                    let
                      pkgs = import nixpkgs { inherit system; overlays = [ packageOverlays ]; };
                    in
                    rec {
                      parsecd_so = pkgs.runCommand "parsecd_so" { } ''
                        cat ${old.latest_appdata} | ${pkgs.jq}/bin/jq --raw-output .so_name | tee $out
                      '';

                      latest_parsecd_so = pkgs.fetchurl {
                        url = "https://builds.parsecgaming.com/channel/release/binary/linux/gz/${builtins.readFile parsecd_so}";
                        sha256 = "sha256-GNyn+jaxSVM5noUxyTAdSK2DriwbtQeG3Qyg25760nU=";
                      };

                      postPatch = ''
                        cp $latest_appdata usr/share/parsec/skel/appdata.json
                        cp $latest_parsecd_so usr/share/parsec/skel/${builtins.readFile parsecd_so}
                      '';
                    }))
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
      };
    };
}
