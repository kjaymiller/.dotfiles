# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/homebrew/sbin:$PATH
export PATH=/opt/homebrew/opt:$PATH

export EDITOR=nvim

eval "$(zoxide init zsh)"

alias vvi=nvim
alias nv=nvim
alias lz="lazygit"
alias ls="eza --icons=always"
alias ll='ollama run "llama3.1"'

for file in $(ls -1 --icons=never .zshrc_plugins/sources/*.sh); do
  source "$file"
done

export vimconf="~/.config/nvim/"
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval $(thefuck --alias)

source ~/.git.aliases.sh
eval "$(starship init zsh)"
