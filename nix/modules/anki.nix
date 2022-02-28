{ lib, pkgs, config, ... }:

with lib; with lib.types;
let
  cfg = config.programs.anki;

  addonConfigFormat = pkgs.formats.json {};
in
{
  options.programs.anki = {
    enable = mkEnableOption "Enable Anki service";

    addons = mkOption {
      description = "Addons for Anki";
      default = [];
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
              default = [];
              type = listOf path;
            };
            buildInputs = mkOption {
              description = "Runtime dependencies for the addon";
              default = [];
              type = listOf package;
            };
            addonConfig = mkOption {
              type = addonConfigFormat.type;
              default = {};
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
      addonById = (foldr (a: acc: acc // { ${a.ankiWebId} = a; }) {} cfg.addons);
      buildInputs = concatMap (addon: addon.buildInputs) cfg.addons;

      addons = pkgs.stdenv.mkDerivation {
        pname = "AnkiWebAddons";

        version = "2.1";

        srcs = map (
          { ankiWebId, sha256, ... }:
            pkgs.fetchurl {
              name = "${ankiWebId}.zip";
              url = "https://ankiweb.net/shared/download/${ankiWebId}?v=2.1";
              sha256 = sha256;
            }
        ) cfg.addons;

        nativeBuildInputs = [ pkgs.unzip ];

        dontConfigure = true;

        unpackPhase = ''
          for _src in $srcs; do
            unzip "$_src" -d "./$(basename $_src .zip | sed -e 's/^.*-//')"
          done
        '';

        patchPhase = concatMap (
          id:
            map (
              patches: ''
                cd ${id}
                patch < "${patches}"
                cd ..
              ''
            ) addonById.${id}.patches
        ) ids;

        installPhase = map (
          id:
            ''
              cd ${id}
              cat <<EOF > meta.json
              {"name":"${id}", "mod": 0, "config": ${builtins.toJSON addonById.${id}.addonConfig}}
              EOF
              cd ..
            ''
        ) ids ++ [
          ''
            mkdir $out/

            cp -r * $out/
          ''
        ];
      };

      ankiPatch = pkgs.writeTextFile {
        name = "anki_addon_dir.patch";
        text = ''
          diff --git a/aqt/profiles.py b/aqt/profiles.py
          index f12b31138..c31dfa47c 100644
          --- a/aqt/profiles.py
          +++ b/aqt/profiles.py
          @@ -258,7 +258,7 @@ and no other programs are accessing your profile folders, then try again."""))
                   return path
           
               def addonFolder(self):
          -        return self._ensureExists(os.path.join(self.base, "addons21"))
          +        return "${addons}"
           
               def backupFolder(self):
                   return self._ensureExists(
        '';
      };

      anki = pkgs.anki.overrideAttrs (
        old: {
          patches = old.patches ++ [ ankiPatch ];

          preFixup = old.preFixup + ''
            makeWrapperArgs+=(
              --prefix PATH ':' ${makeBinPath buildInputs}
            )
          '';
        }
      );
    in
      {
        environment.systemPackages = [
          anki
        ];
      }
  );
}
