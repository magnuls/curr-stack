-- PTY-only: live debug sessions for C++ (codelldb) and Python (debugpy),
-- driven through the real keymaps.
--
-- Keystrokes are chained via t.chain, not vim.wait: nvim_input is only consumed
-- once control returns to the main loop.
--
-- macOS gates codelldb behind `sudo DevToolsSecurity -enable`. When disabled the
-- symptom is distinctive -- the session initializes, the breakpoint verifies,
-- and then nothing happens. That is reported as a FAIL with the cause.
local t = dofile(vim.fn.expand "$SMOKE_LUA/t.lua")
local root = os.getenv "SMOKE_FIXTURE"

local function count_breakpoints()
  local n = 0
  for _, list in pairs(require("dap.breakpoints").get() or {}) do
    n = n + #list
  end
  return n
end

--- One debug session, start to finish.
---@param label string
---@param file string             path relative to the fixture root
---@param pattern string          lua pattern locating the breakpoint line
---@param launch function         starts the session
---@param done function
local function session(label, file, pattern, launch, done)
  local state = { stopped = false }
  local dap = require "dap"

  dap.listeners.after.event_stopped["smoke"] = function()
    state.stopped = true
    local s = dap.session()
    if s and s.current_frame then
      state.line, state.frame = s.current_frame.line, s.current_frame.name
    end
  end

  t.chain({
    {
      500,
      function()
        vim.cmd "silent! only"
        vim.cmd("edit! " .. vim.fn.fnameescape(root .. "/" .. file))
      end,
    },

    {
      1500,
      function()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        for i, l in ipairs(lines) do
          if l:match(pattern) then
            state.target = i
            break
          end
        end
        if state.target then
          vim.api.nvim_win_set_cursor(0, { state.target, 0 })
          vim.api.nvim_input " b" -- <leader>b
        end
      end,
    },

    {
      2000,
      function()
        t.check(
          label .. ": <leader>b sets a breakpoint",
          count_breakpoints() > 0,
          string.format("line %s in %s", tostring(state.target), file)
        )
        launch()
      end,
    },

    -- generous: codelldb has to spawn debugserver, debugpy has to import
    {
      25000,
      function()
        t.check(
          label .. ": stops at the breakpoint",
          state.stopped,
          state.stopped and string.format("frame=%s line=%s", tostring(state.frame), tostring(state.line))
            or "never stopped"
        )
        if state.stopped then
          state.before = state.line
          vim.api.nvim_input "<F2>" -- step over
        end
      end,
    },

    {
      4000,
      function()
        if state.stopped then
          local s = dap.session()
          local after = s and s.current_frame and s.current_frame.line
          t.check(
            label .. ": <F2> steps to the next line",
            after ~= nil and after ~= state.before,
            string.format("line %s -> %s", tostring(state.before), tostring(after))
          )
        end
        dap.listeners.after.event_stopped["smoke"] = nil
        pcall(dap.terminate)
        -- clear breakpoints so the next session starts clean
        pcall(function()
          require("dap.breakpoints").clear()
        end)
      end,
    },

    {
      4000,
      function()
        t.check(label .. ": session terminates", require("dap").session() == nil, "no session left running")
      end,
    },
  }, done)
end

vim.defer_fn(function()
  t.check("real UI attached", #vim.api.nvim_list_uis() > 0)
  t.force_load("nvim-dap", "mason-nvim-dap.nvim", "nvim-dap-ui", "nvim-dap-python")

  vim.defer_fn(function()
    local dap = require "dap"

    -- Surface what the adapter actually reports; a silent failure is the
    -- symptom this probe most needs to explain rather than just fail on.
    dap.listeners.after.event_output["smoke"] = function(_, body)
      if body and body.output then
        t.trace("adapter: " .. (body.output:gsub("%s+$", "")))
      end
    end
    dap.listeners.after.event_terminated["smoke"] = function()
      t.trace "adapter: terminated"
    end

    session("C++", "src/main.cpp", "acc%.add", function()
      -- Bypass the interactive executable prompt so the run is deterministic;
      -- the prompt itself is covered by the codelldb config check in core.lua.
      dap.run {
        name = "smoke-cpp",
        type = "codelldb",
        request = "launch",
        program = root .. "/build/app",
        cwd = root,
        stopOnEntry = false,
        args = {},
        console = "internalConsole",
      }
    end, function()
      session("Python", "py/app.py", "acc%.add", function()
        dap.run {
          name = "smoke-py",
          type = "python",
          request = "launch",
          program = root .. "/py/app.py",
          cwd = root .. "/py",
          console = "internalConsole",
          pythonPath = root .. "/py/.venv/bin/python",
        }
      end, function()
        t.finish()
      end)
    end)
  end, 3000)
end, 5000)
