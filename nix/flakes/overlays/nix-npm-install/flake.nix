{
  outputs = { self }: {
    overlays = final: prev: {
      nix-npm-install =
        with final; pkgs.writeScriptBin "nix-npm-install" ''
        #!/usr/bin/env bash
          tempdir="/tmp/nix-npm-install/$1"
          mkdir -p $tempdir
          pushd $tempdir
        # note the differences here:
          ${nodePackages.node2nix}/bin/node2nix --input <( echo "[\"$1\"]") --nodejs-10
          nix-env --install --file .
          popd
        '';

        allToMp3 = with final; stdenv.mkDerivation {
          version = "0.3.18";
          pname = "allToMp3";
          src = fetchFromGithub {
            owner = "AllToMP3";
            repo = "alltomp3-app";
            rev = "047fd4be848a11948c44ede145112475a9614308";
            sha256 = "1m9xh24p3dz7krv65w06n4iy856c9c2klwb5ma1nqfqhd9czc3sb";
          };

          nativeBuildInputs = [
            npm nodePackages."@angular/cli@1.0.0" ffmpeg nodePackages.fpcalc python
          ];
        };

        ferdi-my = with final; stdenv.mkDerivation rec {
          version = "5.5.1-nightly.15";
          pname = "ferdi";
          src = fetchurl {
            url = "https://github.com/getferdi/nightlies/releases/download/v${version}/ferdi_${version}_amd64.deb";
            sha256 = "1m9xh24p3dz7krv65w06n4iy856c9c2klwb5ma1nqfqhd9czc3sb";
          };

          nativeBuildInputs = [
            autoPatchelfHook makeWrapper wrapGAppsHook dpkg
            nodePackages.asar
          ];

          buildInputs = [
            gtk3
            xlibs.libXScrnSaver
            xlibs.libXtst
            xlibs.libxkbfile
            alsaLib
            nss
          ];

          runtimeDependencies = [
            systemd.lib
            libnotify
            pulseaudio
          ];

          unpackPhase = "dpkg-deb -x $src .";

          installPhase = ''
            mkdir -p $out/bin
            cp -r opt $out
            ln -s $out/opt/Ferdi/ferdi $out/bin
            asar extract $out/opt/Ferdi/resources/app.asar resources
            autoPatchelf resources
            asar pack resources $out/opt/Ferdi/resources/app.asar
    # provide desktop item and icon
            cp -r usr/share $out
            substituteInPlace $out/share/applications/ferdi.desktop \
            --replace Exec=\"/opt/Ferdi/ferdi\" Exec=ferdi
          '';

          dontWrapGApps = true;

          postFixup = ''
    # ferdi without an account requires libstdc++ at runtime
            wrapProgram $out/opt/Ferdi/ferdi \
            --prefix PATH : ${xdg_utils}/bin \
            "''${gappsWrapperArgs[@]}"
          '';

          meta = with stdenv.lib; {
            description = "A free messaging app that combines chat & messaging services into one application";
            homepage = "https://getferdi.com";
            license = licenses.free;
            maintainers = [ maintainers.mic92 ];
            platforms = [ "x86_64-linux" ];
            hydraPlatforms = [ ];
          };
        };
      };
    };
  }
