self: super:

{
  metals = super.metals.overrideAttrs (
    { pname, ... }:
      let
        version = "0.9.7";
      in
        rec {
          inherit version;

          deps = super.stdenv.mkDerivation {
            name = "${pname}-deps-${version}";
            buildCommand = ''
              export COURSIER_CACHE=$(pwd)
              ${self.pkgs.coursier}/bin/coursier fetch org.scalameta:metals_2.12:${version} \
                -r bintray:scalacenter/releases \
                -r sonatype:snapshots > deps
              mkdir -p $out/share/java
              cp -n $(< deps) $out/share/java/
            '';
            outputHashMode = "recursive";
            outputHashAlgo = "sha256";
            outputHash = "0aky4vbbm5hi6jnd2n1aimqznbbaya05c7vdgaqhy3630ks3w4k9";
          };

          buildInputs = [ self.jdk deps ];
        }
  );
}
