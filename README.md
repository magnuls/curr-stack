# dotfiles

My terminal setup: Alacritty + tmux + Neovim + zsh, on macOS.

```sh
git clone https://github.com/magnuls/dotfiles ~/dotfiles && ~/dotfiles/install.sh
```

That's the whole install. It fetches everything it needs, symlinks the configs into
place, and backs up anything it would have overwritten. Nothing to edit first.

Want to see what it would do before it does it?

```sh
~/dotfiles/install.sh --dry-run
```

## What you get

| | |
|---|---|
| **Alacritty** | GPU terminal, Everforest Dark, JetBrainsMono Nerd Font. Launches straight into tmux. |
| **tmux** | Tokyo Night status bar, vim keys, `\|`/`-` splits, sessions that survive reboots. |
| **Neovim** | NvChad-based: C/C++ and Python LSP, DAP debugging, treesitter folding, inlay hints. Lives in its own repo — [magnuls/Nvim-Setup](https://github.com/magnuls/Nvim-Setup), cloned for you. |
| **zsh** | oh-my-zsh + powerlevel10k, autosuggestions, syntax highlighting, fzf history search. |
| **git** | `nvim` as editor, `gh` as credential helper, a global ignore file. |
| **dev** | clang-format / clang-tidy / btop / ideavim configs. |

## Requirements

macOS. If you don't have Homebrew, the installer offers to install it, then installs
everything in [`Brewfile`](Brewfile).

On Linux most of this works, but you'll need to install the packages yourself and run
with `--no-brew`. Anything Apple-specific is skipped rather than fatal.

## What it touches

Every config is a **symlink** back into `~/dotfiles`, so editing a file here changes
your live setup — and `git diff` shows what you've changed.

```
~/.zshrc  ~/.zprofile  ~/.p10k.zsh  ~/.gitconfig
~/.clang-format  ~/.clang-tidy  ~/.ideavimrc
~/.config/{alacritty,tmux,git,btop,nvim}
```

If any of those already exist, they're **moved** (not deleted) to
`~/.dotfiles-backup/<timestamp>/`, and the path is printed at the end. To undo the
install: delete the symlinks and move your files back.

Your name and email are **not** in the tracked git config — the installer asks for them
and writes `~/.gitconfig.local`, which `git/gitconfig` includes. So you won't end up
committing as me.

## Options

| Flag | |
|---|---|
| `--dry-run` | Print every action, change nothing. |
| `--no-brew` | Skip Homebrew and the Brewfile. |
| `--no-nvim` | Don't clone the Neovim config. |

## Making it yours

- **Shell tweaks that shouldn't be committed** — put them in `~/.zshrc.local`, sourced
  automatically and ignored by git.
- **Different Alacritty theme** — the import line at the top of
  `alacritty/alacritty.toml` points at any file in
  [alacritty-theme](https://github.com/alacritty/alacritty-theme), cloned to
  `~/.config/alacritty/themes/themes/`.
- **Don't want tmux on launch** — delete the `[terminal.shell]` block in
  `alacritty/alacritty.toml`.
- **Fewer packages** — the bottom section of the `Brewfile` is project-specific stuff
  you can delete.

## Notes

The heavy third-party pieces (oh-my-zsh, powerlevel10k, the Alacritty theme collection,
tmux plugins, the nvim config) are cloned by the installer rather than committed here —
together they're ~150MB of someone else's git history. This repo stays under a megabyte.

If the tmux status bar looks wrong on first launch, press `prefix + I` (that's
`Ctrl-b` then capital `I`) inside tmux to install the plugins.

btop rewrites its own config when you quit it, so `dev/btop.conf` will occasionally show
up as modified with a machine-specific theme path baked in. `git checkout dev/btop.conf`
to discard that.
