source $HOME/.antigen/antigen.zsh

antigen use oh-my-zsh

antigen bundle gitfast
antigen bundle fasd
# antigen bundle pip
# antigen bundle command-not-found

antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle unixorn/autoupdate-antigen.zshplugin

antigen theme sorin

antigen apply

export EDITOR=/usr/bin/vim
export PATH=/usr/local/share/npm/bin:~/bin:/usr/local/bin:/usr/local/sbin/:/bin:/sbin:/usr/bin:/usr/sbin:$PATH
source ~/.aliases
source ~/.profile

PERL_MB_OPT="--install_base \"/Users/sriraghavan/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/Users/sriraghavan/perl5"; export PERL_MM_OPT;

export NVM_DIR="/Users/sriraghavan/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

eval "$(thefuck --alias)"

# This way the completion script does not have to parse Bazel's options
# # repeatedly.  The directory in cache-path must be created manually.
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
