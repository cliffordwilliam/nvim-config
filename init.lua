-- ============================================================================
-- A deliberately small Neovim config for Python.
--
-- Design rules (why this file looks the way it does):
--   1. Prefer Neovim built-ins over plugins. Built-ins ship with the binary,
--      so they cannot fall out of sync with it. Plugins can, and that is where
--      breakage comes from.
--   2. One plugin only: fzf-lua (fuzzy finding). Everything else -- LSP,
--      completion, syntax, file browsing -- is core Neovim.
--   3. Tools (basedpyright, ruff) are installed on the system with `uv tool`,
--      not by Neovim. No Mason, no npm, no Node.
--
-- Requires Neovim 0.12+ (for vim.pack and vim.o.autocomplete).
-- Structure and idioms follow kickstart.nvim; see :help lua-guide.
-- ============================================================================

-- Leader must be set before any mapping or plugin is loaded.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true -- JetBrainsMono Nerd Font

-- ============================================================================
-- OPTIONS  (:help option-list)
-- ============================================================================

vim.o.number = true
vim.o.relativenumber = true -- pairs with counts: 5j, 12k
vim.o.mouse = 'a'
vim.o.showmode = false -- redundant; the cursor already tells you
vim.o.ruler = false -- drop the 'line,col   All' readout from the statusline
vim.o.termguicolors = true -- 24-bit color; the colorscheme below needs it

-- Sync with the system clipboard. Scheduled because probing the clipboard
-- provider at startup measurably slows it down. Needs wl-clipboard (Wayland).
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

vim.o.breakindent = true
vim.o.undofile = true -- persistent undo, survives restarts

vim.o.ignorecase = true -- searching is case-insensitive...
vim.o.smartcase = true -- ...unless you type a capital

vim.o.signcolumn = 'yes' -- always on, so text doesn't jump when it appears
vim.o.updatetime = 250
vim.o.timeoutlen = 300

vim.o.splitright = true -- new splits go right/below, not left/above
vim.o.splitbelow = true

vim.o.list = true -- make whitespace visible; matters in Python
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

vim.o.inccommand = 'split' -- live preview of :substitute
vim.o.cursorline = true
vim.o.scrolloff = 10 -- keep 10 lines of context above/below the cursor
vim.o.confirm = true -- ask to save instead of refusing to quit

-- PEP 8 indentation. Vim's built-in Python indent handles the rest.
vim.o.expandtab = true
vim.o.shiftwidth = 4
vim.o.tabstop = 4
vim.o.softtabstop = 4

-- ============================================================================
-- COLORSCHEME  (:help :colorscheme)
--
-- retrobox ships with Neovim -- no plugin. The stock 'default' scheme maps most
-- of basedpyright's LSP semantic-token types (class, method, parameter,
-- namespace, variable, decorator) to the plain foreground color, so they render
-- as ordinary white text and all that type-aware classification is invisible.
-- retrobox gives those token types distinct colors (class->green, type->orange,
-- function->yellow, parameter->aqua), so the LSP's information actually shows.
-- Swap the name for another built-in (habamax, sorbet, slate) to taste.
-- ============================================================================

vim.cmd.colorscheme 'retrobox'

-- retrobox builds the statusline with the `reverse` attribute, which swaps a
-- muted grey-brown (#504945) onto a cream bar -- low-contrast and hard to read.
-- Override it with an explicit light bar + near-black bold text instead. A
-- ColorScheme autocmd (not a bare hi call) so it survives re-sourcing the scheme.
vim.api.nvim_create_autocmd('ColorScheme', {
  desc = 'High-contrast statusline',
  group = vim.api.nvim_create_augroup('statusline-contrast', { clear = true }),
  callback = function()
    -- Near-black text (#1d2021) on a muted tan bar (#a89984), bold. Dark-on-light
    -- keeps the text readable; the tan (vs bright cream) drops the bar's luminance
    -- ~half so it doesn't compete with a bright tmux statusline for attention.
    -- Both active and inactive groups get the same look -- splits aren't used here.
    local statusline = { fg = '#1d2021', bg = '#a89984', bold = true }
    vim.api.nvim_set_hl(0, 'StatusLine', statusline)
    vim.api.nvim_set_hl(0, 'StatusLineNC', statusline)
  end,
})
-- Fire once now for the colorscheme already set above.
vim.cmd.doautocmd('ColorScheme')

-- The built-in default statusline flushes the filename hard against the left
-- edge. Set it explicitly to add one space of left padding. Content mirrors the
-- default's left segment -- truncate-marker, path, then the help/preview/modified/
-- readonly flags -- so nothing visible changes except the leading gap.
vim.o.statusline = ' %<%f %h%w%m%r'

-- ============================================================================
-- KEYMAPS  (:help vim.keymap.set)
-- ============================================================================

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostic [Q]uickfix list' })
-- The inline virtual_text (see vim.diagnostic.config) is clipped at the viewport
-- edge; this pops the full message, wrapped, in the bordered float configured there.
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })

-- Move between splits without the <C-w> prefix.
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Focus split left' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Focus split right' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Focus split below' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Focus split above' })

-- Going back where you came from -- these are built-in, no mapping needed here,
-- noted so they're not forgotten:
--   <C-o>  jump back to the previous location (e.g. after grd goto-definition);
--          repeat to keep walking back. <C-i> (= <Tab>) jumps forward again.
--          These walk the jumplist -- big moves (goto def, searches, G, {}, :N)
--          are recorded; plain h/j/k/l are not. See :help jumplist and :jumps.
--   <C-^>  toggle between the current buffer and the previous one.

-- ============================================================================
-- AUTOCOMMANDS  (:help lua-guide-autocommands)
-- ============================================================================

-- Briefly highlight yanked text, so you can see what you grabbed.
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight on yank',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- ============================================================================
-- PLUGINS  (:help vim.pack)
--
-- vim.pack is Neovim's built-in plugin manager -- no bootstrap code needed.
-- `version` is pinned to a branch so updates are never a surprise.
-- Update deliberately with:  :lua vim.pack.update()
-- Inspect first, without fetching:  :lua vim.pack.update(nil, { offline = true })
-- The resulting nvim-pack-lock.json is committed to this repo.
-- ============================================================================

vim.pack.add {
  { src = 'https://github.com/ibhagwan/fzf-lua', version = 'main' },
}

-- 'default' profile, previewer fully disabled. The match list alone is enough
-- and the live preview was a distraction. `previewer = false` removes it
-- outright -- not merely hidden -- so there is no preview to appear or toggle,
-- and no `bat`/builtin previewer dependency to think about.
--
-- It MUST live under `defaults` (applied to every picker), NOT as a top-level
-- `previewer = false`: each picker (files, grep, ...) ships its own previewer
-- default that silently overrides a top-level key, so the top-level form leaves
-- the preview on. `defaults` is the one place that reliably reaches all pickers.
require('fzf-lua').setup {
  'default',
  defaults = { previewer = false },
}

local fzf = require 'fzf-lua'
vim.keymap.set('n', '<leader>sf', fzf.files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sg', fzf.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sh', fzf.helptags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', fzf.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sd', fzf.diagnostics_document, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', fzf.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader><leader>', fzf.buffers, { desc = 'Find existing buffers' })

-- ============================================================================
-- COMPLETION  (built-in -- no blink.cmp / nvim-cmp)
--
-- NOTE: 'complete' MUST include 'o' (omnifunc). Neovim's default is
-- '.,w,b,u,t' -- buffer words only -- so without this you get autocompletion
-- that never actually consults the language server. This is the single
-- easiest thing to get silently wrong here.
-- ============================================================================

vim.o.autocomplete = true -- 0.12: show the menu as you type
vim.o.complete = '.,o' -- '.' current buffer, 'o' omnifunc (= LSP)
vim.o.completeopt = 'menu,menuone,noselect,popup'

-- ============================================================================
-- LSP  (:help lsp)
--
-- Two servers, deliberately split:
--   basedpyright -> types, hover, go-to-definition, rename
--   ruff         -> linting, formatting, import sorting
--
-- Installed system-wide, outside Neovim:
--   uv tool install basedpyright
--   uv tool install ruff
--
-- basedpyright is used over upstream pyright for one concrete reason: it
-- auto-detects a project's ./.venv. Upstream pyright ignores $VIRTUAL_ENV
-- entirely and only finds your venv by accident of $PATH ordering, which
-- breaks the moment you open nvim from a shell where the venv isn't active.
-- ============================================================================

vim.lsp.config('basedpyright', {
  cmd = { 'basedpyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'setup.py', 'requirements.txt', '.venv', '.git' },
  settings = {
    basedpyright = {
      -- Let ruff own import sorting; otherwise both servers offer it.
      disableOrganizeImports = true,
      -- Suppresses basedpyright's greyed-out "not accessed" hints, which
      -- would duplicate ruff's F401 unused-import diagnostic.
      disableTaggedHints = true,
      analysis = {
        -- basedpyright defaults to 'recommended', which is far stricter than
        -- pyright and floods a normal codebase with errors. 'standard' matches
        -- what pyright/VS Code users expect.
        typeCheckingMode = 'standard',
        diagnosticMode = 'openFilesOnly',
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
})

vim.lsp.config('ruff', {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
  init_options = {
    settings = {
      -- F821 (undefined name) overlaps with basedpyright's own check, and
      -- basedpyright does real scope analysis, so defer to it.
      lint = { ignore = { 'F821' } },
    },
  },
})

vim.lsp.enable { 'basedpyright', 'ruff' }

vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'Set up buffer-local LSP keymaps and completion',
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then return end

    -- ruff's hover is near-useless and would fight basedpyright's.
    if client.name == 'ruff' then client.server_capabilities.hoverProvider = false end

    -- Wire the server into the built-in completion menu.
    if client:supports_method 'textDocument/completion' then
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    end

    local function map(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('gra', vim.lsp.buf.code_action, 'Code [A]ction')
    map('grd', fzf.lsp_definitions, '[G]oto [D]efinition')
    map('grr', fzf.lsp_references, '[G]oto [R]eferences')
    map('gO', fzf.lsp_document_symbols, 'Document Symbols')
    -- Note: K (hover) and grn/gra/grr are Neovim 0.11+ defaults; the maps
    -- above mostly just route them through fzf-lua's nicer picker.
  end,
})

vim.diagnostic.config {
  severity_sort = true,
  float = { source = 'if_many' },
  virtual_text = { source = 'if_many', spacing = 2 },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  } or {},
}

-- ============================================================================
-- FORMAT ON SAVE  (ruff)
--
-- NOTE: ruff's code actions are LAZY -- the server returns them with a `data`
-- field and NO `edit`. The obvious `if action.edit then apply end` loop
-- silently does nothing for import sorting. You must call codeAction/resolve
-- first to get the actual edit. This is the second easy thing to get wrong.
-- ============================================================================

---Request a ruff code action of `kind`, resolve it, and apply it.
---@param bufnr integer
---@param kind string LSP code action kind, e.g. 'source.fixAll.ruff'
local function ruff_code_action(bufnr, kind)
  local ruff = vim.lsp.get_clients({ bufnr = bufnr, name = 'ruff' })[1]
  if not ruff then return end

  local params = vim.lsp.util.make_range_params(0, ruff.offset_encoding)
  params.context = { only = { kind }, diagnostics = {} }

  local res = ruff:request_sync('textDocument/codeAction', params, 3000, bufnr)
  for _, action in ipairs(res and res.result or {}) do
    -- The resolve step this file exists to remember.
    if not action.edit and action.data then
      local resolved = ruff:request_sync('codeAction/resolve', action, 3000, bufnr)
      action = (resolved and resolved.result) or action
    end
    if action.edit then vim.lsp.util.apply_workspace_edit(action.edit, ruff.offset_encoding) end
  end
end

vim.api.nvim_create_autocmd('BufWritePre', {
  desc = 'Sort imports, autofix, and format with ruff',
  group = vim.api.nvim_create_augroup('ruff-format-on-save', { clear = true }),
  pattern = '*.py',
  callback = function(args)
    ruff_code_action(args.buf, 'source.organizeImports.ruff')
    ruff_code_action(args.buf, 'source.fixAll.ruff')
    vim.lsp.buf.format {
      bufnr = args.buf,
      timeout_ms = 3000,
      filter = function(c) return c.name == 'ruff' end,
    }
  end,
})

-- vim: ts=2 sts=2 sw=2 et
