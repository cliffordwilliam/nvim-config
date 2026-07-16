# nvim-config

A deliberately small Neovim setup for Python on Ubuntu.

**One plugin.** Everything else is core Neovim.

## Why it looks like this

The maintenance burden of a Neovim config is mostly a function of **plugin
count**, not line count. Plugins are what break when Neovim updates and what
carry their own breaking changes. Core APIs are stable. So this config prefers
built-ins wherever they're good enough, and the result is something that mostly
doesn't need looking after.

Neovim 0.12 made that practical: it has a built-in plugin manager (`vim.pack`),
native LSP configuration (`vim.lsp.config`/`vim.lsp.enable`), and built-in
insert-mode autocompletion. Those used to be three plugins.

## What's here

| Concern | Choice | Notes |
| :--- | :--- | :--- |
| Editor | Neovim 0.12+ | Official tarball in `/opt`, symlinked to `/usr/local/bin` |
| Plugin manager | `vim.pack` | Built in. Lockfile committed as `nvim-pack-lock.json` |
| Plugins | `fzf-lua` | The one thing genuinely missing from core |
| Types / hover / goto | `basedpyright` | `uv tool install basedpyright` |
| Lint / format / imports | `ruff` | `uv tool install ruff` |
| Completion | built-in | `vim.lsp.completion` + `vim.o.autocomplete` |
| Syntax highlighting | built-in | Vim's Python syntax; no treesitter (see below) |
| File browsing | built-in | netrw (`:Explore`), plus fzf-lua |

### Deliberately absent

- **Mason** — tools are installed with `uv tool`, system-wide and visible.
  Nothing is hidden inside Neovim's data directory.
- **nvim-treesitter** — its `main` branch needs `tree-sitter-cli` >= 0.26.1,
  which Ubuntu's apt doesn't provide (it has 0.25.9), plus a C compiler and
  local parser compilation. That's a toolchain to maintain in exchange for
  nicer highlighting. Vim's built-in Python syntax and indent are good.
  Revisit if apt catches up.
- **blink.cmp / nvim-cmp** — built-in completion is sufficient here. The
  known trade-off: it can't merge LSP and buffer sources into one ranked menu
  the way blink can.
- **lazy.nvim** — `vim.pack` covers pinning and lockfiles. Its missing feature
  is lazy-loading, which matters at 30+ plugins, not at one.
- **A colorscheme, statusline, git signs, which-key** — not needed yet.

## Install on a new machine

```bash
# 1. Neovim itself (see update.sh for why not apt/snap)
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

# 2. System dependencies
#    wl-clipboard is for Wayland; use xclip on X11 instead.
sudo apt install -y wl-clipboard ripgrep fd-find fzf git curl

# 3. Python tooling
uv tool install basedpyright
uv tool install ruff

# 4. This config
git clone <this-repo> ~/repositories/nvim-config
ln -s ~/repositories/nvim-config ~/.config/nvim

# 5. Verify
nvim +checkhealth
```

## Maintenance

Two things update, both on purpose, never on their own:

```bash
./update.sh                                       # Neovim itself
```
```vim
:lua vim.pack.update(nil, { offline = true })     " review plugin changes
:lua vim.pack.update()                            " apply them
```

Then commit `nvim-pack-lock.json` if it changed.

When something breaks, `:checkhealth` first.

## Sources worth trusting

Neovim's own `:help` docs are authoritative and — unlike any blog post — ship
with your binary, so they can't be out of sync with your version.

- `:help vim.pack`, `:help lsp`, `:help news-0.12`, `:checkhealth`
- [Neovim INSTALL.md](https://github.com/neovim/neovim/blob/master/INSTALL.md)
- [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) — the reference
  for *how* to write config. Maintained by a Neovim core team member, and this
  config follows its idioms and structure. Note its per-distro **install**
  recipes are community-contributed and can lag: its Ubuntu recipe currently
  points at the `neovim-ppa/unstable` PPA, whose newest 26.04 build is a
  pre-release older than current stable, and installs an apt `tree-sitter-cli`
  too old for the treesitter setup it ships. Its *Debian* recipe (the tarball)
  is the one used here. Follow kickstart for the how, not the install.
- [Ruff editor setup](https://docs.astral.sh/ruff/editors/setup/) ·
  [basedpyright docs](https://docs.basedpyright.com/)

## Cheatsheet

Leader is `<Space>`.

| Key | Action |
| :-- | :--- |
| `<leader>sf` | Search files |
| `<leader>sg` | Live grep |
| `<leader>sh` | Search help |
| `<leader>sk` | Search keymaps |
| `<leader>sd` | Search diagnostics |
| `<leader><leader>` | Switch buffer |
| `grd` / `grr` | Goto definition / references |
| `grn` / `gra` | Rename / code action |
| `K` | Hover docs |
| `<leader>q` | Diagnostics to quickfix |

Files format, sort imports, and autofix on save via ruff.

## Python projects

`basedpyright` auto-detects a `./.venv` in the project root, so `uv`-managed
projects work with no configuration. (This is why it's used instead of upstream
pyright, which ignores `$VIRTUAL_ENV` and only finds a venv via `$PATH`.)
