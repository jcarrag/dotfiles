### System Installation
Build the initial system using the github hosted flake, i.e.:
```
sudo nixos-rebuild build --flake github:jcarrag/dotfiles#xps
```
After cloning this repo, link the system flake:
```
cd /etc/nixos
for ext in {nix,lock}; do echo ln -s "$(realpath flake.$ext)" "flake.$ext"; done
```
The system will point to the appropriate system from then on:
```
sudo nixos-rebuild build
```

### Pairing
1. Start tmate server:
```
// the config disables the default Esc delay
tmate -f <(echo set -s escape-time 0)

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
