# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/homebrew/sbin:$PATH
export PATH=/opt/homebrew/opt:$PATH
export PATH=$HOMEBREW_PREFIX/lib/ruby/gems/3.3.0/bin:$PATH

export EDITOR=nvim

eval "$(zoxide init zsh)"

alias vvi=nvim
alias nv=nvim
alias lz="lazygit"
alias ls="eza --icons=always"
alias ll='ollama run "llama3.1"'

source ~/.zshrc_plugins/sources/atuin.sh
source ~/.zshrc_plugins/sources/brewfile.sh
source ~/.zshrc_plugins/sources/fzf.sh
source ~/.zshrc_plugins/sources/pyenv.sh
source ~/.zshrc_plugins/sources/envrc.sh


export vimconf="~/.config/nvim/"

eval $(thefuck --alias)


# Add Aliases
source ~/.zshrc_plugins/aliases/.git.aliases.sh
source ~/.zshrc_plugins/aliases/.gh.aliases.sh
source ~/.zshrc_plugins/aliases/.tmux.aliases.sh
source ~/.zshrc_plugins/aliases/.python.aliases.sh

eval "$(starship init zsh)"
# source ~/.zshrc_plugins/sources/brewfile.sh
eval "$(rbenv init -)"
alias lst="ls -L 1 -T"
