# dotfiles

Alacritty + tmux + Neovim, on macOS.

## Install

```sh
# get the configs
git clone https://github.com/magnuls/dotfiles ~/dotfiles

# install the programs (needs Homebrew — https://brew.sh)
brew install neovim tmux ripgrep
brew install --cask alacritty font-jetbrains-mono-nerd-font

# put the configs in place
mkdir -p ~/.config/alacritty ~/.config/tmux ~/.config/nvim
cp -r ~/dotfiles/alacritty/. ~/.config/alacritty/
cp -r ~/dotfiles/tmux/.      ~/.config/tmux/
cp -r ~/dotfiles/nvim/.      ~/.config/nvim/

# alacritty color themes
git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes

# tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

Then:

1. Open **Alacritty** — it drops you straight into a tmux session named `main`.
2. Inside tmux, press `Ctrl-b` then `I` (capital i) once to install the tmux plugins.
3. Run `nvim` — plugins and language servers install themselves on first launch.

## What you get

| | |
|---|---|
| **alacritty/** | GPU-accelerated terminal. Everforest Dark, JetBrainsMono Nerd Font, opens straight into tmux. |
| **tmux/** | Vim keys, `\|` and `-` to split, Tokyo Night status bar, sessions that survive reboots. |
| **nvim/** | NvChad-based: C/C++ and Python LSP, debugging, treesitter. Keybindings in [nvim/CHEATSHEET.md](nvim/CHEATSHEET.md), full tour in [nvim/CONFIG-REFERENCE.md](nvim/CONFIG-REFERENCE.md). |

## Tweaks

- **No tmux on launch** — delete the `[terminal.shell]` block in `~/.config/alacritty/alacritty.toml`.
- **Different colors** — point the `import` line at the top of `alacritty.toml` at any file in `~/.config/alacritty/themes/themes/`.
