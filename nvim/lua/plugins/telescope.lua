-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
-- Fuzzy Finder (files, lsp, etc)
return {
  'nvim-telescope/telescope.nvim',
  event = 'VeryLazy',
  branch = '0.1.x',
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
  },
  keys = {
    { '<leader>?', require('telescope.builtin').oldfiles },
    { '<leader><space>', require('telescope.builtin').buffers },
    {
      '<leader>s/',
      function()
        require('telescope.builtin').live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
      end,
    },
    { '<leader>ss', require('telescope.builtin').builtin },
    { '<leader>gf', require('telescope.builtin').git_files },
    { '<leader>sh', require('telescope.builtin').help_tags },
    { '<leader>sw', require('telescope.builtin').grep_string },
    { '<leader>sg', require('telescope.builtin').live_grep },
    { '<leader>sG', ':LiveGrepGitRoot<cr>' },
    { '<leader>sd', require('telescope.builtin').diagnostics },
    { '<leader>sr', require('telescope.builtin').resume },
    { '<leader>pf', require('telescope.builtin').find_files },
    { '<C-p>', require('telescope.builtin').git_files },
    {
      '<leader>ps',
      function()
        require('telescope.builtin').grep_string { search = vim.fn.input 'Grep > ' }
      end,
    },
    { '<leader>vh', require('telescope.builtin').help_tags },
  },
  config = function()
    require('telescope').setup {
      defaults = {
        mappings = {
          i = {
            ['<C-u>'] = false,
            ['<C-d>'] = false,
          },
        },
      },
    }

    -- Enable telescope fzf native, if installed
    pcall(require('telescope').load_extension, 'fzf')

    -- Custom function for live grep in git root
    local function find_git_root()
      local current_file = vim.api.nvim_buf_get_name(0)
      local current_dir
      local cwd = vim.fn.getcwd()
      if current_file == '' then
        current_dir = cwd
      else
        current_dir = vim.fn.fnamemodify(current_file, ':h')
      end

      local git_root = vim.fn.systemlist('git -C ' .. vim.fn.escape(current_dir, ' ') .. ' rev-parse --show-toplevel')[1]
      if vim.v.shell_error ~= 0 then
        print 'Not a git repository. Searching on current working directory'
        return cwd
      end
      return git_root
    end

    local function live_grep_git_root()
      local git_root = find_git_root()
      if git_root then
        require('telescope.builtin').live_grep {
          search_dirs = { git_root },
        }
      end
    end

    vim.api.nvim_create_user_command('LiveGrepGitRoot', live_grep_git_root, {})

    -- Other key mappings are set up in the 'keys' table
  end,
}
-- vim: ts=2 sts=2 sw=2 et
