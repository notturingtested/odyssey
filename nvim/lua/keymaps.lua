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

-- For toggling comments in normal mode
vim.api.nvim_set_keymap('n', '<leader>/', 'gcc', { noremap = true, silent = true })

-- For toggling comments in visual mode
vim.api.nvim_set_keymap('v', '<leader>/', ':<C-u>gcc<CR>', { noremap = true, silent = true })

vim.keymap.set("n", "<leader>fml", "<cmd>CellularAutomaton make_it_rain<CR>")
-- vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format()]]
-- new formatter
vim.g.neoformat_try_node_exe = 1

vim.cmd [[autocmd BufWritePre * Neoformat]]



-- Copy
vim.api.nvim_set_keymap('n', '<D-c>', ':w !pbcopy<CR><CR>', { noremap = true })
vim.api.nvim_set_keymap('v', '<D-c>', ':w !pbcopy<CR><CR>', { noremap = true })

-- Paste
vim.api.nvim_set_keymap('n', '<D-v>', ':r !pbpaste<CR>', { noremap = true })
vim.api.nvim_set_keymap('i', '<D-v>', '<C-r>=system(\'pbpaste\')<CR>', { noremap = true })

-- Cut
vim.api.nvim_set_keymap('v', '<D-x>', ':w !pbcopy<CR><CR>gvd', { noremap = true })

