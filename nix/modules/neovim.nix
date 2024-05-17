{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    configure = {
      customRC = builtins.readFile "${pkgs._self}/nix/modules/vimrc";
      packages.myPlugins.start = with pkgs.unstable.vimPlugins;
        let
          vim-alloy = pkgs.vimUtils.buildVimPlugin {
            pname = "vim-alloy";
            version = "2024-05-11";
            src = pkgs.fetchFromGitHub {
              owner = "grafana";
              repo = "vim-alloy";
              rev = "main";
              sha256 = "sha256-lUOVfbdmEBuuIyxTFkWy7R3Sem6DnC6pjmu8XJWJYM8=";
            };
            meta.homepage = "https://github.com/grafana/vim-alloy";
          };
          vim-github-link = pkgs.vimUtils.buildVimPlugin {
            pname = "github-link";
            version = "2022-12-22";
            src = pkgs.fetchFromGitHub {
              owner = "knsh14";
              repo = "vim-github-link";
              rev = "master";
              sha256 = "sha256-C0XU351KCm/Og0I7jl5PH+yOydOJ91WdPTcA6068GgI=";
            };
            meta.homepage = "https://github.com/knsh14/vim-github-link";
          };
          vim-file-line = pkgs.vimUtils.buildVimPlugin {
            pname = "file-line";
            version = "2022-12-22";
            src = pkgs.fetchFromGitHub {
              owner = "bogado";
              repo = "file-line";
              rev = "master";
              sha256 = "sha256-r47H2vfQQM283YIMZFGjLfTxu6mHy1BN/VsiCcEbKPA=";
            };
            meta.homepage = "https://github.com/bogado/file-line/";
          };
          vim-material_kaicataldo = pkgs.vimUtils.buildVimPlugin {
            pname = "material.vim";
            version = "2022-12-22";
            src = pkgs.fetchFromGitHub {
              owner = "kaicataldo";
              repo = "material.vim";
              rev = "main";
              sha256 = "sha256-yBMa/zwNS6h+d08oBQskiExgmN69lZkBuwAWCEHkQ8g=";
            };
            meta.homepage = "https://github.com/kaicataldo/material.vim/";
          };
        in
        [
          vim-abolish
          vim-alloy
          vim-commentary
          vim-devicons
          vim-sensible
          vim-fugitive
          vim-obsession
          vim-surround # Shortcuts for setting () {} etc.
          vim-visualstar
          direnv-vim
          nvim-autopairs
          sort-nvim
          coc-nvim
          coc-git
          coc-highlight
          coc-metals
          coc-python
          coc-rust-analyzer
          coc-snippets
          coc-vimtex
          coc-yaml
          coc-html
          coc-json # auto completion
          coc-tsserver
          coc-eslint
          coc-prettier
          vim-nix # nix highlight
          fzf-vim # fuzzy finder through vim
          nerdtree # file structure inside nvim
          rainbow # Color parenthesis
          vim-airline
          vim-airline-themes
          csv-vim
          vim-multiple-cursors
          vim-devicons
          vim-github-link
          vim-file-line
          vim-material_kaicataldo
          vim-css-color
        ];
    };
  };
}
