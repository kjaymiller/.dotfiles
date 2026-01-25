# kjaymiller's .dotfiles

This repo is a collection of dotfiles and scripts that I use to configure my system.

The dotfiles are configured using [GNU Stow](https://www.gnu.org/software/stow/) with a per-tool package structure for flexible management.

## Installation

I'm using a mac. I think most of these tools are also supported on linux, but no guarantees.

### Prerequisites

Install Stow:
```bash
brew install stow
```

### Quick Start

Fork the repo, clone it, and cd into the repo directory.

#### Install All Packages
```bash
stow zsh git tmux nvim wezterm bat gh starship zellij karabiner aerospace thefuck howzit searchlink alacritty brew
```

#### Install Specific Package Groups

Essential shell setup:
```bash
stow zsh git starship
```

Editor:
```bash
stow nvim
```

Terminal tools:
```bash
stow tmux wezterm zellij
```

Window management:
```bash
stow aerospace karabiner
```

### Individual Package Installation

```bash
stow zsh         # Zsh shell configuration
stow git         # Git configuration
stow tmux        # Tmux terminal multiplexer
stow nvim        # Neovim editor
stow wezterm     # WezTerm terminal emulator
stow bat         # Bat syntax highlighter
stow gh          # GitHub CLI and gh-dash
stow starship    # Starship prompt
stow zellij      # Zellij terminal multiplexer
stow karabiner   # Karabiner keyboard remapper
stow aerospace   # AeroSpace window manager
stow thefuck     # Command corrector
stow howzit      # Template manager
stow searchlink  # Search utility
stow alacritty   # Alacritty terminal themes
stow brew        # Homebrew bundle file
```

### Uninstalling Packages

To remove symlinks for a specific package:
```bash
stow -D package-name
```

To remove all packages:
```bash
stow -D zsh git tmux nvim wezterm bat gh starship zellij karabiner aerospace thefuck howzit searchlink alacritty brew
```

## Package Structure

Each tool has its own directory containing the dotfiles that will be symlinked to your home directory. This allows you to:
- Install only the tools you need
- Update individual tool configurations independently
- Share specific configurations with others
- Keep your dotfiles organized and maintainable
