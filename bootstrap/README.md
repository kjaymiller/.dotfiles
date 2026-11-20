# bootstrap

System setup scripts that run outside of GNU Stow (things that can't just be symlinked).

## Nerd Fonts

Installs a Nerd Font of your choice (default: **JetBrainsMono**).

- **macOS**: `brew install --cask font-jetbrainsmono-nerd-font`
- **Linux**: downloads the font tarball from [nerd-fonts releases](https://github.com/ryanoasis/nerd-fonts/releases) into `~/.local/share/fonts` and refreshes the font cache

```bash
./bootstrap/install-nerd-fonts.sh                 # JetBrainsMono (default)
./bootstrap/install-nerd-fonts.sh FiraCode        # any font name from the releases page
NERD_FONTS_VERSION=v3.3.0 ./bootstrap/install-nerd-fonts.sh Hack  # pin a version
```

Verify:

```bash
fc-list | grep -i nerd
```
