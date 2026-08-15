-- pyright + ruff: attach, venv resolution, completion, navigation, diagnostics.
local t = dofile(vim.fn.expand "$SMOKE_LUA/t.lua")
local root = os.getenv "SMOKE_FIXTURE"

t.force_load "nvim-lspconfig"

local function open(path)
  vim.cmd("edit " .. vim.fn.fnameescape(root .. "/" .. path))
  return vim.api.nvim_get_current_buf()
end

local function by_source(diags)
  local out = {}
  for _, d in ipairs(diags) do
    local s = tostring(d.source)
    out[s] = (out[s] or 0) + 1
  end
  return out
end

--- Servers pad or decorate labels; normalise before matching.
local function labels(res)
  local out = {}
  for _, r in pairs(res or {}) do
    for _, item in ipairs((r.result and (r.result.items or r.result)) or {}) do
      out[#out + 1] = vim.trim(item.label)
    end
  end
  return out
end

local function messages(diags)
  local m = {}
  for _, d in ipairs(diags) do
    m[#m + 1] = string.format("[%s] %s", tostring(d.source), (d.message:gsub("\n.*", "")))
  end
  return table.concat(m, " | ")
end

vim.defer_fn(function()
  -- --------------------------------------------------- both servers attach ----
  t.guard("py-attach", function()
    open "py/app.py"
    local pyright = t.wait_lsp("pyright", 20000)
    local ruff = t.wait_lsp("ruff", 20000)
    t.check("pyright attaches", pyright ~= nil)
    t.check("ruff attaches", ruff ~= nil)
  end)

  -- ------------------------------------------------------ venv resolution ----
  -- app.py imports mydummypkg, which exists ONLY in py/.venv. Without the
  -- absolute venvPath + didChangeConfiguration this reports an unresolved
  -- import.
  t.guard("py-venv", function()
    local buf = open "py/app.py"
    t.wait_lsp("pyright", 20000)
    vim.wait(8000)
    local d = vim.diagnostic.get(buf)
    local unresolved = t.count_matching(d, "could not be resolved")
    t.check("venv-only import resolves", unresolved == 0, messages(d))
  end)

  -- ----------------------------------------------------------- completion ----
  t.guard("py-completion", function()
    local buf = open "py/app.py"
    t.wait_lsp("pyright", 20000)
    vim.wait(5000)
    -- complete a symbol from the sibling module
    vim.api.nvim_buf_set_lines(buf, 5, 5, false, { "sq = square" })
    vim.wait(1500)
    local got = labels(vim.lsp.buf_request_sync(buf, "textDocument/completion", {
      textDocument = vim.lsp.util.make_text_document_params(buf),
      position = { line = 5, character = 11 },
    }, 10000))
    t.check(
      "pyright completes local module symbol",
      vim.tbl_contains(got, "square"),
      "square from mathlib.py; got " .. #got .. " items"
    )
    vim.cmd "edit!"
  end)

  -- ----------------------------------------------------------- navigation ----
  t.guard("py-nav", function()
    local buf = open "py/app.py"
    t.wait_lsp("pyright", 20000)
    vim.wait(5000)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local lnum, col
    for i, l in ipairs(lines) do
      local c = l:find "square%(7%)"
      if c then
        lnum, col = i - 1, c + 1
      end
    end
    local def = vim.lsp.buf_request_sync(buf, "textDocument/definition", {
      textDocument = vim.lsp.util.make_text_document_params(buf),
      position = { line = lnum or 0, character = col or 0 },
    }, 10000)
    local target
    for _, r in pairs(def or {}) do
      local loc = r.result and (r.result[1] or r.result)
      if loc then
        target = vim.fn.fnamemodify(vim.uri_to_fname(loc.uri or loc.targetUri), ":t")
      end
    end
    t.check("go-to-definition app.py -> mathlib.py", target == "mathlib.py", tostring(target))
  end)

  -- ---------------------------------------------------------- diagnostics ----
  -- The mypy substitute: pyright must catch the type error, ruff the lint.
  t.guard("py-diagnostics", function()
    local buf = open "py/broken.py"
    t.wait_lsp("pyright", 20000)
    t.wait_lsp("ruff", 20000)
    local d = t.wait_diagnostics(buf, 15000)
    vim.wait(4000)
    d = vim.diagnostic.get(buf)
    local src = by_source(d)
    t.check("pyright reports the type error", (src.Pyright or 0) > 0, messages(d))
    t.check("ruff reports lint issues", (src.Ruff or 0) > 0, messages(d))
    t.check(
      "pyright catches str/int mismatch (the mypy substitute)",
      t.count_matching(d, "not assignable") > 0 or t.count_matching(d, "cannot be assigned") > 0,
      messages(d)
    )
    t.check("ruff flags the unused import", t.count_matching(d, "imported but unused") > 0, messages(d))
  end)

  -- ------------------------------------------------------------ inlay hints ----
  -- Python gets NONE, and that is a property of the server, not a bug here.
  -- Open-source pyright does not implement textDocument/inlayHint -- inlay
  -- hints are a Pylance / basedpyright feature. configs/inlayhints.lua guards
  -- on supports_method, so it correctly skips this buffer.
  --
  -- Asserted rather than skipped so this becomes a tripwire: if pyright ever
  -- ships inlay hints, this fails and the config can start enabling them.
  t.guard("py-inlay-hints", function()
    local buf = open "py/app.py"
    local client = t.wait_lsp("pyright", 20000)
    vim.wait(5000)
    if not client then
      t.check("pyright attached for the inlay hint check", false)
      return
    end

    t.check(
      "pyright still advertises no inlayHintProvider",
      not client:supports_method "textDocument/inlayHint",
      "basedpyright is the drop-in fork that does implement it"
    )
    t.check(
      "inlay hints correctly left off for python",
      not vim.lsp.inlay_hint.is_enabled { bufnr = buf },
      "supports_method guard in configs/inlayhints.lua"
    )
    -- Signature help is a different capability and pyright does have it.
    t.check("pyright advertises signatureHelpProvider", client.server_capabilities.signatureHelpProvider ~= nil)
  end)

  -- ------------------------------------------------------------ dap-python ----
  t.guard("py-dap", function()
    open "py/app.py"
    t.force_load "nvim-dap-python"
    vim.wait(2000)
    t.check("dap-python loads", pcall(require, "dap-python"))
    local cfgs = require("dap").configurations.python or {}
    t.check("python dap configurations registered", #cfgs > 0, string.format("%d configs", #cfgs))
    local debugpy = vim.fn.stdpath "data" .. "/mason/packages/debugpy/venv/bin/python"
    t.check("debugpy interpreter exists", vim.uv.fs_stat(debugpy) ~= nil, debugpy)
  end)

  t.finish()
end, 4000)
