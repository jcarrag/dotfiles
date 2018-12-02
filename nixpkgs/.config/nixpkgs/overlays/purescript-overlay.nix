self: super:

with super; with stdenv; with lib; {

  myPurescript = mkDerivation rec {
    name = "purescript-binary-${version}";
    version = "0.12.0";
    platform = {
      "x86_64-linux" = "linux64";
    }.${hostPlatform.system};
    src = fetchurl {
      url = 
        "https://github.com/"
        + "purescript/purescript/releases/download/"
        + "v${version}/${platform}.tar.gz";
      sha256 = {
        "x86_64-linux" = "1wf7n5y8qsa0s2p0nb5q81ck6ajfyp9ijr72bf6j6bhc6pcpgmyc";
      }.${hostPlatform.system};
      name = "purescript.tar.gz";
    };
  
    buildInputs = [ makeWrapper ];
    unpackCmd = "tar -xzf $curSrc";
  
    installPhase = ''
      mkdir -p $out/bin $out/lib
      cp purs $out/bin/
  
      runHook postInstall
    '';
  
    postInstall = let
      libs = makeLibraryPath [ cc.cc gmpxx ncurses5 zlib ];
    in ''
      interpreter="$(cat $NIX_CC/nix-support/dynamic-linker)"
      ${patchelf}/bin/patchelf \
        --set-interpreter $interpreter \
        $out/bin/purs
  
      wrapProgram $out/bin/purs \
        --prefix LD_LIBRARY_PATH : ${libs}
    '';
  
    meta = {
      description = "A small strongly typed programming language with expressive
      types that compiles to JavaScript, written in and inspired by Haskell.";
      homepage = http://www.purescript.org/;
      license = licenses.bsd3;
      platforms = [ "x86_64-linux" ];
    };
  };
}
