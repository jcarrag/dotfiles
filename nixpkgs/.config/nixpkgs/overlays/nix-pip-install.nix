self: super:

{
  nix-pip-install = with self; pkgs.writeScriptBin "nix-pip-install" ''
      #!/usr/bin/env bash
      tempdir="/tmp/nix-pip-install/$1"
      mkdir -p $tempdir
      pushd $tempdir
      # note the differences here:
      ${super.pypi2nix}/bin/pypi2nix -e $1 -V 3 ''${@:2}
      nix-env --install --file .
      popd
    ''; 
}
