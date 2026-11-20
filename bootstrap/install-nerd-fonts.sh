#!/usr/bin/env bash
# Bootstrap Nerd Fonts on macOS (brew) or Linux (GitHub release -> ~/.local/share/fonts)
set -euo pipefail

FONT="${1:-JetBrainsMono}" # e.g. JetBrainsMono, FiraCode, Hack, Iosevka
VERSION="${NERD_FONTS_VERSION:-latest}"

case "$(uname -s)" in
  Darwin)
    echo "==> Installing ${FONT} Nerd Font via Homebrew"
    brew install --cask "font-${FONT,,}-nerd-font"
    ;;
  Linux)
    DEST="$HOME/.local/share/fonts"
    mkdir -p "$DEST"
    if [ "$VERSION" = "latest" ]; then
      VERSION="$(curl -fsSL https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep -oP '"tag_name":\s*"\K[^"]+')"
    fi
    echo "==> Downloading ${FONT} Nerd Font ${VERSION}"
    curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/${VERSION}/${FONT}.tar.xz" \
      | tar -xJ -C "$DEST"
    fc-cache -f "$DEST" >/dev/null
    ;;
  *)
    echo "Unsupported OS: $(uname -s)" >&2
    exit 1
    ;;
esac

echo "==> Done. Verify with: fc-list | grep -i nerd"
