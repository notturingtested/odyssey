vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
-- Copy
vim.api.nvim_set_keymap('n', '<D-c>', ':w !pbcopy<CR><CR>', { noremap = true })
vim.api.nvim_set_keymap('v', '<D-c>', ':w !pbcopy<CR><CR>', { noremap = true })

-- Paste
vim.api.nvim_set_keymap('n', '<D-v>', ':r !pbpaste<CR>', { noremap = true })
vim.api.nvim_set_keymap('i', '<D-v>', '<C-r>=system(\'pbpaste\')<CR>', { noremap = true })

-- Cut
vim.api.nvim_set_keymap('v', '<D-x>', ':w !pbcopy<CR><CR>gvd', { noremap = true })

vim.opt.termguicolors = true

vim.opt.tabstop = 2

-- [[ Install `lazy.nvim` plugin manager ]]
require 'lazy-bootstrap'

-- [[ Configure plugins ]]
require 'lazy-plugins'

-- [[ Setting options ]]
require 'options'

-- [[ Basic Keymaps ]]
require 'keymaps'

-- [[ Configure Telescope ]]
-- (fuzzy finder)
require 'telescope-setup'

-- [[ Configure Treesitter ]]
-- (syntax parser for highlighting)
require 'treesitter-setup'

-- [[ Configure LSP ]]
-- (Language Server Protocol)
require 'lsp-setup'

-- [[ Configure nvim-cmp ]]
-- (completion)
require 'cmp-setup'

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
