#!/usr/bin/env bash
#
# Update Neovim itself to the latest stable release.
#
# Why this script exists: Neovim is installed from the official tarball rather
# than apt or snap, so nothing updates it automatically.
#
#   - Ubuntu's apt ships an older Neovim than this config needs (it required
#     0.12+ for vim.pack at the time of writing; apt had 0.11.6).
#   - The classic snap is built on the core22 base (Ubuntu 22.04) and patches
#     an RPATH into nvim that resolves libstdc++ from core22 *before* the
#     system's. On a modern Ubuntu that ABI gap breaks anything compiled
#     against the host toolchain, and the snap has shipped broken stable
#     builds before. Auto-updating into that is worse than updating by hand.
#
# This mirrors the install recipe from kickstart.nvim's README.
#
# Usage:  ./update.sh          (asks for sudo; prints the version when done)
#
# To update PLUGINS instead, that's a separate, deliberate step inside Neovim:
#   :lua vim.pack.update()                              -- fetch and apply
#   :lua vim.pack.update(nil, { offline = true })       -- review first
# Then commit the changed nvim-pack-lock.json.

set -euo pipefail

TARBALL="nvim-linux-x86_64.tar.gz"
URL="https://github.com/neovim/neovim/releases/latest/download/${TARBALL}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "==> Current: $(nvim --version 2>/dev/null | head -1 || echo 'not installed')"

echo "==> Downloading latest stable Neovim..."
curl -fL# -o "${TMP}/${TARBALL}" "$URL"

echo "==> Installing to /opt (requires sudo)..."
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf "${TMP}/${TARBALL}"
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

echo "==> Now: $(nvim --version | head -1)"
echo
echo "If something broke, check ':checkhealth' first."
echo "The previous version is gone; reinstall a specific one from:"
echo "  https://github.com/neovim/neovim/releases"
