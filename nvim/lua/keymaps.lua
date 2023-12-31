-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- [[ Highlight on yank ]]
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Show Netrw
vim.keymap.set('n', '<leader>pv', vim.cmd.Ex)

-- Copy
vim.api.nvim_set_keymap('n', '<D-c>', ':w !pbcopy<CR><CR>', { noremap = true })
vim.api.nvim_set_keymap('v', '<D-c>', ':w !pbcopy<CR><CR>', { noremap = true })

-- Paste
vim.api.nvim_set_keymap('n', '<D-v>', ':r !pbpaste<CR>', { noremap = true })
vim.api.nvim_set_keymap('i', '<D-v>', "<C-r>=system('pbpaste')<CR>", { noremap = true })

-- Cut
vim.api.nvim_set_keymap('v', '<D-x>', ':w !pbcopy<CR><CR>gvd', { noremap = true })

-- Set Escape to exit terminal mode
vim.api.nvim_set_keymap('t', '<Esc>', '<C-\\><C-n>', { noremap = true, silent = true })
