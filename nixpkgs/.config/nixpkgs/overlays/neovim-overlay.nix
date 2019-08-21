self: super:

{
  my-neovim = super.neovim.override {
    extraPython3Packages = pkgs: with pkgs; [ websocket_client sexpdata ];
  };
}

