{ fetchurl, stdenv, lib, buildFHSUserEnv, appimageTools, writeShellScript, anki, undmg, zstd }:

let
  pname = "anki-bin";
  # Update hashes for both Linux and Darwin!
  version = "2.1.50";

  sources = {
    linux = fetchurl {
      url = "https://github.com/ankitects/anki/releases/download/${version}/anki-${version}-linux-qt5.tar.zst";
      sha256 = "sha256-whhIrJ/9A1L+ojTB89SMY8VUSJjhpMKzL3sw3Sj1Ba4=";
    };
    darwin = fetchurl {
      url = "https://github.com/ankitects/anki/releases/download/${version}/anki-${version}-mac.dmg";
      sha256 = "sha256-sEVWZQpICL7RYrOuPm1Y5XhzPxCwNk1WGP1rctTtE4Y=";
    };
  };

  unpacked = stdenv.mkDerivation {
    inherit pname version;

    nativeBuildInputs = [ zstd ];

    src = sources.linux;
    phases = [ "unpackPhase" "installPhase" ];

    unpackPhase = ''
      runHook preUnpack

      tar --use-compress-program=unzstd -xvf $src --strip-components 1 --directory .

      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      xdg-mime () {
        echo Stubbed!
      }
      export -f xdg-mime

      PREFIX=$out bash install.sh

      runHook postInstall
    '';
  };

  meta = with lib; {
    inherit (anki.meta) license homepage description longDescription;
    platforms = [ "x86_64-linux" "x86_64-darwin" ];
    maintainers = with maintainers; [ atemu ];
  };

  passthru = { inherit sources; };
in

if stdenv.isLinux then
  buildFHSUserEnv
    (appimageTools.defaultFhsEnvArgs // {
      name = "anki";

      runScript = writeShellScript "anki-wrapper.sh" ''
        exec ${unpacked}/bin/anki
      '';

      extraInstallCommands = ''
        mkdir -p $out/share
        cp -R ${unpacked}/share/applications \
          ${unpacked}/share/man \
          ${unpacked}/share/pixmaps \
          $out/share/
      '';

      inherit meta passthru;
    }) else
  stdenv.mkDerivation {
    inherit pname version passthru;

    src = sources.darwin;

    nativeBuildInputs = [ undmg ];
    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/Applications/
      cp -a Anki.app $out/Applications/
    '';

    inherit meta;
  }
