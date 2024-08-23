# update brewfile when `brew install <PACKAGE>` is called

if [ -f $(brew --prefix)/etc/brew-wrap ]; then
  source $(brew --prefix)/etc/brew-wrap
fi
