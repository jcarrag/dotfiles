The `flake.nix` files in each of the system folders share a symlinked parent `flake.lock` file.

Link the appropriate `flake.nix` & `flake.lock` into `/etc/nixos/flake.*`.

You can build each system with:
```
nixos-rebuild build --flake github:jcarrag/dotfiles?dir=nix/flakes/nixos/xps13
```
