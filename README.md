### System Installation
1. Run the NixOS installer to get `hardware-configuration.nix`
2. Clone this repository
3. Move `hardware-configuration.nix` to `./nix/nixos/$SYSTEM/hardware-configuration` (+ link in `./nix/nixos/flake.nix`)
4. (From `./nix/nixos`) Build the initial system using the updated flake, i.e.:
```
sudo nixos-rebuild build --flake .#$SYSTEM
```
5. (From `./nix/nixos`) link the system flake:
```
for ext in {nix,lock}; do sudo ln -s "$(realpath flake.$ext)" "/etc/nixos/flake.$ext"; done
```
6. The system will point to the appropriate system from then on:
```
sudo nixos-rebuild rebuild
```
7. Push the local changes upstream

### Pairing
1. Start tmate server:
```
// the config disables the default Esc delay
nix run nixpkgs#tmate -- -f <(echo set -s escape-time 0)

// or without 'nix-command' & 'flakes' as default
nix run --extra-experimental-features 'flakes nix-command' tmate -- -f <(echo set -s escape-time 0)
```
2. Start neovim:
```
nix run github:jcarrag/dotfiles#neovim

// or without 'nix-command' & 'flakes' as default
// `--refresh` force re-downloads the flake
nix run --extra-experimental-features 'flakes nix-command' run --refresh github:jcarrag/dotfiles#neovim
```
