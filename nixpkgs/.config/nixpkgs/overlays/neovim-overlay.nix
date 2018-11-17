self: super:

{
  neovim = super.neovim.override {
    extraPython3Packages = pkgs: with pkgs; [ websocket_client sexpdata ];
  };
}

