# Wrap `brew` so install/uninstall updates the Brewfile via brew-file.
if [ -f /opt/homebrew/etc/brew-wrap ]; then
  source /opt/homebrew/etc/brew-wrap

  _post_brewfile_update() {
    echo "Brewfile was updated!"
  }
fi
