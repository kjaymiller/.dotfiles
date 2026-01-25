# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/homebrew/sbin:$PATH
export PATH=/opt/homebrew/opt:$PATH
export PATH=$HOMEBREW_PREFIX/lib/ruby/gems/3.3.0/bin:$PATH
export PATH=$(go env GOPATH)/bin:$PATH

export EDITOR=nvim

eval "$(zoxide init zsh)"

alias nv=nvim
alias lz="lazygit"
alias ls="eza --icons=always"
alias ll='ollama run "gpt-oss:latest"'

export vimconf="~/.config/nvim/"

eval $(thefuck --alias)


# Add Aliases
source ~/.dotfiles/zsh-plugins/aliases/.git.aliases.sh
source ~/.dotfiles/zsh-plugins/aliases/.gh.aliases.sh
source ~/.dotfiles/zsh-plugins/aliases/.tmux.aliases.sh
source ~/.dotfiles/zsh-plugins/aliases/.python.aliases.sh

# Source plugin configurations
source ~/.dotfiles/zsh-plugins/sources/atuin.sh
source ~/.dotfiles/zsh-plugins/sources/envrc.sh
source ~/.dotfiles/zsh-plugins/sources/fzf.sh
source ~/.dotfiles/zsh-plugins/sources/pyenv.sh
# source ~/.dotfiles/zsh-plugins/sources/brewfile.sh

. ~/.asdf/plugins/golang/set-env.zsh

eval "$(starship init zsh)"
alias lst="ls -L 1 -T"
alias lsl="ls -l"
alias pbc="pbcopy"
alias rene="python -m render_engine new-entry"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
alias inkscape=/Applications/Inkscape.app/Contents/MacOS/./inkscape
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
