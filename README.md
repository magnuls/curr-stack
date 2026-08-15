# curr-stack

Alacritty + tmux + Neovim, on macOS.

## Install

```sh
# get the configs
git clone https://github.com/magnuls/curr-stack ~/curr-stack

# install the dependencies (needs Homebrew — https://brew.sh)
brew install neovim tmux ripgrep node python
brew install --cask alacritty font-jetbrains-mono-nerd-font

# put the configs in place
mkdir -p ~/.config/alacritty ~/.config/tmux ~/.config/nvim
cp -r ~/curr-stack/alacritty/. ~/.config/alacritty/
cp -r ~/curr-stack/tmux/.      ~/.config/tmux/
cp -r ~/curr-stack/nvim/.      ~/.config/nvim/

# alacritty color themes
git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes

# tmux plugin manager
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

Then:

1. Open **Alacritty** — it drops you straight into a tmux session named `main`.
2. Inside tmux, press `Ctrl-b` then `I` (capital i) once to install the tmux plugins.
3. Run `nvim` plugins and language servers install themselves on first launch.

## What you get

| | |
|---|---|
| **alacritty/** | Terminal: Everforest Dark, JetBrainsMono Nerd Font, opens straight into tmux. |
| **tmux/** | Vim keys, `\|` and `-` to split, Tokyo Night status bar, sessions that survive reboots. |
| **nvim/** | NvChad: C/C++ and Python LSP, debugging, treesitter. Keybindings in [nvim/CHEATSHEET.md](nvim/CHEATSHEET.md), full tour in [nvim/CONFIG-REFERENCE.md](nvim/CONFIG-REFERENCE.md). |

## Dependencies

Everything the configs need, all installed by the commands above:

| Dependency | Needed for |
|---|---|
| `alacritty`, `tmux`, `neovim` | The stack itself. |
| `font-jetbrains-mono-nerd-font` | The font Alacritty is configured to use; also the icons in the tmux and nvim status bars. |
| `ripgrep` | Telescope's live grep (`<leader>fw`) in nvim. |
| `node` | Mason uses it to install the pyright language server. |
| `python` | Mason uses it to install black and debugpy. |
| git + Xcode Command Line Tools | Cloning plugins and compiling treesitter parsers. Homebrew installs the CLT for you, so if `brew` works you already have both. |

Language servers, formatters, and debuggers (clangd, pyright, ruff, black, codelldb, debugpy, stylua, …) are **not** installed by hand — Mason downloads them automatically the first time you open nvim.

## Tweaks

- **No tmux on launch** — delete the `[terminal.shell]` block in `~/.config/alacritty/alacritty.toml`.
- **Different colors** — point the `import` line at the top of `alacritty.toml` at any file in `~/.config/alacritty/themes/themes/`.
