{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    configure = {
      customRC = builtins.readFile "${pkgs._self}/nix/modules/vimrc";
      packages.myPlugins.start = with pkgs.unstable.vimPlugins;
        let
          vim-github-link = pkgs.vimUtils.buildVimPluginFrom2Nix {
            pname = "github-link";
            version = "2022-05-16";
            src = pkgs.fetchFromGitHub {
              owner = "knsh14";
              repo = "vim-github-link";
              rev = "master";
              sha256 = "sha256-138OelnjN92Y4jXSJhvOV9TM7vYWGHjW9gXKRhwygYA=";
            };
            meta.homepage = "https://github.com/knsh14/vim-github-link";
          };
          vim-file-line = pkgs.vimUtils.buildVimPluginFrom2Nix {
            pname = "file-line";
            version = "2022-02-26";
            src = pkgs.fetchFromGitHub {
              owner = "bogado";
              repo = "file-line";
              rev = "master";
              sha256 = "sha256-r47H2vfQQM283YIMZFGjLfTxu6mHy1BN/VsiCcEbKPA=";
            };
            meta.homepage = "https://github.com/bogado/file-line/";
          };
          vim-material_kaicataldo = pkgs.vimUtils.buildVimPluginFrom2Nix {
            pname = "material.vim";
            version = "2022-02-26";
            src = pkgs.fetchFromGitHub {
              owner = "kaicataldo";
              repo = "material.vim";
              rev = "main";
              sha256 = "sha256-0QwN8tbCv27qxlGYVXnwhOJ9FA3KRDPrr6oFqaDJlNM=";
            };
            meta.homepage = "https://github.com/kaicataldo/material.vim/";
          };
        in
        [
          vim-abolish
          vim-commentary
          vim-sensible
          vim-fugitive
          vim-obsession
          vim-surround # Shortcuts for setting () {} etc.
          vim-visualstar
          direnv-vim
          coc-nvim
          coc-git
          coc-highlight
          coc-metals
          coc-python
          coc-rls
          coc-vimtex
          coc-yaml
          coc-html
          coc-json # auto completion
          coc-tsserver
          vim-nix # nix highlight
          fzf-vim # fuzzy finder through vim
          chadtree # file structure inside nvim
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
