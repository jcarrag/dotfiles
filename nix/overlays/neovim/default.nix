{ pkgs
, lib
, ...
}:
let
  fromGitHub = rev: ref: repo:
    pkgs.vimUtils.buildVimPlugin {
      pname = "${lib.strings.sanitizeDerivationName repo}";
      version = ref;
      src = builtins.fetchGit {
        url = "https://github.com/${repo}.git";
        ref = ref;
        rev = rev;
      };
    };
in
{
  programs = {
    neovim = {
      # TODO: copy https://github.com/zmre/pwnvim/blob/main/pwnvim/plugins.lua
      configure =
        let
          homeManagerPlugins = [
            ## Theme
            {
              plugin = pkgs.vimPlugins.lualine-nvim;
              config = /* lua */ ''
                require('lualine').setup {
                    options = {
                        theme = 'auto',
                    }
                }
              '';
              type = "lua";
            }
            {
              plugin = pkgs.vimPlugins.material-nvim;
              config = /* lua */''
                vim.g.material_style = "deep ocean"
                require("material").setup {}
                vim.cmd 'colorscheme material'
              '';
              type = "lua";
            }
            {
              # plugin = fromGitHub "d98e732cb73690b07c00c839c924be1d1d9ac5c2" "main" "MunifTanjim/prettier.nvim";
              plugin = pkgs.vimPlugins.formatter-nvim;
              config = /* lua */''
                require("formatter").setup {
                  filetype = {
                    javascript = {
                      require("formatter.filetypes.javascript").prettier,
                    },
                    typescript = {
                      require("formatter.filetypes.typescript").prettier,
                    }
                  }
                }
              vim.keymap.set('n', '<leader>p', '<cmd>Format<cr>')
              '';
              type = "lua";
            }
            {
              plugin = pkgs.vimPlugins.obsidian-nvim;
              config = /* lua */''
                require("obsidian").setup {
                  workspaces = {
                    {
                      name = "obsidian",
                      path = "~/obsidian",
                    },
                  },
                }
              vim.opt.conceallevel = 1
              '';
              type = "lua";
            }
            {
              plugin = pkgs.vimPlugins.auto-session;
              config = /* lua */''
                require("auto-session").setup {
                  suppressed_dirs = { "~/", "~/tmp", "~/Downloads", "/"},
                }
              '';
              type = "lua";
            }

            ## Treesitter
            {
              plugin = pkgs.vimPlugins.nvim-treesitter;
              config = builtins.readFile config/setup/treesitter.lua;
              type = "lua";
            }
            pkgs.vimPlugins.nvim-treesitter.withAllGrammars
            pkgs.vimPlugins.nvim-treesitter-textobjects
            {
              plugin = pkgs.vimPlugins.nvim-lspconfig;
              config = builtins.readFile config/setup/lspconfig.lua;
              type = "lua";
            }

            pkgs.vimPlugins.plenary-nvim

            ## Telescope
            {
              plugin = pkgs.vimPlugins.telescope-nvim;
              config = builtins.readFile config/setup/telescope.lua;
              type = "lua";
            }
            # pkgs.vimPlugins.telescope-fzf-native-nvim
            {
              plugin = pkgs.vimPlugins.fzf-lua;
              config = /* lua */''
                require("fzf-lua").setup({
                  defaults = {
                    winopts = {
                      preview = {
                        hidden = 'hidden',
                      },
                    },
                  },
                  keymap = {
                    builtin = {
                      ['?'] = 'toggle-preview',
                    },
                    fzf = {
                      ['?'] = 'toggle-preview',
                    },
                  },
                })
                require("fzf-lua").register_ui_select()
              '';
              type = "lua";
            }
            {
              plugin = pkgs.vimPlugins.project-nvim;
              config = /* lua */ ''
                require("project_nvim").setup {
                  detection_methods = { "pattern" },
                  patterns = { ".git" },
                }
              '';
              type = "lua";
            }
            pkgs.vimPlugins.harpoon
            {
              plugin = pkgs.vimPlugins.typescript-tools-nvim;
              config = /* lua */ ''
                require("typescript-tools").setup {
                  settings = {
                    expose_as_code_action = "all",
                    tsserver_max_memory = 30000
                  }
                }
              vim.keymap.set('n', ':OR', '<cmd>TSToolsOrganizeImports<cr>')
              '';
              type = "lua";
            }
            ## cmp
            {
              plugin = pkgs.vimPlugins.nvim-cmp;
              config = builtins.readFile config/setup/cmp.lua;
              type = "lua";
            }
            pkgs.vimPlugins.cmp-nvim-lsp
            pkgs.vimPlugins.cmp-buffer
            pkgs.vimPlugins.cmp-cmdline
            pkgs.vimPlugins.cmp_luasnip

            ## Tpope
            pkgs.vimPlugins.vim-abolish
            pkgs.vimPlugins.vim-surround
            pkgs.vimPlugins.vim-sleuth
            pkgs.vimPlugins.vim-repeat
            {
              plugin = fromGitHub "afd76df166ed0f223ede1071e0cfde8075cc4a24" "main" "TabbyML/vim-tabby";
              config = /* lua */''
                vim.cmd([[
                  let g:tabby_keybinding_accept = '<Tab>'
                ]])
              '';
              type = "lua";
            }

            ## QoL
            pkgs.vimPlugins.lspkind-nvim
            pkgs.vimPlugins.rainbow
            pkgs.vimPlugins.nvim-web-devicons
            pkgs.vimPlugins.nui-nvim
            pkgs.vimPlugins.surround-nvim
            pkgs.vimPlugins.nvim-code-action-menu
            pkgs.vimPlugins.vim-multiple-cursors
            pkgs.vimPlugins.csv-vim
            pkgs.vimPlugins.nvim-autopairs
            pkgs.vimPlugins.direnv-vim
            pkgs.vimPlugins.file-line
            (fromGitHub "0612c180d699c5d298e5181befa1830980e8e083" "master" "knsh14/vim-github-link")
            (fromGitHub "0273f88f7199189f9a0f32213a34ab778e226f86" "main" "grafana/vim-alloy")
            # {
            #   plugin = pkgs.vimPlugins.neorg;
            #   config = builtins.readFile config/setup/neorg.lua;
            #   type = "lua";
            # }
            # {
            #   # Updated 07/06/24
            #   plugin = fromGitHub "30fe1b3de2b7614f061be4fc9c71984a2b87e50a" "main" "m-demare/hlargs.nvim";
            #   config = "require('hlargs').setup()";
            #   type = "lua";
            # }
            # {
            #   # Updated 07/06/24
            #   plugin = fromGitHub "a0ae099c7eb926150ee0a126b1dd78086edbe3fc" "main" "apple/pkl-neovim";
            # }
            # {
            #   # Updated 07/06/24
            #   plugin = fromGitHub "c6bd6d93e4724ac2dc0cae73ebe1d568bf406537" "main" "epwalsh/obsidian.nvim";
            #   config = /*lua*/ ''
            #     require("obsidian").setup({
            #       workspaces = {
            #         {
            #           name = "notes",
            #           path = "~/dev/notes",
            #         },
            #       },
            #     })
            #   '';
            #   type = "lua";
            # }
            # (fromGitHub "8843b72822151bb7792f3fdad4b63df0bc1dd4a6" "main" "MattCairns/telescope-cargo-workspace.nvim")
            {
              plugin = pkgs.vimPlugins.oil-nvim;
              config = /* lua */"require('oil').setup()";
              type = "lua";
            }
            {
              plugin = pkgs.vimPlugins.neo-tree-nvim;
              config = /* lua */''
                require('neo-tree').setup {
                  filesystem = {
                    window = {
                      mappings = {
                        ["u"] = "navigate_up",
                        ["O"] = "expand_all_nodes",
                      }
                    },
                    filtered_items = {
                      visible = true,
                      show_hidden_count = true,
                      hide_dotfiles = false,
                      hide_gitignored = false,
                    },
                    follow_current_file = {
                      enabled = true,
                      leave_dirs_open = false,
                    },
                  },
                  buffers = { follow_current_file = { enable = true } },
                }

                -- auto close https://github.com/gomfol12/dotfiles/blob/47efefe2bfe3f800b0f94b5036e83a79e85fac4c/.config/nvim/lua/tree.lua#L103C3-L124
                local function is_modified_buffer_open(buffers)
                    for _, v in pairs(buffers) do
                        if v.name:match("neo%-tree") == nil then
                            return true
                        end
                    end
                    return false
                end
                local function non_floating_wins_count()
                    local i = 0
                    for _, v in pairs(vim.api.nvim_list_wins()) do
                        if vim.api.nvim_win_get_config(v).relative == "" then
                          i = i + 1
                        end
                    end
                    return i
                end
                vim.api.nvim_create_autocmd("BufEnter", {
                    nested = true,
                    callback = function()
                        if
                            non_floating_wins_count() == 1
                            and vim.api.nvim_buf_get_name(0):match("neo%-tree") ~= nil
                        then
                            vim.cmd("quit")
                        end
                    end,
                })
              '';
              type = "lua";
            }
            {
              plugin = pkgs.vimPlugins.fidget-nvim;
              config = /* lua */ "require('fidget').setup{}";
              type = "lua";
            }
            {
              plugin = pkgs.vimPlugins.trouble-nvim;
              config = /* lua */"require('trouble').setup {}";
              type = "lua";
            }
            {
              plugin = pkgs.vimPlugins.luasnip;
              config = builtins.readFile config/setup/luasnip.lua;
              type = "lua";
            }
            {
              plugin = pkgs.vimPlugins.comment-nvim;
              config = /* lua */"require('Comment').setup()";
              type = "lua";
            }
            {
              plugin = pkgs.vimPlugins.gitsigns-nvim;
              config = /* lua */''
                require('gitsigns').setup{
                  on_attach = function(bufnr)
                    local gitsigns = require('gitsigns')

                    local function map(mode, l, r, opts)
                      opts = opts or {}
                      opts.buffer = bufnr
                      vim.keymap.set(mode, l, r, opts)
                    end

                    map('n', ']g', function()
                      if vim.wo.diff then
                        vim.cmd.normal({']c', bang = true})
                      else
                        gitsigns.nav_hunk('next')
                      end
                    end)

                    map('n', '[g', function()
                      if vim.wo.diff then
                        vim.cmd.normal({'[c', bang = true})
                      else
                        gitsigns.nav_hunk('prev')
                      end
                    end)
                  end
                }
              '';
              type = "lua";
            }
            # {
            #   plugin = pkgs.vimPlugins.noice-nvim;
            #   config = /*lua*/ ''
            #     require("noice").setup({
            #       lsp = {
            #         -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
            #         override = {
            #           ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            #           ["vim.lsp.util.stylize_markdown"] = true,
            #           ["cmp.entry.get_documentation"] = true,
            #         },
            #       },
            #       -- you can enable a preset for easier configuration
            #       presets = {
            #         bottom_search = true, -- use a classic bottom cmdline for search
            #         command_palette = true, -- position the cmdline and popupmenu together
            #         long_message_to_split = true, -- long messages will be sent to a split
            #         inc_rename = false, -- enables an input dialog for inc-rename.nvim
            #         lsp_doc_border = false, -- add a border to hover docs and signature help
            #       },
            #     })
            #   '';
            #   type = "lua";
            # }

            ## Debugging
            pkgs.vimPlugins.nvim-dap-ui
            pkgs.vimPlugins.nvim-dap-virtual-text
            {
              plugin = pkgs.vimPlugins.nvim-dap;
              config = builtins.readFile config/setup/dap.lua;
              type = "lua";
            }
            {
              plugin = pkgs.vimPlugins.rustaceanvim;
              config = /*lua*/ ''
                vim.g.rustaceanvim = {
                  -- Plugin configuration
                  tools = {
                  },
                  -- LSP configuration
                  server = {
                    on_attach = function(client, bufnr)
                      -- you can also put keymaps in here
                    end,
                    settings = {
                      -- rust-analyzer language server configuration
                      ['rust-analyzer'] = {
                       cargo = {
                          allFeatures = true,
                          loadOutDirsFromCheck = true,
                          runBuildScripts = true,
                        },
                        checkOnSave = {
                          allFeatures = true,
                          command = "clippy",
                          extraArgs = { "--no-deps" },
                        },
                        procMacro = {
                          enable = true,
                          ignored = {
                            ["async-trait"] = { "async_trait" },
                            ["napi-derive"] = { "napi" },
                            ["async-recursion"] = { "async_recursion" },
                          },
                        },
                      },
                    },
                  },
                  -- DAP configuration
                  dap = {
                  },
                }
              '';
              type = "lua";
            }
          ];
          luaConfig = lib.pipe homeManagerPlugins [
            (lib.lists.concatMap (p: if (p ? type && p.type == "lua") then [ p.config ] else [ ]))
            lib.strings.concatLines
            # lib.debug.traceVal
          ];
          plugins = lib.lists.map (p: if (p ? plugin) then p.plugin else p) homeManagerPlugins;
        in
        {
          customRC = ''
            lua << EOF
            package.path = "${pkgs._self}/nix/overlays/neovim/?.lua;" .. package.path
          ''
          + pkgs.lib.readFile ./config/options.lua
          + pkgs.lib.readFile ./config/mappings.lua
          + luaConfig
          + ''
            EOF
          '';
          packages.myPlugins.start = plugins;
        };
      enable = true;
    };
  };
}
