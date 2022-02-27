The `flake.nix` files in each of the system folders share a symlinked parent `flake.lock` file.

Link the appropriate `flake.nix` & `flake.lock` into `/etc/nixos/flake.*`.

You can build each system with:
```
nixos-rebuild build --flake github:jcarrag/dotfiles?dir=nix/flakes/nixos/xps13
```

### Pairing
1. Install [tmate](http://tmate.io) on client
2. Start tmate server:
```
// the config disables the default Esc delay
tmate -f <(echo set -s escape-time 0)

// or on OSX
nix run --extra-experimental-features 'flakes nix-command' tmate -- -f <(echo set -s escape-time 0)
```
3. Start neovim:
```
nix run github:jcarrag/dotfiles#neovim

// or on OSX
nix run --extra-experimental-features 'flakes nix-command' run --refresh github:jcarrag/dotfiles#neovim
```
