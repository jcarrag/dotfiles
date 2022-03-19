### System Installation
1. Run the NixOS installer to get `hardware-configuration.nix`
2. Clone this repository
3. Move `hardware-configuration.nix` to `./nix/nixos/$SYSTEM/hardware-configuration` (+ link in `./nix/nixos/flake.nix`)
4. (From `./nix/nixos`) Build the initial system using the updated flake, i.e.:
```
sudo nixos-rebuild switch --flake .#$SYSTEM
```
5. (From `./nix/nixos`) link the system flake:
```
for ext in {nix,lock}; do sudo ln -s "$(realpath flake.$ext)" "/etc/nixos/flake.$ext"; done
```
6. The system will point to the appropriate system from then on:
```
sudo nixos-rebuild switch
```
7. Push the local changes upstream

### Pairing
1. (From host) Start tmate server:
```
nix run github:jcarrag/dotfiles#tmate

// or without 'nix-command' & 'flakes' as default
nix run --extra-experimental-features 'nix-command flakes' github:jcarrag/dotfiles#tmate
```
2. (From host) Enter tmate session password
3. (From client) Connect to tmate server:
```
tmate_connect
```
