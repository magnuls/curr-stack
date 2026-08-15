-- C/C++ toolchain, in pipeline order: LSP -> format -> debug.
-- Ported from dreamsofcode-io/neovim-cpp, which targeted NvChad v2.0.
--
-- The nvim-lspconfig and conform specs below are shared with CMake and Python;
-- their per-language settings live in configs/. Tool installation is in
-- plugins/tools.lua.

return {
  -- 1. LSP -----------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- 2. Formatting ----------------------------------------------------------
  -- Replaces upstream's null-ls (archived 2023). Style comes from
  -- ~/.clang-format; format-on-save is enabled in configs/conform.lua.
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  -- 3. Debugging -----------------------------------------------------------
  -- Keymaps are in lua/mappings.lua, not here: NvChad v2.0's
  -- core.utils.load_mappings hook no longer exists.
  { "mfussenegger/nvim-dap" },

  {
    "rcarriga/nvim-dap-ui",
    event = "VeryLazy",
    -- nvim-nio became a hard dependency after upstream was written.
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      require("configs.dap").setup_ui()
    end,
  },

  {
    "jay-babu/mason-nvim-dap.nvim",
    event = "VeryLazy",
    dependencies = { "mason-org/mason.nvim", "mfussenegger/nvim-dap" },
    opts = function()
      return { handlers = require("configs.dap").handlers }
    end,
  },
}
