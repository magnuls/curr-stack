-- Autocommands. Per-filetype settings go here; globals are in options.lua.

require "nvchad.autocmds"

-- C/C++ indent width -----------------------------------------------------------
-- Must match IndentWidth in ~/.clang-format. NvChad sets 2 globally, so `o`
-- produced a 2-space line that format-on-save immediately rewrote to 4.
--
-- Buffer-local on purpose: Lua stays at 2, per .stylua.toml.
-- A FileType autocmd, not after/ftplugin/, so it runs after Neovim's own
-- ftplugin/cpp.vim and indent/cpp.vim and therefore wins.
--
-- Change this and ~/.clang-format together, or the symptom comes back.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("CppIndent", { clear = true }),
  pattern = { "c", "cpp", "objc", "objcpp", "cuda" },
  callback = function()
    vim.bo.shiftwidth = 4
    vim.bo.tabstop = 4
    vim.bo.softtabstop = 4
    vim.bo.expandtab = true
    -- cindent comes from Neovim's indent/cpp.vim; smartindent is the cruder
    -- fallback it supersedes, and NvChad enables it globally.
    vim.bo.cindent = true
    vim.bo.smartindent = false
  end,
})
