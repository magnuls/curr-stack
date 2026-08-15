-- Tiny assertion helper shared by every probe.
--
-- Results go to a file rather than stdout: nvim's own output is unreliable to
-- parse (it interleaves plugin messages and terminal escapes), and a probe that
-- errors must still leave behind whatever it managed to check.

local M = {}

M.results = {}
local outfile = os.getenv "SMOKE_OUT" or "/tmp/smoke.out"

local function flush()
  local lines = {}
  for _, r in ipairs(M.results) do
    lines[#lines + 1] = string.format("%s\t%s\t%s", r.status, r.name, r.detail or "")
  end
  vim.fn.writefile(lines, outfile)
end

---@param name string
---@param ok boolean
---@param detail string|nil  shown on failure, or as context on pass
function M.check(name, ok, detail)
  M.results[#M.results + 1] = { status = ok and "PASS" or "FAIL", name = name, detail = detail }
  flush()
end

--- Diagnostic note. Not a check -- shown only to explain a nearby failure.
function M.trace(msg)
  M.results[#M.results + 1] = { status = "NOTE", name = msg }
  flush()
end

function M.skip(name, why)
  M.results[#M.results + 1] = { status = "SKIP", name = name, detail = why }
  flush()
end

--- Run body in pcall; a thrown error becomes a FAIL rather than a hung nvim.
function M.guard(name, body)
  local ok, err = pcall(body)
  if not ok then
    M.check(name, false, "error: " .. tostring(err))
  end
end

--- Wait until fn() is truthy, or timeout. Returns the value (or nil).
function M.wait_for(fn, timeout_ms, interval)
  local result
  vim.wait(timeout_ms or 15000, function()
    result = fn()
    return result ~= nil and result ~= false
  end, interval or 100)
  return result
end

--- Wait for an LSP client by name to attach to the current buffer.
function M.wait_lsp(name, timeout_ms)
  return M.wait_for(function()
    for _, c in ipairs(vim.lsp.get_clients { bufnr = 0 }) do
      if c.name == name then
        return c
      end
    end
  end, timeout_ms)
end

--- Wait until diagnostics settle: non-empty, or the timeout expires.
function M.wait_diagnostics(bufnr, timeout_ms)
  M.wait_for(function()
    return #vim.diagnostic.get(bufnr) > 0 or nil
  end, timeout_ms or 12000)
  return vim.diagnostic.get(bufnr)
end

--- Count diagnostics whose message matches a pattern.
function M.count_matching(diags, pattern)
  local n = 0
  for _, d in ipairs(diags) do
    if d.message:match(pattern) then
      n = n + 1
    end
  end
  return n
end

--- Run steps in sequence, yielding to the event loop between each.
---
--- Keys sent with nvim_input are only consumed once control returns to the main
--- loop. vim.wait() does not reliably do that for pending insert-mode input, so
--- anything driving real keystrokes has to be split across defer_fn callbacks.
---@param steps table  list of { ms, fn } pairs
function M.chain(steps, done)
  local i = 0
  local function next_step()
    i = i + 1
    local step = steps[i]
    if not step then
      return (done or function() end)()
    end
    vim.defer_fn(function()
      local ok, err = pcall(step[2])
      if not ok then
        M.check("chain step " .. i, false, tostring(err))
      end
      next_step()
    end, step[1])
  end
  next_step()
end

function M.finish()
  flush()
  vim.cmd "qa!"
end

--- NvChad lazy-loads nvim-lspconfig on "User FilePost", which only fires after
--- UIEnter -- never in --headless. Force it.
---
--- Uses lazy's Lua API, not `:Lazy! load`: the command form is ambiguous once
--- lazygit.nvim registers :LazyGit* stubs, and fails with
---   E464: Ambiguous use of user-defined command
function M.force_load(...)
  vim.g.ui_entered = true
  local plugins = { ... }
  local ok, lazy = pcall(require, "lazy")
  if ok then
    pcall(lazy.load, { plugins = plugins })
  end
end

return M
