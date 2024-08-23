# zshrc_plugins

## What is it

This is a list of ZSH scripts that are used by my .zshrc_plugins

This section is made up of sources and aliases.

### sources

Sources are the files that configure different tools that need the .zshrc modified

### aliases

Aliases are a list of commands. Most of these are pulled from <https://github.com/sebastienrousseau/dotfiles>. Learn more from - <https://dotfiles.io>

## Where is the .zshrc

It's at the root of the [dotfiles](../README.md) directory. This project is using [stow]() and because of that I have to have the files setup in the same path as they appear in the root directory.

One day when people [sponsor](https://github.com/sponsors/kjaymiller) my work maybe I will think more about building my perfect dotfile project.

## Why not include these them in the .zshrc

![Suspicious Looks](https://media1.tenor.com/m/-L5-p15qh6kAAAAd/pardon-me.gif)

If you need to know...It's because I forget what they are doing and I am often like "where do I go to do thing..."

A specific file is also easier to have someone copy than "Oh you should copy lines 345-364" (Also those lines can change).

## How do I load them

Fork this project

If you are are copying my `.zshrc` file then there is nothing else to do. The files are loaded one at a time.

If you aren't copying my `.zshrc` file then you will need to add each file that you want.

- For the Plugins:
  You can do that with `source .zsrch_plugins/sources/<FILE>`
- For the Aliases:
  You can do that with `source .zsrch_plugins/aliases/<FILE>`
