# nvm.sh is only sourced from .zshrc, which non-interactive shells never read, and the
# brew shellenv below prepends Homebrew's node regardless -- so without this, scripts and
# GUI-launched apps get Homebrew's node instead of nvm's. Re-assert an nvm bin dir after
# brew: whatever "nvm use" put on PATH if there is one, else the default alias. Sourcing
# nvm.sh here instead would cost ~1s per zsh, since it shells out to npm via "nvm use".
_nvm_node="$(command -v node 2>/dev/null)"
case "$_nvm_node" in
  "$HOME"/.nvm/versions/node/*) _nvm_bin="${_nvm_node%/node}" ;;
  *) _nvm_bin="" ;;
esac
unset _nvm_node

eval "$(/opt/homebrew/bin/brew shellenv)"

if [ -z "$_nvm_bin" ] && [ -r "$HOME/.nvm/alias/default" ]; then
  _nvm_default="$(cat "$HOME/.nvm/alias/default")"
  case "$_nvm_default" in
    v*) ;;
    *) _nvm_default="v$_nvm_default" ;;
  esac
  _nvm_bin="$HOME/.nvm/versions/node/$_nvm_default/bin"
  unset _nvm_default
fi
if [ -n "$_nvm_bin" ] && [ -d "$_nvm_bin" ]; then
  export PATH="$_nvm_bin:$PATH"
fi
unset _nvm_bin

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"

export NODE_OPTIONS="--disable-warning=DEP0040"

# uv
export PATH="$HOME/.local/bin:$PATH"

# Machine-specific env and secrets (API keys, tokens) live here, outside the repo.
[ -f ~/.zshenv.local ] && source ~/.zshenv.local
