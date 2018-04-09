self: super:

{
  neovim = super.neovim.override {
    extraPythonPackages = with self.pythonPackages; [ websocket_client sexpdata neovim ];
  };
}
