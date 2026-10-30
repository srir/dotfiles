# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

zstyle ':omz:update' mode auto      # update automatically without asking

zstyle ':completion:*' list-prompt   ''
zstyle ':completion:*' select-prompt ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':fzf-tab:*' continuous-trigger '?'

zstyle ':autocomplete:*' min-input 2
zstyle ':autocomplete:*' insert-unambiguous yes

zstyle ':completion:*:git:*' group-order 'main commands' 'alias commands' 'external commands'
zstyle ':completion::complete:git-checkout:argument-rest:remote-branch-refs-noprefix' command "echo"
zstyle ':completion::complete:git-checkout:argument-rest:heads-remote' command "echo"
zstyle ':completion::complete:git-checkout:argument-rest:heads-local' command "echo"

# fzf-tab and zsh-autosuggestions are cloned into $ZSH_CUSTOM/plugins by install.sh
plugins=(git fzf-tab zsh-autosuggestions fzf)

source $ZSH/oh-my-zsh.sh

# User configuration

bindkey '^ ' autosuggest-accept

export EDITOR='vim'

source ~/.aliases

# Homebrew binaries before system paths (but pyenv init below will prepend shims first)
export PATH="/opt/homebrew/bin:$PATH"

command -v pyenv >/dev/null && eval "$(pyenv init -)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

if [[ "$CLAUDECODE" != "1" ]]; then
    eval "$(zoxide init --cmd cd zsh)"
fi

eval "$(oh-my-posh init zsh --config '~/.config/omp.json')"
# Harden against oh-my-posh reverting to its built-in default theme: the generated
# _omp_get_prompt never passes --config, so it relies on a per-session cache
# (~/.cache/oh-my-posh/zsh.<POSH_SESSION_ID>.omp.cache). If that cache entry is lost or
# expires (e.g. during a long-running TUI like claude/sand-sync), the prompt falls back to
# the default theme. Injecting --config makes every render resolve the real config.
functions[_omp_get_prompt]="${functions[_omp_get_prompt]/--save-cache/--config $HOME/.config/omp.json --save-cache}"

if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Machine-specific shell config lives here, outside the repo.
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
