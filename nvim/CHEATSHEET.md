# Cheat Sheet

`<leader>` is `<Space>`. Live version: `<leader>ch`.

## Daily keys

| Key | Does |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fw` | Live grep the project |
| `<leader>fo` | Recent files |
| `<Tab>` / `<S-Tab>` | Next / previous buffer |
| `<leader>x` | Close buffer |
| `\` | Reveal current file in tree / close tree |
| `<C-h/j/k/l>` | Move between splits and tmux panes |
| `<C-s>` | Save |
| `;` | Command mode (`:`) |
| `jk` | Escape (insert mode) |
| `<Esc>` | Clear search highlight |
| `gd` | Go to definition |
| `K` | Hover docs |
| `gra` | Code action |
| `grn` | Rename symbol |
| `grr` | References |
| `]d` / `[d` | Next / previous diagnostic |
| `<leader>dt` | Diagnostics: errors-only ⇄ all |
| `<leader>fd` | Diagnostics, project-wide (Telescope) |
| `<leader>de` | Show full diagnostic under cursor (float) |
| `<leader>/` | Toggle comment |
| `<leader>gg` | lazygit |
| `<F5>` | Debug: start / continue |

## Telescope

| Key | Does |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fa` | Find all files, including hidden and git-ignored |
| `<leader>fw` | Live grep |
| `<leader>fz` | Fuzzy find in the current buffer |
| `<leader>fd` | Diagnostics, project-wide |
| `<leader>fb` | Open buffers |
| `<leader>fo` | Recent files |
| `<leader>fh` | Help pages |
| `<leader>ma` | Marks |
| `<leader>pt` | Pick a hidden terminal |
| `<leader>th` | Theme picker |
| `<leader>cm` | Git commits |
| `<leader>gt` | Git status |

Inside a picker:

| Key | Does |
|---|---|
| `<C-n>` / `<C-p>` | Next / previous result |
| `<CR>` | Open |
| `<C-v>` / `<C-x>` / `<C-t>` | Open in vsplit / split / tab |
| `<C-u>` / `<C-d>` | Scroll the preview |
| `<C-q>` | Send results to quickfix |
| `<Esc>` | Close |
| `?` | Show all picker mappings |

## Git

| Key | Does |
|---|---|
| `<leader>gg` | lazygit |
| `<leader>gf` | lazygit, filtered to this file's history |

gitsigns draws the gutter signs but binds no keys.

### Inside lazygit

`?` lists every key valid in the current panel. Panels: `1` status, `2` files,
`3` branches, `4` commits, `5` stash.

| Key | Does |
|---|---|
| `q` | Quit back to nvim |
| `<Esc>` | Back / cancel |
| `<Space>` | Stage file / checkout branch / apply stash, depending on panel |
| `a` | Stage or unstage everything |
| `<CR>` | Drill in — on a file, opens per-hunk staging |
| `c` | Commit |
| `A` | Amend |
| `d` | Discard / delete / drop, depending on panel |
| `s` | Stash all changes |
| `p` / `P` | Pull / push |
| `f` | Fetch |
| `z` / `Z` | Undo / redo, reflog-based |
| `x` | Confirm discard |
| `:` | Run a raw shell command |

Per-hunk staging (`<CR>` on a file): `<Space>` stage hunk, `h` / `l` previous /
next hunk, `v` select a line range, `d` discard hunk, `<Esc>` back.

## LSP

Buffer-local; live once a server attaches.

| Key | Does |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `K` | Hover docs |
| `grr` | References |
| `gra` | Code action |
| `grn` | Rename symbol |
| `gri` | Implementation |
| `grt` | Type definition |
| `grx` | Run code lens |
| `gO` | Document symbols |
| `<leader>D` | Type definition, older alias for `grt` |
| `<leader>ra` | Rename via NvRenamer's floating box |
| `<leader>ds` | Send this file's diagnostics to the location list |
| `<leader>fd` | Telescope diagnostics picker, whole project |
| `<leader>wa` / `<leader>wr` / `<leader>wl` | Add / remove / list workspace folder |
| `<C-w>d` | Show the diagnostic under the cursor in a float |
| `<leader>ih` | Toggle inlay hints on/off, every buffer |

### Parameter info (signature help)

The float pops up on its own as soon as you type `(` or `,` inside a call, and
bolds the parameter you are on. Nothing to press.

| Key | Does |
|---|---|
| `<C-q>` (insert) | Cycle to the next overload — `std::string(` has 26 |
| `<C-S>` (insert) | Force the native float instead |
| `<C-s>` (from inside that float) | Cycle it — normal mode only, hence `<C-q>` above |
| `K` | Hover: the full declaration, docs included |

clangd puts the return type on the end as `-> T`, e.g.
`add(int lhs, int rhs) -> int`. Constructors show none because they have none —
for those the overload count is the useful part.

### Inlay hints

On by default. The greyed-in annotations at call sites and on deduced types:

```cpp
auto n: size_t = s.size();
add(lhs: 1, rhs: 2);
```

clangd needs no configuration for this; pyright does, and it is set in
`lua/configs/lspconfig.lua`. `<leader>ih` toggles both.

## Diagnostics and lists

| Key | Does |
|---|---|
| `]d` / `[d` | Next / previous diagnostic |
| `]D` / `[D` | Last / first diagnostic in the buffer |
| `]q` / `[q` | Next / previous quickfix entry |
| `]Q` / `[Q` | Last / first quickfix entry |
| `]l` / `[l` | Next / previous location-list entry |
| `]b` / `[b` | Next / previous buffer |
| `]a` / `[a` | Next / previous arglist file |
| `]t` / `[t` | Next / previous tag |
| `]<Space>` / `[<Space>` | Insert a blank line below / above |
| `<leader>dt` | Toggle errors-only ⇄ all severities |
| `<leader>de` | Show diagnostic under cursor in a float (alias of `<C-w>d`) |

`]d` / `[d` step **errors only** by default — warnings are filtered out until
`<leader>dt`. See CONFIG-REFERENCE → "Diagnostics are filtered to errors only".

## Debugging

| Key | Does |
|---|---|
| `<F5>` | Start / continue — first run prompts for the executable |
| `<F1>` | Step into |
| `<F2>` | Step over |
| `<F3>` | Step out |
| `<F7>` | Toggle the dap-ui panels |
| `<leader>b` | Toggle breakpoint |
| `<leader>B` | Conditional breakpoint |
| `<leader>dpr` | Python only: debug the test method under the cursor |

Inside dap-ui: `<CR>` expand or edit a value, `e` edit, `d` remove, `r` REPL.

## File tree

| Key | Does |
|---|---|
| `\` | Reveal the current file, or close the tree if you are in it |
| `<C-n>` | Toggle |
| `<leader>e` | Focus |
| `s` / `S` | Open in vertical / horizontal split |
| `<CR>` / `o` | Open |
| `<C-v>` / `<C-x>` / `<C-t>` | vsplit / split / new tab |
| `a` / `d` / `r` | Create / delete / rename |
| `x` / `c` / `p` | Cut / copy / paste |
| `y` / `Y` / `gy` | Copy name / relative path / absolute path |
| `H` | Show dotfiles, hidden by default |
| `I` | Show git-ignored files, hidden by default |
| `R` | Refresh |
| `E` / `W` | Expand all / collapse all |
| `-` | Up a directory |
| `g?` | Full tree keymap list |

Gutter glyphs are git status, not errors: `✗` unstaged, `★` untracked,
`✓` staged, `➜` renamed, `◌` ignored.

## Buffers, windows, tmux

| Key | Does |
|---|---|
| `<Tab>` / `<S-Tab>` | Next / previous buffer |
| `<leader>x` | Close buffer |
| `<C-h/j/k/l>` | Move between splits, and across tmux pane borders |
| `<C-s>` | Save |
| `<C-c>` | Yank the whole file |
| `<C-w>v` / `<C-w>s` | Split vertical / horizontal |
| `<C-w>q` | Close window |
| `<C-w>=` | Equalize sizes |

## Terminals

| Key | Does |
|---|---|
| `<A-i>` | Toggle floating terminal |
| `<A-h>` / `<A-v>` | Toggle horizontal / vertical terminal |
| `<leader>h` / `<leader>v` | New horizontal / vertical terminal |
| `<C-x>` | Leave terminal mode |
| `<leader>pt` | Pick a hidden terminal |

## Completion (insert mode)

| Key | Does |
|---|---|
| `<C-y>` | Accept the highlighted item, and insert its `#include` |
| `<CR>` | Accept |
| `<C-n>` / `<C-p>` | Next / previous item |
| `<Tab>` / `<S-Tab>` | Next / previous item, or jump snippet placeholders |
| `<C-Space>` | Open the menu |
| `<C-e>` | Close the menu |
| `<C-d>` / `<C-f>` | Scroll the docs popup down / up |
| `<C-b>` / `<C-e>` | Start / end of line |
| `<C-h/j/k/l>` | Left / down / up / right |

A `•` prefix marks a completion that will add a header.

## Editing

| Key | Does |
|---|---|
| `<leader>/` | Toggle comment, normal and visual |
| `gcc` | Toggle comment line |
| `gc` | Comment operator — `gc3j`, `gcap`, or a visual selection |
| `gx` | Open the URL or filepath under the cursor |
| `<leader>fm` | Format the buffer now |
| `<leader>n` / `<leader>rn` | Toggle line numbers / relative numbers |
| `an` / `in` | Select the outer / inner treesitter node |
| `]n` / `[n` | Next / previous node |
| `]N` / `[N` | Next / previous sibling node |

## Folding

Treesitter-driven, so folds land on real function/class/block boundaries. Files
open fully expanded; the `-`/`+` markers live in the leftmost column.

| Key | Does |
|---|---|
| `za` | Toggle the fold under the cursor |
| `zc` / `zo` | Close / open the fold under the cursor |
| `zC` / `zO` | Close / open it and everything nested inside it |
| `zM` / `zR` | Close all / open all folds in the file |
| `zj` / `zk` | Jump to the next / previous fold |
| click `-` / `+` | Toggle that fold from the gutter |

## Formatting

Runs on save; `<leader>fm` forces it.

| Filetype | Formatter | Style from |
|---|---|---|
| c, cpp | clang-format | `~/.clang-format` |
| cmake | gersemi | defaults |
| python | black | defaults |
| lua | stylua | `.stylua.toml` |

## Discovery

| Key | Does |
|---|---|
| `<leader>ch` | NvCheatsheet — every mapping with a `desc`, live |
| `<leader>wK` | which-key: all keymaps |
| `<leader>wk` | which-key: query a prefix |
| `<leader>fh` | Telescope help pages |
| `g?` | nvim-tree's keymap list, inside the tree |
| `?` | lazygit's context menu, inside lazygit |
