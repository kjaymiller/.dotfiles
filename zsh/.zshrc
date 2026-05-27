# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH
export PATH=/opt/homebrew/sbin:$PATH
export PATH=/opt/homebrew/opt:$PATH
export PATH=$HOMEBREW_PREFIX/lib/ruby/gems/3.3.0/bin:$PATH
export PATH=/Users/kjaymiller/.local/bin:$PATH
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export EDITOR=nvim

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"

alias nv=nvim

export vimconf="~/.config/nvim/"

# Aliases — any *.aliases.sh in the aliases dir (including dotfiles)
for f in ~/.dotfiles/zsh-plugins/aliases/*.aliases.sh(N) ~/.dotfiles/zsh-plugins/aliases/.*.aliases.sh(N); do
  source "$f"
done

# Plugins — sources/ is loaded in alphabetical order, so numbered prefixes
# (10-, 20-, ... 90-) control load order. Each entry is either:
#   - a *.sh file, sourced directly
#   - a directory, where we source the first matching entry point:
#       <dir>/*.plugin.zsh  →  <dir>/<name-after-prefix>.sh  →  <dir>/<name-after-prefix>.zsh
for entry in ~/.dotfiles/zsh-plugins/sources/*(N); do
  if [[ -f $entry ]]; then
    source "$entry"
  elif [[ -d $entry ]]; then
    stripped="${${entry:t}#*-}"
    for candidate in $entry/*.plugin.zsh(N) $entry/${stripped}.sh(N) $entry/${stripped}.zsh(N); do
      source "$candidate"
      break
    done
  fi
done

alias pbc="pbcopy"
