#!/usr/bin/env bash
#
# Installs these dotfiles: fetches dependencies, then symlinks each config from
# this repo into place. Safe to re-run — it's idempotent, and anything it would
# overwrite gets moved to ~/.dotfiles-backup/<timestamp>/ first.
#
#   ./install.sh              full install
#   ./install.sh --dry-run    print every action, change nothing
#   ./install.sh --no-brew    skip Homebrew and the Brewfile
#   ./install.sh --no-nvim    skip cloning the nvim config
#
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
NVIM_REPO="https://github.com/magnuls/Nvim-Setup.git"

DRY_RUN=false
DO_BREW=true
DO_NVIM=true
backed_up=false

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --no-brew) DO_BREW=false ;;
    --no-nvim) DO_NVIM=false ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^#\ \?//'; exit 0 ;;
    *) echo "unknown option: $arg (try --help)" >&2; exit 1 ;;
  esac
done

# --- output helpers --------------------------------------------------------
if [ -t 1 ]; then
  BOLD=$'\033[1m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; DIM=$'\033[2m'; RESET=$'\033[0m'
else
  BOLD=''; GREEN=''; YELLOW=''; RED=''; DIM=''; RESET=''
fi
step() { printf '\n%s==> %s%s\n' "$BOLD" "$1" "$RESET"; }
ok()   { printf '  %s✓%s %s\n' "$GREEN" "$RESET" "$1"; }
skip() { printf '  %s·%s %s\n' "$DIM" "$RESET" "$1"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$RESET" "$1"; }
die()  { printf '\n%serror:%s %s\n' "$RED" "$RESET" "$1" >&2; exit 1; }

# Every mutating action goes through this, so --dry-run is honoured in one place.
run() {
  if $DRY_RUN; then
    printf '  %swould run:%s %s\n' "$DIM" "$RESET" "$*"
  else
    "$@"
  fi
}

# --- preflight -------------------------------------------------------------
step "Checking prerequisites"

command -v git >/dev/null || die "git is required but not installed."
ok "git $(git --version | awk '{print $3}')"

case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux)  OS=linux ;;
  *)      die "unsupported OS: $(uname -s). This targets macOS, and mostly works on Linux." ;;
esac
ok "$OS"

if $DO_BREW; then
  if ! command -v brew >/dev/null; then
    if [ "$OS" = macos ]; then
      warn "Homebrew not found — installing it (you'll be prompted for your password)."
      run /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      # The installer doesn't put brew on PATH for the current shell.
      for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        [ -x "$p" ] && eval "$("$p" shellenv)" && break
      done
    else
      warn "Homebrew not found. On Linux, install these with your package manager:"
      warn "  neovim tmux git fzf ripgrep fastfetch alacritty"
      warn "Then re-run with --no-brew."
      DO_BREW=false
    fi
  fi
  command -v brew >/dev/null && ok "homebrew $(brew --version | head -1 | awk '{print $2}')"
fi

# --- packages --------------------------------------------------------------
if $DO_BREW && command -v brew >/dev/null; then
  step "Installing packages from Brewfile"
  run brew bundle --file="$DOTFILES/Brewfile"
  ok "Brewfile applied"
else
  step "Installing packages from Brewfile"
  skip "skipped (--no-brew)"
fi

# --- symlinks --------------------------------------------------------------
# Deliberately before the oh-my-zsh install below: with no ~/.zshrc present the
# oh-my-zsh installer writes one from its own template, which we would then
# immediately back up and replace — leaving a confusing backup directory on a
# machine that had no dotfiles at all. Linking first means KEEP_ZSHRC=yes sees
# our symlink and leaves it alone.
step "Linking configs"

link() {
  local src="$DOTFILES/$1" dest="$HOME/$2"

  [ -e "$src" ] || die "missing file in repo: $1"

  # Already pointing where it should — nothing to do. This is what makes
  # re-running the script a no-op.
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    skip "$2"
    return
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    run mkdir -p "$BACKUP_DIR/$(dirname "$2")"
    run mv "$dest" "$BACKUP_DIR/$2"
    backed_up=true
    warn "$2 existed — backed up"
  fi

  run mkdir -p "$(dirname "$dest")"
  run ln -s "$src" "$dest"
  ok "$2"
}

link alacritty/alacritty.toml .config/alacritty/alacritty.toml
link tmux/tmux.conf           .config/tmux/tmux.conf
link zsh/.zshrc               .zshrc
link zsh/.zprofile            .zprofile
link zsh/.p10k.zsh            .p10k.zsh
link git/gitconfig            .gitconfig
link git/ignore               .config/git/ignore
link dev/.clang-format        .clang-format
link dev/.clang-tidy          .clang-tidy
link dev/.ideavimrc           .ideavimrc
link dev/btop.conf            .config/btop/btop.conf

# --- third-party clones ----------------------------------------------------
# Cloned rather than vendored: together these are ~150MB of other people's
# git history, and they update independently of this repo.
clone_if_missing() {
  local repo="$1" dest="$2" label="$3" depth="${4:---depth=1}"
  if [ -e "$dest" ]; then
    skip "$label already present"
  else
    run git clone $depth "$repo" "$dest"
    ok "$label"
  fi
}

step "Fetching dependencies"

if [ -d "$HOME/.oh-my-zsh" ]; then
  skip "oh-my-zsh already present"
else
  # Unattended: don't let the installer switch shells or launch a subshell,
  # and don't let it write its own .zshrc over the one we're about to link.
  #
  # ZSH is pinned explicitly rather than left to the installer's default. If
  # the caller happens to have ZSH exported (anyone already running oh-my-zsh
  # does), the installer sees a pre-existing directory, refuses to run, and
  # exits non-zero — which under `set -e` kills this whole script.
  run env ZSH="$HOME/.oh-my-zsh" RUNZSH=no CHSH=no KEEP_ZSHRC=yes /bin/sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  ok "oh-my-zsh"
fi

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions" "zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"
clone_if_missing https://github.com/romkatv/powerlevel10k \
  "$ZSH_CUSTOM/themes/powerlevel10k" "powerlevel10k"

clone_if_missing https://github.com/alacritty/alacritty-theme \
  "$HOME/.config/alacritty/themes" "alacritty themes"
clone_if_missing https://github.com/tmux-plugins/tpm \
  "$HOME/.config/tmux/plugins/tpm" "tpm (tmux plugin manager)"

if $DO_NVIM; then
  # Full clone, not shallow: it's small, and you'll want the history to pull.
  clone_if_missing "$NVIM_REPO" "$HOME/.config/nvim" "nvim config" ""
else
  skip "nvim config skipped (--no-nvim)"
fi

# --- git identity ----------------------------------------------------------
# git/gitconfig deliberately ships without a [user] block so nobody commits
# under someone else's name. It includes ~/.gitconfig.local, written here.
step "Git identity"

if [ -f "$HOME/.gitconfig.local" ]; then
  skip "~/.gitconfig.local already exists"
elif $DRY_RUN; then
  printf '  %swould prompt for%s git name/email → ~/.gitconfig.local\n' "$DIM" "$RESET"
elif [ -t 0 ]; then
  printf '  Your name for git commits: '; read -r git_name
  printf '  Your email for git commits: '; read -r git_email
  cat > "$HOME/.gitconfig.local" <<EOF
[user]
	name = $git_name
	email = $git_email
EOF
  ok "wrote ~/.gitconfig.local"
else
  # Non-interactive (piped into bash, CI). Leave a template rather than a
  # wrong identity — git will prompt on first commit anyway.
  cat > "$HOME/.gitconfig.local" <<'EOF'
# Fill these in — git/gitconfig includes this file.
[user]
	name =
	email =
EOF
  warn "not a terminal — wrote a template to ~/.gitconfig.local, fill it in"
fi

# --- plugin bootstrap ------------------------------------------------------
# Done here so the first launch of tmux/nvim isn't a wall of installer output.
# Both are verbose enough to bury this script's own output, so they go to a log
# and we only surface it if something fails. This takes a few minutes.
step "Installing plugins (this takes a few minutes)"

LOG="${TMPDIR:-/tmp}/dotfiles-install.log"
$DRY_RUN || : > "$LOG"

# Runs a command quietly, printing the tail of its log only on failure.
quietly() {
  local label="$1"; shift
  if $DRY_RUN; then
    printf '  %swould run:%s %s\n' "$DIM" "$RESET" "$*"
    return
  fi
  printf '  %s… %s%s' "$DIM" "$label" "$RESET"
  if "$@" >>"$LOG" 2>&1; then
    printf '\r  %s✓%s %s%s\n' "$GREEN" "$RESET" "$label" "$(printf '%20s' '')"
  else
    printf '\r'
    warn "$label failed — last lines of $LOG:"
    tail -15 "$LOG" | sed 's/^/      /'
  fi
}

if [ -x "$HOME/.config/tmux/plugins/tpm/bin/install_plugins" ]; then
  # Note: tpm reads the @plugin list from the RUNNING tmux server. If one is
  # already up with a different config, this can be a no-op — prefix + I inside
  # tmux is the reliable fallback.
  quietly "tmux plugins" "$HOME/.config/tmux/plugins/tpm/bin/install_plugins"
else
  warn "tpm not found — run tmux and press prefix + I instead"
fi

if $DO_NVIM && command -v nvim >/dev/null; then
  quietly "nvim plugins" nvim --headless "+Lazy! sync" +qa
elif $DO_NVIM; then
  warn "nvim not installed — plugins will sync on first launch"
fi

# --- verify ----------------------------------------------------------------
step "Verifying"

THEME_FILE="$HOME/.config/alacritty/themes/themes/everforest_dark_medium.toml"
if $DRY_RUN; then
  skip "verification skipped in --dry-run"
else
  # alacritty.toml imports this. A missing import is a hard startup error,
  # so it's worth an explicit check rather than a confusing crash later.
  if [ -f "$THEME_FILE" ]; then
    ok "alacritty theme import resolves"
  else
    warn "MISSING: $THEME_FILE"
    warn "Alacritty will fail to start. Re-run this script, or edit the import"
    warn "line in ~/.config/alacritty/alacritty.toml to point at a theme you have."
  fi

  for cmd in nvim tmux fzf rg; do
    command -v "$cmd" >/dev/null && ok "$cmd" || warn "$cmd not on PATH"
  done
fi

# --- done ------------------------------------------------------------------
printf '\n%sDone.%s\n' "$BOLD$GREEN" "$RESET"
if $DRY_RUN; then
  printf 'That was a dry run — nothing changed. Re-run without --dry-run to apply.\n'
  exit 0
fi

printf '\nNext:\n'
printf '  1. Open a new terminal (or: exec zsh) to pick up the shell config.\n'
printf '  2. Launch Alacritty — it auto-attaches to a tmux session named "main".\n'
printf '  3. Run `p10k configure` if you want a different prompt style.\n'
if [ "${SHELL:-}" != "$(command -v zsh 2>/dev/null)" ]; then
  printf '\nYour login shell is %s, not zsh. To switch:\n' "${SHELL:-unknown}"
  printf '  chsh -s %s\n' "$(command -v zsh 2>/dev/null || echo /bin/zsh)"
fi
if $backed_up; then
  printf '\n%sYour previous configs were moved to:%s\n  %s\n' "$BOLD" "$RESET" "$BACKUP_DIR"
  printf 'To undo this install, move them back and delete the symlinks.\n'
fi
