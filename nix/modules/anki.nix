{ lib, pkgs, config, ... }:

with lib; with lib.types;
let
  cfg = config.programs.anki;

  addonConfigFormat = pkgs.formats.json { };
in
{
  options.programs.anki = {
    enable = mkEnableOption "Enable Anki service";

    addons = mkOption {
      description = "Addons for Anki";
      default = [ ];
      type = listOf (
        submodule {
          options = {
            ankiWebId = mkOption {
              description = "The id of the addon in AnkiWeb";
              type = str;
            };
            sha256 = mkOption {
              description = "The sha256 of the addon";
              type = str;
            };
            patches = mkOption {
              description = "Patches to be applied";
              default = [ ];
              type = listOf path;
            };
            addonConfig = mkOption {
              type = addonConfigFormat.type;
              default = { };
              description = "Addon configuration";
            };
          };
        }
      );
    };
  };

  config = mkIf cfg.enable (
    let
      ids = map (addon: addon.ankiWebId) cfg.addons;
      addonById = (foldr (a: acc: acc // { ${a.ankiWebId} = a; }) { } cfg.addons);

      addons = pkgs.stdenv.mkDerivation {
        pname = "AnkiWebAddons";

        version = "2.1";

        srcs = map
          (
            { ankiWebId, sha256, ... }:
            pkgs.fetchurl {
              name = "${ankiWebId}.zip";
              url = "https://ankiweb.net/shared/download/${ankiWebId}?v=2.1";
              sha256 = sha256;
            }
          )
          cfg.addons;

        nativeBuildInputs = [ pkgs.unzip ];

        dontConfigure = true;

        unpackPhase = ''
          for _src in $srcs; do
            unzip "$_src" -d "./$(basename $_src .zip | sed -e 's/^.*-//')"
          done
        '';

        patchPhase = concatMap
          (
            id:
            map
              (
                patches: ''
                  cd ${id}
                  patch < "${patches}"
                  cd ..
                ''
              )
              addonById.${id}.patches
          )
          ids;

        installPhase = map
          (
            id:
            ''
              cd ${id}
              cat <<EOF > meta.json
              {"name":"${id}", "mod": 0, "config": ${builtins.toJSON addonById.${id}.addonConfig}}
              EOF
              cd ..
            ''
          )
          ids ++ [
          ''
            mkdir $out/

            cp -r * $out/
          ''
        ];
      };

      anki-bin = pkgs.callPackage ./anki-bin.nix { };

      anki = pkgs.writeShellScriptBin "anki" ''
        cp -r ${addons}/* /home/james/.local/share/Anki2/addons21/

        chmod -R +w /home/james/.local/share/Anki2/addons21/

        ${anki-bin}/bin/anki
      '';
    in
    {
      environment.systemPackages = [
        anki
      ];
    }
  );
}
