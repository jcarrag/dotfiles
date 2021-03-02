self: super:

{
  nix-npm-install =
    with self; pkgs.writeScriptBin "nix-npm-install" ''
      #!/usr/bin/env bash
        tempdir="/tmp/nix-npm-install/$1"
        mkdir -p $tempdir
        pushd $tempdir
      # note the differences here:
        ${nodePackages.node2nix}/bin/node2nix --input <( echo "[\"$1\"]")
        nix-env --install --file .
        popd
    '';
}
