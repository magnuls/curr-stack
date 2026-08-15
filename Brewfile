# Brewfile — `brew bundle --file Brewfile` installs everything below.
# install.sh runs this for you; run it by hand to re-sync later.

# --- Required by these dotfiles -------------------------------------------
# Skipping any of these leaves a config referencing a binary that isn't there.
brew "neovim"       # the nvim config lives in github.com/magnuls/Nvim-Setup
brew "tmux"         # alacritty auto-attaches to a tmux session named "main"
brew "git"
brew "fzf"          # .zshrc sources `fzf --zsh` for Ctrl-R / Ctrl-T
brew "ripgrep"      # telescope's live_grep backend
brew "fastfetch"    # the banner .zshrc prints on shell start
cask "alacritty"
cask "font-jetbrains-mono-nerd-font"  # alacritty.toml asks for this exact font

# --- Terminal tooling ------------------------------------------------------
brew "bash"         # macOS ships bash 3.2 from 2007; this is bash 5
brew "btop"         # config in dev/btop.conf
brew "gh"           # git credential helper in git/gitconfig
brew "lazygit"      # <leader>gg in nvim
brew "hyperfine"    # command-line benchmarking
brew "macmon"       # Apple Silicon power/thermal monitor
brew "uv"           # python package manager

# --- C / C++ ---------------------------------------------------------------
brew "cmake"
brew "llvm@18"      # clangd, clang-format, clang-tidy (configs in dev/)
brew "googletest"
brew "tree-sitter-cli"
brew "tree-sitter@0.25"

# --- Python ----------------------------------------------------------------
brew "python@3.11"

# --- LaTeX -----------------------------------------------------------------
brew "texlab"       # LaTeX language server
brew "latexindent"
cask "basictex"
cask "skim"         # PDF viewer with SyncTeX support

# --- Optional: project-specific, safe to delete ----------------------------
# Not referenced by any config here — they came along with my own projects.
brew "assimp"       # 3D model import (physics engine)
brew "opencv"       # computer vision
brew "ollama"       # local LLMs
brew "pymupdf"
brew "pure"
cask "iterm2"       # backup terminal; alacritty is the primary
