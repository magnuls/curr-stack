# Neovim C++ Setup — Reference

Why things are set the way they are. **Keybindings live in CHEATSHEET.md.**

Base: NvChad v2.5 starter, plugins via lazy.nvim. Leader is `<Space>`.

## Layout

```
init.lua                  NvChad bootstrap (stock, don't edit)
lua/
  chadrc.lua              theme / UI
  options.lua             global editor options
  autocmds.lua            per-filetype settings (C/C++ indent)
  mappings.lua            all keymaps -- runs last, so it wins
  plugins/
    cpp.lua               C/C++ specs: LSP -> format -> debug
    python.lua            Python debug adapter
    editor.lua            treesitter, file tree, completion, signature, tmux
    git.lua               lazygit
    tools.lua             every external tool (mason-tool-installer)
  configs/
    lspconfig.lua         clangd (add future servers here)
    diagnostics.lua       errors-only filter + <leader>dt toggle
    inlayhints.lua        inlay hints + <leader>ih toggle
    conform.lua           formatters
    dap.lua               debugger + codelldb run configs
    lazy.lua              lazy.nvim settings (stock)
```

Specs say *which* plugin and when to load it; `configs/` says how it behaves.

`./test/smoke.sh` builds a polyglot fixture and runs 131 checks against it.
Run it after changing anything.

Settings outside this repo that the config depends on:

| Path | Controls |
|---|---|
| `~/.clang-format` | C/C++ format style (`IndentWidth: 4`) |
| `~/Library/Preferences/clangd/config.yaml` | clangd flags, diagnostics |
| `~/.config/tmux/tmux.conf` | tmux keys, theme, plugins |

---

## The five traps

### ⚠️ Build with debug info, or breakpoints silently never bind

```bash
g++ -std=c++23 -g -o main main.cpp
cmake -S . -B build -DCMAKE_BUILD_TYPE=Debug   # unset BUILD_TYPE passes no -g
```

Failure mode gives you nothing: codelldb launches, the program runs to
completion, the breakpoint is ignored. No error. Check with
`dwarfdump --debug-info <binary> | head` — empty means no debug info.

macOS also needs `sudo DevToolsSecurity -enable` (already done here). Without
it the symptom is identical.

### ⚠️ `CompileFlags.Add` is not a fallback mechanism

In `~/Library/Preferences/clangd/config.yaml`, `CompileFlags.Add` appends
*after* the compile command, and for `-std` the last flag wins — so it silently
overrides `compile_commands.json`, `compile_flags.txt` and `fallbackFlags`.

Keep `-std` out of that file. It caused two bugs: a stale `-std=c++20` beating
an explicit c++23 everywhere, and `-std=c++23` applied to C files, which clang
rejects outright (`not allowed with 'C'`).

### ⚠️ macOS reads a different clangd config path than Linux

macOS: `~/Library/Preferences/clangd/config.yaml`. That is the only one clangd
reads here. `~/.config/clangd/config.yaml` is the *Linux* path — it existed
here, drifted out of sync, and was deleted. Don't recreate it on this machine.

### ⚠️ Keymap ordering: NvChad wins by default

`init.lua` runs `require "mappings"` inside a `vim.schedule`, which fires
*after* eagerly-loaded plugins set their keymaps — so a plugin that maps
`<C-h>` at load time gets silently overwritten by `nvchad.mappings`.

This made vim-tmux-navigator completely inert. Fix is
`vim.g.tmux_navigator_no_mappings = 1` plus explicit maps in `lua/mappings.lua`.
Anything that must beat an NvChad default belongs there.

### ⚠️ Diagnostics are filtered to errors only

`configs/diagnostics.lua` sets the display floor to ERROR at startup. Every
clang-tidy finding and every `-Wall`/`-Wextra` warning is WARN severity, so a
file with eleven narrowing warnings shows a clean gutter and `]d` reports
"No more valid diagnostics to move to". That is deliberate, not a dead LSP.

`<leader>dt` flips the floor to everything. `<leader>fd` reads
`vim.diagnostic.get()` directly and lists all severities in either mode.

The filter cannot hide one check while showing others — severity is all it
knows, so it takes `-Wall` warnings down with clang-tidy's. Per-check
suppression belongs in the project's `.clang-tidy`.

Implementation note: `vim.diagnostic.config()` replaces per key rather than
merging, so `apply()` reads each handler back before adding the filter, and must
run *after* `nvchad.configs.lspconfig.defaults()` — otherwise it captures an
empty table and NvChad's sign icons vanish.

---

## Features

### Debugging
`nvim-dap` + `codelldb`. A custom handler closes over a `last_program` local, so
the second `<F5>` pre-fills the last executable instead of prompting from an
empty box. Two configs: `LLDB: Launch` and `LLDB: Launch (with args)`.
UI opens and closes with the session, via listeners in `lua/plugins/init.lua`.

`<leader>b` overrides NvChad's "new buffer" — use `:enew`.

### Theme
`tokyonight` via `lua/chadrc.lua`. Alacritty and tmux use the same theme, so
another nvim theme leaves the statusline clashing with the tmux bar. `<leader>th`
to swap.

Do **not** delete `~/.local/share/nvim/base46/` to force a rebuild — `init.lua`
loads that cache before anything can regenerate it, so a missing cache aborts
startup with no mappings or options. Use `<leader>th`.

### clangd
`lua/configs/lspconfig.lua`, via `vim.lsp.config()` + `vim.lsp.enable()`.
Runs with `--background-index` and `--clang-tidy`.

clang-tidy's check list is `~/.clang-tidy` — deliberately narrow, since
`readability-*` and `cppcoreguidelines-*` are where the noise lives. Like
`~/.clang-format` it sits at `$HOME` so it applies under `~`, and a project's own
`.clang-tidy` overrides it.

### Which C++ standard clangd uses
1. The project's `compile_commands.json` — a real project always wins.
2. `-std=c++23` from `init_options.fallbackFlags`, only when there is no
   compile database.

For CMake projects, set the standard once and the editor follows:

```cmake
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
```

If clangd flags `std::println`, your build would reject it too. Fix the
CMakeLists, not the editor.

### Unused-include warnings — off
`UnusedIncludes: None` in `~/Library/Preferences/clangd/config.yaml`. It comes
from include-cleaner, on by default since clangd 17. Set to `Strict` to restore.
`MissingIncludes` is left at its default. `:LspRestart` to pick up a change.

### Parameter info — automatic
`ray-x/lsp_signature.nvim` in `lua/plugins/editor.lua`. The float appears on `(`
and `,` inside a call and bolds the active parameter; `<C-q>` cycles overloads
from insert mode. The float lists every overload at once and highlights the
active one — `init.lua:440` inserts the other labels around what Neovim's own
`convert_signature_help_to_markdown_lines` renders.

`<C-q>` was chosen because its only insert-mode meaning is "insert literal
character", a duplicate of `<C-v>`. **`<C-\>` does not work** and must not be
used: Neovim's input layer treats CTRL-\ as a prefix awaiting CTRL-N/G/O, so a
lone `<C-\>` mapping registers successfully and then never fires.

Neovim 0.12 renders signature help natively and even cycles it, but only on
demand (insert `<C-S>`) and its cycle key is buffer-local to the float and
normal-mode only — you cannot page through `std::string`'s 26 constructors
without leaving insert mode. That gap is the whole reason for the plugin.

This config previously set `client.server_capabilities.signatureHelpProvider =
false` for clangd, because the native popup collided with cmp's menu. That threw
away the parameter list for every server. The collision is now handled by
`check_completion_visible`, which repositions the float around the completion
menu instead of suppressing it.

`hint_enable = false`: the plugin's own virtual-text hint duplicates inlay hints,
and two sets of virtual text on one line is unreadable.

Return types come through as a `-> T` suffix (`add(int lhs, int rhs) -> int`).
Constructors have none, so for those the overload count is the useful part; `K`
(hover) is the fallback for a full declaration.

### Inlay hints — on by default
`lua/configs/inlayhints.lua`, applied from `lspconfig.lua`, toggled by
`<leader>ih`. Same `apply()`/`toggle()` shape as `configs/diagnostics.lua`.

Rendering is Neovim's (`vim.lsp.inlay_hint`); the module only decides which
buffers get it on, via an `LspAttach` autocmd guarded by `supports_method`. What
each server emits is server-side:

- **clangd** — `ParameterNames` and `DeducedTypes` are on by default in clangd
  22, so there is nothing to set. Override with an `InlayHints:` block in
  `~/Library/Preferences/clangd/config.yaml`.
- **pyright** — every hint defaults to off; switched on in the `settings` table
  in `lua/configs/lspconfig.lua`.

The toggle calls `inlay_hint.enable()` with no filter, so it clears the whole
session rather than one buffer; new buffers then follow the flag via the
autocmd.

### Indentation — C/C++ is 4, everything else 2
NvChad sets 2 globally but `~/.clang-format` uses `IndentWidth: 4`, so new lines
got rewritten on every save. A `FileType` autocmd in `lua/autocmds.lua` sets 4
for C-family buffers only — global would recreate the mismatch in Lua.

**`IndentWidth` in `~/.clang-format` and `shiftwidth` in that autocmd must change
together.**

### Formatting
`conform.nvim`: clang_format, gersemi, black, stylua. `format_on_save` on.

`timeout_ms` is 2000, not the default 500 — black and gersemi pay Python startup
on first run in a session, and a cold miss means the save silently goes
unformatted. It is a ceiling, not a delay.

Style comes from `~/.clang-format` (LLVM base, 4-space, 100 columns,
`Standard: Latest` — clang-format's enum stops at c++20 and rejects c++23).
It sits at `$HOME` so it applies everywhere under `~`; a project's own
`.clang-format` overrides it.

### Brace style
`BreakBeforeBraces: Attach` — K&R, opening brace on the same line.

### CMake
`neocmakelsp` provides completion, hover, go-to-definition and diagnostics; the
diagnostics *are* the linting, so no separate linter. `gersemi` formats on save.
Completion only works because NvChad's `*` capabilities advertise
`snippetSupport`.

### Python
`pyright` (types), `ruff` (lint + import sort), `black` (format), `debugpy`
(debug, via `nvim-dap-python`). Debug keys match C++, plus `<leader>dpr`.

`.venv` detection has two non-obvious requirements: `venvPath` must be
**absolute** (a relative `"."` silently fails over LSP), and pyright resolves the
venv once at startup, so `client.settings` alone is not enough — it needs an
explicit `workspace/didChangeConfiguration`. Both handled in
`configs/lspconfig.lua`.

mypy is deliberately absent; pyright already reports what it would.

### Treesitter
Installs `c`, `cpp`, `lua`, `luadoc`, `printf`, `vim`, `vimdoc`.

nvim-treesitter's `main` branch accepts *only* `install_dir` in `setup()` —
**`ensure_installed` is silently ignored**, including NvChad's, so the stock
config installs zero parsers with no warning. Neovim 0.12 bundles most of these
but **not `cpp`**. The config calls `require("nvim-treesitter").install()`
directly and starts highlighting per-buffer via `vim.treesitter.start()`.

### Tool installation
`mason-tool-installer` installs `clangd`, `clang-format`, `codelldb` on startup.
`ensure_installed` on `mason.nvim` itself — what upstream used — does nothing in
mason v2 and fails silently.

Mason's binaries are not on your shell `PATH`, so `which clang-format` finding
nothing is expected. Inside nvim, mason's bin is prepended, so bare `clangd`
resolves to mason's copy, not `/usr/bin/clangd`.

### gitsigns has no keymaps
Loaded and drawing signs, but NvChad ships it without an `on_attach` and it
binds nothing by default — no stage-hunk, reset, preview, blame, or hunk
navigation. Everything hunk-level goes through lazygit. `]c` / `[c` are Vim's
diff-mode motions and do not step gutter hunks.

---

## External requirements

- **ripgrep** — installed, required by Telescope's live grep.
- **Developer mode** — enabled, required for `debugserver`.
- **`fd`** — optional, makes Telescope's file pickers faster.
- **tmux `focus-events`** — optional; without it `'autoread'` can miss files
  changed outside nvim. Add `set -g focus-events on`.

---

## Tmux

Prefix is the default `Ctrl-b`.

| Key | Action |
|---|---|
| `prefix \|` | Split vertically |
| `prefix -` | Split horizontally |
| `prefix r` | Reload the config |
| `prefix h/j/k/l` | Resize pane by 5, repeatable |
| `prefix m` | Toggle pane zoom, repeatable |
| `Ctrl-h/j/k/l` | Navigate panes and nvim splits, no prefix |
| `v` / `C-v` / `y` (copy mode) | Select / rectangle toggle / copy and cancel |

`default-terminal` is `tmux-256color` with `Tc` overrides, without which nvim
colorschemes render washed out. Plugins via TPM: vim-tmux-navigator,
tmux-resurrect, tmux-continuum, tokyo-night-tmux.

vim-tmux-navigator must be installed on **both** sides. It claims
`Ctrl-h/j/k/l`, which is why pane resizing sits on `prefix h/j/k/l`.
