self: super:
let
  mkEmbyServer =
    {
      lib,
      stdenv,
      fetchurl,
      autoPatchelfHook,
      dpkg,
      makeWrapper,
      lttng-ust_2_12,
    }:

    let
      version = "4.9.0.42";
      name = "emby-${version}";
    in
    stdenv.mkDerivation {
      inherit name version;
      # "https://github.com/MediaBrowser/Emby.Releases/releases/download/4.8.0.37/emby-server-deb_4.8.0.37_amd64.deb";
      src = fetchurl {
        url = "https://github.com/MediaBrowser/Emby.Releases/releases/download/${version}/emby-server-deb_${version}_amd64.deb";
        sha256 = "sha256-dN4zgKwfAdvOjiii2wm6WepG2NwzRO/I3+fXciJJ4bE=";
      };

      preBuild = ''
        addAutoPatchelfSearchPath ${lib.makeLibraryPath [ lttng-ust_2_12 ]}
      '';

      nativeBuildInputs = [
        autoPatchelfHook
        dpkg
        makeWrapper
      ];

      unpackPhase = "true";

      # preFixup = ''
      #   wrapProgram $out/bin/emby-server --set EMBY_DATA ${EMBY_DATA}
      # '';

      installPhase = ''
        mkdir -p $out/bin
        dpkg -x $src .
        cp -r ./opt/emby-server/* $out/
        sed -i "s|APP_DIR=\/opt\/emby-server|APP_DIR=$out|g" $out/bin/*
      '';

      meta = with lib; {
        description = "Self-hosted web application that allows users the ability to stream content";
        homepage = "https://emby.media/";
        sourceProvenance = with sourceTypes; [ binaryNativeCode ];
        license = licenses.gpl3Only;
        maintainers = with maintainers; [ jcarrag ];
        platforms = [ "x86_64-linux" ];
      };
    };
in
{
  emby-server = self.callPackage mkEmbyServer { };
}
