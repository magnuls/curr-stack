-- Python. Ported from dreamsofcode-io/neovim-python (NvChad v2.0, Apr 2024).
--
-- Most of that repo is already here: nvim-dap, nvim-dap-ui and nvim-nio came
-- with the C++ port, and conform replaces its null-ls. What is left is the
-- debug adapter below, plus entries in:
--   plugins/cpp.lua      pyright, ruff, black, debugpy (mason-tool-installer)
--   configs/lspconfig.lua  pyright + ruff
--   configs/conform.lua    black
--   plugins/editor.lua     python treesitter parser

return {
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = {
      "mfussenegger/nvim-dap",
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      -- debugpy's own venv, installed by mason. stdpath avoids hardcoding
      -- ~/.local/share/nvim as upstream does.
      require("dap-python").setup(vim.fn.stdpath "data" .. "/mason/packages/debugpy/venv/bin/python")
    end,
  },
}
