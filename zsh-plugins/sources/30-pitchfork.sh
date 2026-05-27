if command -v pitchfork >/dev/null; then
  mkdir -p ~/.zfunc
  if [[ ! -f ~/.zfunc/_pitchfork ]] || [[ $(command -v pitchfork) -nt ~/.zfunc/_pitchfork ]]; then
    pitchfork completion zsh > ~/.zfunc/_pitchfork
  fi
  fpath=(~/.zfunc $fpath)
fi
