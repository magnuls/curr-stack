-- Editor options. Global only -- per-filetype settings live in autocmds.lua.

require "nvchad.options"

-- Hybrid line numbers: absolute on the cursor line, relative above and below,
-- so the count for a j/k/dd motion is readable straight off the gutter.
-- NvChad sets `number` but leaves `relativenumber` off.
-- Toggle: <leader>rn (relative), <leader>n (numbers).
vim.o.relativenumber = true

-- Folding ----------------------------------------------------------------------
-- Neovim defaults to foldmethod=manual, i.e. no folds exist until you make them
-- by hand with zf. Drive them off the treesitter tree instead so functions,
-- classes and blocks fold on their real boundaries rather than on indentation
-- guesses. Parsers are installed and started in plugins/editor.lua; a filetype
-- with no parser just gets no folds, which is harmless.
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"

-- Open everything on load. Without this a file arrives fully collapsed, which
-- no other editor does. 99 is the idiom for "deeper than any real nesting".
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99

-- The clickable gutter: foldcolumn draws the -/+ markers, and NvChad already
-- sets mouse=a, so clicking one toggles that fold.
vim.o.foldcolumn = "1"

-- Empty foldtext (0.10+) keeps the folded line syntax-highlighted instead of
-- replacing it with the plain "+--  12 lines:" filler.
vim.o.foldtext = ""
