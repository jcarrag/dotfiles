vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- lazygit
vim.api.nvim_set_keymap("n", "<leader>lg", "<cmd>LazyGit<cr>", { noremap = true, silent = true })

-- lsp diagnostics cache clear
vim.api.nvim_set_keymap("n", "<leader>ra", "<cmd>lua vim.diagnostic.reset()<cr>", { noremap = true })

-- lsp trouble
vim.api.nvim_set_keymap("n", "<leader>a", "<cmd>Trouble document_diagnostics toggle<cr>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>A", "<cmd>Trouble workspace_diagnostics toggle<cr>", { noremap = true })
-- vim.api.nvim_set_keymap('n', '<leader>tq', '<cmd>Trouble quickfix toggle<cr>', { noremap = true })
vim.api.nvim_set_keymap("n", "gr", "<cmd>Trouble lsp_references toggle<cr>", { noremap = true })
vim.api.nvim_set_keymap("n", "gd", "<cmd>Trouble lsp_definitions toggle<cr>", { noremap = true })
vim.api.nvim_set_keymap("n", "gy", "<cmd>Trouble lsp_type_definitions toggle<cr>", { noremap = true })
vim.api.nvim_set_keymap("n", "gi", "<cmd>Trouble lsp_implementations toggle<cr>", { noremap = true })

-- fzf
vim.api.nvim_set_keymap("n", "<C-g>", "<cmd>lua require('fzf-lua').git_files()<cr>", { noremap = true })
-- a couple of necessary extra params here:
-- 1. disable adding icons since it makes fzf 10x slower (https://github.com/ibhagwan/fzf-lua/issues/1005#issuecomment-1894367825)
-- 2. include filename in fzf's fuzzy search
vim.api.nvim_set_keymap(
	"n",
	"<leader><C-g>",
	"<cmd>lua require('fzf-lua').grep_project({ file_icons=false, git_icons=false, fzf_opts = { ['--nth'] = '1..' }, rg_opts = '--hidden --column --line-number --no-heading --color=always --smart-case --max-columns=4096 -e' })<cr>",
	{ noremap = true }
)
vim.api.nvim_set_keymap("n", "<leader><C-w>", "<cmd>lua require('fzf-lua').buffers()<cr>", { noremap = true })

-- telescope
vim.api.nvim_set_keymap("n", "<leader>fh", "<cmd>lua require('telescope.builtin').help_tags()<cr>", { noremap = true })
vim.api.nvim_set_keymap(
	"n",
	"<leader>fd",
	"<cmd>lua require('telescope.builtin').diagnostics()<cr>",
	{ noremap = true }
)
vim.api.nvim_set_keymap(
	"n",
	"<leader>fi",
	"<cmd>lua require('telescope.builtin').lsp_implementations()<cr>",
	{ noremap = true }
)
vim.api.nvim_set_keymap("n", "<leader>fw", "<cmd>Telescope telescope-cargo-workspace switch<cr>", { noremap = true })

-- DAP
vim.api.nvim_set_keymap("n", "<leader>db", "<cmd>lua require('dap').toggle_breakpoint()<cr>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>dc", "<cmd>lua require('dap').continue()<cr>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>so", "<cmd>lua require('dap').step_over()<cr>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>si", "<cmd>lua require('dap').step_into()<cr>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>du", "<cmd>lua require('dapui').toggle()<cr>", { noremap = true })

-- SnipRun
vim.api.nvim_set_keymap("n", "<leader>sr", "<cmd>lua require('sniprun').run()<cr>", { noremap = true })

-- Quickfix
vim.api.nvim_set_keymap("n", "<leader>qn", "<cmd>:cn<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader>qp", "<cmd>:cp<CR>", { noremap = true })

-- Neotree
-- the Neotree commands don't work when bound to just <C-*> and called when Neotree is focussed
vim.api.nvim_set_keymap("n", "<leader><C-f>", "<cmd>Neotree reveal<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<leader><C-b>", "<cmd>Neotree toggle<CR>", { noremap = true })

-- Windows
vim.api.nvim_set_keymap("n", "<M-j>", "<C-W>+", { noremap = true })
vim.api.nvim_set_keymap("n", "<M-k>", "<C-W>-", { noremap = true })
vim.api.nvim_set_keymap("n", "<M-l>", "<C-W>>", { noremap = true })
vim.api.nvim_set_keymap("n", "<M-h>", "<C-W><", { noremap = true })

vim.api.nvim_set_keymap("n", "<C-j>", "<C-W>j", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-k>", "<C-W>k", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-l>", "<C-W>l", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-h>", "<C-W>h", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-p>", "<C-W>p", { noremap = true })

-- Clang
vim.api.nvim_set_keymap("n", "<leader>he", "<cmd>ClangdSwitchSourceHeader<cr>", { noremap = true })

-- Oil
vim.api.nvim_set_keymap("n", "<leader>oo", "<cmd>Oil<cr>", { noremap = true })

-- Neorg
-- vim.api.nvim_set_keymap('n', '<leader>ne', '<cmd>Neorg index<cr>', { noremap = true }) vim.api.nvim_set_keymap('n', '<leader>nr', '<cmd>Neorg return<cr>', { noremap = true })

vim.api.nvim_set_keymap("n", "J", "<cmd>lua require('config.utils').join_spaceless()<cr>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-w>o", "<cmd>lua require('config.utils').onlyAndNeotree()<cr>", { noremap = true })

-- copy current filename + position
vim.api.nvim_set_keymap("n", "yL", "<cmd>let @+=join([expand('%:p'),  line('.')], ':')<cr>", { noremap = true })
