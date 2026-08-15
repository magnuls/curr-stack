-- External tools (LSP servers, formatters, debug adapters), for every language.
-- One list, so there is a single place to look when something isn't installed.
--
-- Both upstream repos put ensure_installed on mason.nvim itself. That worked in
-- NvChad v2.0 via :MasonInstallAll; mason v2 has no such option and v2.5 dropped
-- the command, so it silently installed nothing. mason-tool-installer is what
-- actually works.
--
-- Wiring a tool up is a separate step: servers in configs/lspconfig.lua,
-- formatters in configs/conform.lua, debug adapters in configs/dap.lua.

return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = "VeryLazy",
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = {
        -- C/C++
        "clangd", -- LSP
        "clang-format", -- formatter
        "codelldb", -- debug adapter

        -- CMake
        "neocmakelsp", -- LSP (completion + diagnostics)
        "gersemi", -- formatter

        -- Python
        "pyright", -- LSP (types, completion)
        "ruff", -- linter LSP; replaces ruff-lsp, which mason dropped
        "black", -- formatter
        "debugpy", -- debug adapter

        -- Lua
        "stylua", -- formatter
      },
    },
  },
}
