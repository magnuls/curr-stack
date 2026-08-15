-- Debugger setup for nvim-dap / nvim-dap-ui / mason-nvim-dap.
-- Specs: plugins/cpp.lua. Keymaps (F5, F1-F3, F7, <leader>b/B): mappings.lua.
--
-- macOS note: debugging needs `sudo DevToolsSecurity -enable`. Without it the
-- session initializes, the breakpoint verifies, and then nothing happens.

local M = {}

-- Open the UI with the session, close it when the session ends.
function M.setup_ui()
  local dap = require "dap"
  local dapui = require "dapui"
  dapui.setup()

  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close()
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close()
  end
end

M.handlers = {
  -- Default handler: stock behaviour for every adapter except codelldb.
  function(config)
    require("mason-nvim-dap").default_setup(config)
  end,

  -- Stock codelldb prompts for the executable on every launch, starting from
  -- an empty box. These configurations remember the last path, so F5 + Enter
  -- re-runs like an IDE run configuration.
  codelldb = function(config)
    local dap = require "dap"
    local last_program

    local function pick_program()
      local program = vim.fn.input("Path to executable: ", last_program or (vim.fn.getcwd() .. "/"), "file")
      if program == nil or program == "" then
        return dap.ABORT
      end
      last_program = program
      return program
    end

    config.configurations = {
      {
        name = "LLDB: Launch",
        type = "codelldb",
        request = "launch",
        program = pick_program,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = {},
      },
      {
        name = "LLDB: Launch (with args)",
        type = "codelldb",
        request = "launch",
        program = pick_program,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
        args = function()
          return vim.split(vim.fn.input "Args: ", " +", { trimempty = true })
        end,
      },
    }

    require("mason-nvim-dap").default_setup(config)
  end,
}

return M
