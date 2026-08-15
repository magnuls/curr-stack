-- Diagnostic display filtering. Applied from configs/lspconfig.lua, toggled by
-- <leader>dt in mappings.lua.
--
-- Two levels: errors only (the default) and everything. Errors-only means
-- literally what would fail the build -- every clang-tidy finding and every
-- -Wall/-Wextra warning is WARN severity, so this hides all of them. That is
-- the point: --clang-tidy stays on and stays quiet until you want a cleanup
-- pass. It also means the toggle is all-or-nothing; per-check suppression
-- belongs in the project's .clang-tidy, not here.

local M = {}
local S = vim.diagnostic.severity

M.errors_only = true

-- vim.diagnostic.config() REPLACES per key, it does not merge -- see the bare
-- `t[k] = v` loop in runtime/lua/vim/diagnostic.lua. So each handler is read
-- back and only `severity` is added. Passing a bare { severity = ... } would
-- delete NvChad's sign icons and its virtual_text prefix.
local function with_severity(current, filter)
  if current == false then
    -- Deliberately disabled. Returning a table here would switch it back on.
    return false
  end
  local t = type(current) == "table" and vim.deepcopy(current) or {}
  t.severity = filter
  return t
end

-- nvim-tree dereferences severity.min at render time (is_severity_in_range in
-- nvim-tree/diagnostics.lua), so mutating the live config and reloading is
-- enough -- the toggle does not need a restart.
local function apply_tree(min)
  local ok, ntconf = pcall(require, "nvim-tree.config")
  if not ok then
    return
  end
  ntconf.g.diagnostics.severity.min = min

  local ok_api, api = pcall(require, "nvim-tree.api")
  if ok_api then
    pcall(api.tree.reload)
  end
end

function M.apply()
  local min = M.errors_only and S.ERROR or S.HINT
  local filter = { min = min }

  -- Read back every time, so apply() is idempotent and toggling repeatedly
  -- cannot accumulate stale keys.
  local cur = vim.diagnostic.config() or {}

  vim.diagnostic.config {
    signs = with_severity(cur.signs, filter),
    underline = with_severity(cur.underline, filter),
    virtual_text = with_severity(cur.virtual_text, filter),
    -- ]d / [d honour this; without it they would still step hidden warnings.
    jump = vim.tbl_extend("force", type(cur.jump) == "table" and cur.jump or {}, { severity = filter }),
  }

  apply_tree(min)
end

function M.toggle()
  M.errors_only = not M.errors_only
  M.apply()
  vim.notify(
    M.errors_only and "Diagnostics: errors only" or "Diagnostics: all severities",
    vim.log.levels.INFO
  )
end

return M
