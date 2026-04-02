export TERM=xterm-256color
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

# Starship must init before atuin to avoid recursive zle-keymap-select wrapping
eval "$(starship init zsh)"

# Source plugin configurations
source ~/.dotfiles/zsh-plugins/sources/atuin.sh
source ~/.dotfiles/zsh-plugins/sources/envrc.sh
source ~/.dotfiles/zsh-plugins/sources/fzf.sh
source ~/.dotfiles/zsh-plugins/sources/pyenv.sh
# source ~/.dotfiles/zsh-plugins/sources/brewfile.sh

. ~/.asdf/plugins/golang/set-env.zsh
alias lst="ls -L 1 -T"
alias lt="ls -L 1 -T"
alias lsl="ls -l"
alias pbc="pbcopy"
alias rene="python -m render_engine new-entry"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
alias inkscape=/Applications/Inkscape.app/Contents/MacOS/./inkscape
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# bun completions
[ -s "/Users/kjaymiller/.bun/_bun" ] && source "/Users/kjaymiller/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"

export FZF_DEFAULT_OPTS="--preview 'bat --color=always --style=numbers --theme=\"Catppuccin Latte\" {}'"
