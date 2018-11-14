self: super:

{
  neovim = super.neovim.override {
    extraPython3Packages = with self.python3Packages; [ websocket_client sexpdata ];
  };
}

