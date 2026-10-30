# dotfiles

My macOS setup: AeroSpace + SketchyBar for windows, Rex (and Ghostty) for terminals,
zsh with oh-my-zsh, fzf and oh-my-posh.

## Install

```sh
git clone https://github.com/srir/dotfiles ~/code/dotfiles
~/code/dotfiles/install.sh
```

`install.sh` is safe to re-run. It:

- installs Homebrew and everything in `Brewfile`
- installs oh-my-zsh, the `fzf-tab` and `zsh-autosuggestions` plugins, nvm, and SbarLua
- backs up any existing file it would replace (as `<file>.pre-dotfiles`), then
  symlinks `home/` into `~` with [GNU Stow](https://www.gnu.org/software/stow/)
- builds SketchyBar's helper binaries and starts SketchyBar

## Layout

| Path | What |
| --- | --- |
| `home/.zshrc`, `.zshenv`, `.zprofile`, `.aliases` | zsh (oh-my-zsh, fzf-tab, autosuggestions, zoxide, oh-my-posh) |
| `home/.config/omp.json` | oh-my-posh prompt |
| `home/.aerospace.toml`, `home/.config/aerospace/` | AeroSpace tiling, workspaces and monitor assignment |
| `home/.config/sketchybar/` | SketchyBar (Lua, via SbarLua), with AeroSpace workspaces |
| `home/.config/rex/` | Rex keymap: herdr-style `ctrl+b` prefix, sessions instead of tabs |
| `home/.config/ghostty/` | Ghostty, plus the Duskfox theme Rex imports |
| `home/.config/karabiner/` | caps lock → escape, cmd/option swap on the external keyboard |
| `home/.config/zed/` | Zed settings and keymap |
| `home/.config/herdr/`, `home/.config/graphite/` | herdr keys, Graphite aliases |
| `raycast/rex-jump/` | Raycast command to jump to any Rex session or agent pane |
| `legacy/` | the old (2017) bash/vim dotfiles |

## Local overrides

Machine-specific settings and secrets stay out of the repo:

- `~/.zshenv.local`: env vars, API keys
- `~/.zshrc.local`: interactive shell extras
- `~/.gitconfig.local`: e.g. a work email

## Manual steps

- **Rex**: install Rex Beta. Then press `ctrl+b` `shift+t` once to import the Duskfox
  theme, and turn on Settings → Rex Server → Remote Control (Rex Jump and
  `cmd+shift+n` "New Window with This Session" need it).
- **Rex Jump**: `cd raycast/rex-jump && npm install && npm run dev`, then quit it
  once Raycast lists **Jump to Rex Pane**.
- **AeroSpace, SketchyBar, Karabiner**: grant Accessibility / Input Monitoring when
  macOS asks. Karabiner's cmd/option swap only applies to the keyboard with vendor
  9456 / product 320; edit `karabiner.json` for a different one.
- **AeroSpace monitors**: workspaces E and T are pinned to monitors by name. See
  `home/.config/aerospace/DISPLAY-NAMES.md`. With only the built-in screen,
  everything falls back to `main`.
- **Python/Node**: `pyenv install <version>`, `nvm install --lts`.
