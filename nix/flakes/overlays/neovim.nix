self: super:

{
  my-neovim = with self (pkgs);
    let
      vimrc = import ./vimrc_empty;
    in
    pkgs.wrapNeovim pkgs.neovim-unwrapped {
      # inherit (cfg) viAlias vimAlias withPython3 withNodeJs withRuby;
      vimAlias = true;
      withPython3 = true;
      withNodeJs = true;
      withRuby = true;

      configure = cfg.configure // {

        customRC = vimrc;
      };
    };
}
