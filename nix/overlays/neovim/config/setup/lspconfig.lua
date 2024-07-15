local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
require 'lspconfig'.clangd.setup { capabilities = capabilities }
-- require'lspconfig'.rust_analyzer.setup{capabilities=capabilities} -- This is setup by rust-tools
require 'lspconfig'.cmake.setup { capabilities = capabilities }
require 'lspconfig'.dockerls.setup { capabilities = capabilities }
require('lspconfig').nil_ls.setup {
  autostart = true,
  capabilities = capabilities,
  settings = {
    ['nil'] = {
      testSetting = 42,
      formatting = {
        command = { "nixpkgs-fmt" },
      },
    },
  },
}
require("lspconfig").dockerls.setup {
  settings = {
    docker = {
      languageserver = {
        formatter = {
          ignoreMultilineInstructions = true,
        },
      },
    }
  }
}
require 'lspconfig'.jsonls.setup {
  capabilities = capabilities,
}
require 'lspconfig'.bufls.setup { capabilities = capabilities }
require 'lspconfig'.ansiblels.setup {}
require 'lspconfig'.tsserver.setup {}
require 'lspconfig'.pyright.setup {
  capabilities = capabilities,
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "off",
      }
    }
  }
}
require 'lspconfig'.vimls.setup {}
require 'lspconfig'.lua_ls.setup {
  on_init = function(client)
    local path = client.workspace_folders[1].name
    if vim.loop.fs_stat(path .. '/.luarc.json') or vim.loop.fs_stat(path .. '/.luarc.jsonc') then
      return
    end

    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = {
        -- Tell the language server which version of Lua you're using
        -- (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT'
      },
      -- Make the server aware of Neovim runtime files
      workspace = {
        checkThirdParty = false,
        -- library = {
        --   vim.env.VIMRUNTIME
        --   -- Depending on the usage, you might want to add additional paths here.
        --   -- "${3rd}/luv/library"
        --   -- "${3rd}/busted/library",
        -- }
        -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
        library = vim.api.nvim_get_runtime_file("", true)
      }
    })
  end,
  settings = {
    Lua = {}
  }
}

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[e', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']e', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>a', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    -- defined by Trouble
    -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    -- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    -- vim.keymap.set('n', 'gy', vim.lsp.buf.type_definition, opts)
    -- vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<leader>o', vim.lsp.buf.document_symbol, opts)
    vim.keymap.set('n', '<leader>s', vim.lsp.buf.workspace_symbol, opts)
    vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<leader>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.api.nvim_set_keymap('n', '<leader>cl', '<cmd>CodeActionMenu<cr>', { noremap = true })
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', '<leader>p', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})
