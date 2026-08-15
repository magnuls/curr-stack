-- Formatters. Spec: plugins/cpp.lua.
-- Replaces upstream's null-ls (archived 2023); conform ships with NvChad.
--
-- C/C++ style comes from ~/.clang-format (LLVM base, IndentWidth 4).
-- Lua style comes from .stylua.toml in this repo.
--
-- Editor indent must match the formatter or every new line gets rewritten on
-- save -- see the CppIndent autocmd in lua/autocmds.lua.

return {
  formatters_by_ft = {
    c = { "clang_format" },
    cpp = { "clang_format" },
    cmake = { "gersemi" },
    python = { "black" },
    lua = { "stylua" },
  },

  format_on_save = {
    -- 2000, not conform's default 500: black and gersemi are Python programs,
    -- and their first run in a session pays interpreter startup plus bytecode
    -- compilation. Measured ~210ms cold vs ~70ms warm, but a cold miss means
    -- the save silently goes unformatted. Fast formatters are unaffected --
    -- this is a ceiling, not a delay.
    timeout_ms = 2000,
    lsp_fallback = true,
  },
}
