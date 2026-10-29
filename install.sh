#!/usr/bin/env bash
# Set up a Mac from this repo. Safe to re-run.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

if ! command -v brew >/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"
brew bundle --file "$DOTFILES/Brewfile"

# oh-my-zsh and the custom plugins .zshrc loads
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
[ -d "$ZSH_CUSTOM/plugins/fzf-tab" ] || git clone https://github.com/Aloxaf/fzf-tab "$ZSH_CUSTOM/plugins/fzf-tab"
[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] ||
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"

# nvm (not from Homebrew, which nvm doesn't support)
if [ ! -d "$HOME/.nvm" ]; then
  PROFILE=/dev/null bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh)"
fi

# SbarLua, the Lua module the SketchyBar config is written against
if [ ! -f "$HOME/.local/share/sketchybar_lua/sketchybar.so" ]; then
  tmp="$(mktemp -d)"
  git clone https://github.com/FelixKratz/SbarLua.git "$tmp/SbarLua"
  (cd "$tmp/SbarLua" && make install)
  rm -rf "$tmp"
fi

# Apps that write state or credentials next to their config get a real directory,
# so stow links the tracked files into it instead of linking the whole directory.
mkdir -p "$HOME/.config"/{graphite,herdr,zed}

# Move aside anything stow would conflict with (e.g. the stock ~/.zshrc oh-my-zsh writes).
cd "$DOTFILES/home"
find . -type f | while read -r f; do
  target="$HOME/${f#./}"
  # Skip files that already resolve into this repo (stow linked their directory).
  if [ -e "$target" ] && [ "$(realpath "$target")" != "$DOTFILES/home/${f#./}" ]; then
    echo "Backing up $target -> $target.pre-dotfiles"
    mv "$target" "$target.pre-dotfiles"
  fi
done
stow --dir "$DOTFILES" --target "$HOME" --restow home

# SketchyBar's C helpers (cpu/network load, menus) need building on each machine.
(cd "$HOME/.config/sketchybar/helpers" && make)
brew services restart sketchybar

echo
echo "Done. Remaining manual steps are in $DOTFILES/README.md."
