-- clangd: C++, C, and the .h-for-both-languages case. Plus CMake (neocmakelsp).
local t = dofile(vim.fn.expand "$SMOKE_LUA/t.lua")
local root = os.getenv "SMOKE_FIXTURE"

t.force_load "nvim-lspconfig"

local function open(path)
  vim.cmd("edit " .. vim.fn.fnameescape(root .. "/" .. path))
  return vim.api.nvim_get_current_buf()
end

local function errors(diags)
  local n = 0
  for _, d in ipairs(diags) do
    if d.severity == vim.diagnostic.severity.ERROR then
      n = n + 1
    end
  end
  return n
end

local function messages(diags)
  local m = {}
  for _, d in ipairs(diags) do
    m[#m + 1] = (d.message:gsub("\n.*", ""))
  end
  return table.concat(m, " | ")
end

--- clangd pads completion labels for alignment (" total") and prefixes a bullet
--- on items that will insert a header ("•vector"). Normalise before matching.
local function labels(res)
  local out = {}
  for _, r in pairs(res or {}) do
    for _, item in ipairs((r.result and (r.result.items or r.result)) or {}) do
      out[#out + 1] = vim.trim((item.label:gsub("^•", "")))
    end
  end
  return out
end

vim.defer_fn(function()
  -- --------------------------------------------------- C++ source, valid ----
  t.guard("clangd-cpp", function()
    local buf = open "src/main.cpp"
    local client = t.wait_lsp "clangd"
    t.check("clangd attaches to .cpp", client ~= nil)
    if not client then
      return
    end

    -- Give clangd time to publish; then require the file to be clean. This is
    -- C++23 (std::print, std::expected, deducing this) compiled by CMake at 23.
    vim.wait(6000)
    local d = vim.diagnostic.get(buf)
    t.check("C++23 file is clean", errors(d) == 0, messages(d))

    local td = vim.lsp.util.make_text_document_params(buf)

    -- completion on a member of a class defined in the .h
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local target
    for i, l in ipairs(lines) do
      if l:match "acc%.add" then
        target = i - 1
      end
    end
    vim.api.nvim_buf_set_lines(buf, target, target, false, { "    acc.to" })
    vim.wait(3000)
    local got = labels(
      vim.lsp.buf_request_sync(
        buf,
        "textDocument/completion",
        { textDocument = td, position = { line = target, character = 10 } },
        8000
      )
    )
    t.check(
      "clangd completes class member declared in the .h",
      vim.tbl_contains(got, "total"),
      "acc.to -> " .. table.concat(got, ", ")
    )
    vim.cmd "edit!" -- discard the scratch edit

    -- hover
    local hov = vim.lsp.buf_request_sync(buf, "textDocument/hover", {
      textDocument = td,
      position = { line = 15, character = 20 },
    }, 5000)
    local got_hover = false
    for _, r in pairs(hov or {}) do
      if r.result and r.result.contents then
        got_hover = true
      end
    end
    t.check("clangd hover responds", got_hover)
  end)

  -- ------------------------------------- cross-file navigation into a .h ----
  t.guard("clangd-nav", function()
    local buf = open "src/main.cpp"
    t.wait_lsp "clangd"
    vim.wait(4000)
    local td = vim.lsp.util.make_text_document_params(buf)

    -- find `square(` and jump to its definition -- it lives in include/mathlib.h
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local lnum, col
    for i, l in ipairs(lines) do
      local c = l:find "mathlib::square"
      if c then
        lnum, col = i - 1, c + 9
      end
    end
    local def = vim.lsp.buf_request_sync(buf, "textDocument/definition", {
      textDocument = td,
      position = { line = lnum or 0, character = col or 0 },
    }, 8000)
    local target
    for _, r in pairs(def or {}) do
      local loc = r.result and (r.result[1] or r.result)
      if loc then
        target = vim.fn.fnamemodify(vim.uri_to_fname(loc.uri or loc.targetUri), ":t")
      end
    end
    t.check("go-to-definition crosses into include/mathlib.h", target == "mathlib.h", tostring(target))

    -- switchSourceHeader both ways
    local b2 = open "src/mathlib.cpp"
    t.wait_lsp "clangd"
    vim.wait(3000)
    local sh =
      vim.lsp.buf_request_sync(b2, "textDocument/switchSourceHeader", vim.lsp.util.make_text_document_params(b2), 6000)
    local hdr
    for _, r in pairs(sh or {}) do
      if r.result then
        hdr = vim.fn.fnamemodify(vim.uri_to_fname(r.result), ":t")
      end
    end
    t.check("switchSourceHeader mathlib.cpp -> mathlib.h", hdr == "mathlib.h", tostring(hdr))
  end)

  -- ------------------------------------------- .h opened directly as C++ ----
  -- The ambiguous case: .h used for both languages. clangd must infer C++ here
  -- from the .cpp translation units that include it.
  t.guard("h-as-cpp", function()
    local buf = open "include/mathlib.h"
    local client = t.wait_lsp "clangd"
    t.check("clangd attaches to C++ .h", client ~= nil)
    vim.wait(6000)
    local d = vim.diagnostic.get(buf)
    t.check("C++ .h parses as C++ (namespace/template/deducing-this ok)", errors(d) == 0, messages(d))
  end)

  -- --------------------------------------------- .h opened directly as C ----
  t.guard("h-as-c", function()
    local buf = open "include/util.h"
    t.wait_lsp "clangd"
    vim.wait(6000)
    local d = vim.diagnostic.get(buf)
    t.check("C .h is clean", errors(d) == 0, messages(d))
  end)

  -- ------------------------------------------------------------ C file ----
  -- Regression: -std=c++23 must not reach C. Previously every .c errored with
  -- "invalid argument '-std=c++23' not allowed with 'C'".
  t.guard("c-file", function()
    local buf = open "legacy/util.c"
    t.wait_lsp "clangd"
    vim.wait(6000)
    local d = vim.diagnostic.get(buf)
    t.check("C file has no -std=c++ error", t.count_matching(d, "not allowed with 'C'") == 0, messages(d))
    t.check("C file is clean", errors(d) == 0, messages(d))
  end)

  -- -------------------------------------------- diagnostics actually fire ----
  t.guard("cpp-diagnostics", function()
    local buf = open "scratch/broken.cpp"
    t.wait_lsp "clangd"
    local d = t.wait_diagnostics(buf, 12000)
    t.check("clangd reports errors in broken C++", errors(d) > 0, messages(d))
  end)

  -- -------------------------------------------------------------- CMake ----
  t.guard("cmake-lsp", function()
    local buf = open "CMakeLists.txt"
    local client = t.wait_lsp "neocmake"
    t.check("neocmakelsp attaches", client ~= nil)
    if not client then
      return
    end
    vim.wait(3000)
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, { "add_ex" })
    vim.wait(1500)
    local got = labels(vim.lsp.buf_request_sync(buf, "textDocument/completion", {
      textDocument = vim.lsp.util.make_text_document_params(buf),
      position = { line = 0, character = 6 },
    }, 8000))
    t.check("cmake completion (add_executable)", vim.tbl_contains(got, "add_executable"), #got .. " items")
    vim.cmd "edit!"
  end)

  -- ----------------------------------------- signature help and overloads ----
  -- Regression guard. configs/lspconfig.lua used to carry
  --     client.server_capabilities.signatureHelpProvider = false
  -- which silently removed the parameter list for every server -- no overloads
  -- on std:: constructors, nothing inside foo(|). Pure LSP requests, so this
  -- runs headless; the float itself is checked in ui.lua.
  t.guard("signature-help", function()
    local path = root .. "/scratch/sigtest.cpp"
    vim.fn.writefile({
      "#include <string>",
      "",
      "int add(int lhs, int rhs) { return lhs + rhs; }",
      "",
      "int main() {",
      '    std::string s("hi");',
      "    int r = add(1, 2);",
      "    return r + static_cast<int>(s.size());",
      "}",
    }, path)
    vim.cmd("edit! " .. vim.fn.fnameescape(path))
    local buf = vim.api.nvim_get_current_buf()
    local client = t.wait_lsp "clangd"
    t.check("clangd attaches to sigtest.cpp", client ~= nil)
    if not client then
      return
    end

    t.check(
      "clangd advertises signatureHelpProvider",
      client.server_capabilities.signatureHelpProvider ~= nil,
      "lspconfig.lua must not disable it"
    )

    vim.wait(4000)
    local td = vim.lsp.util.make_text_document_params(buf)
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

    --- Cursor position just past the "(" of the first line containing `needle`.
    --- Computed rather than hardcoded so re-indenting the fixture cannot break
    --- the probe into a silent pass.
    local function sigs(needle)
      local lnum, col
      for i, l in ipairs(lines) do
        local c = l:find(needle, 1, true)
        if c then
          lnum, col = i - 1, c - 1 + #needle
          break
        end
      end
      if not lnum then
        return {}, "needle not found: " .. needle
      end
      local res = vim.lsp.buf_request_sync(buf, "textDocument/signatureHelp", {
        textDocument = td,
        position = { line = lnum, character = col },
      }, 8000)
      for _, r in pairs(res or {}) do
        if r.result and r.result.signatures then
          return r.result.signatures
        end
      end
      return {}
    end

    -- Constructor overloads. libc++ gives 26 here; assert plural rather than an
    -- exact count, which moves with the standard library version.
    local ctor = sigs "string s("
    t.check("std::string( offers multiple constructor overloads", #ctor > 1, #ctor .. " signatures")

    -- A plain function: one signature, and clangd suffixes the return type.
    -- Needle is "= add(", not "add(": the latter matches the DEFINITION on line
    -- 3 first, and clangd returns nothing inside a declaration's parameter list.
    local fn = sigs "= add("
    local label = fn[1] and fn[1].label or ""
    t.check("add( returns a signature", #fn > 0, label)
    t.check("clangd labels carry the return type as -> T", label:match "%->%s*int" ~= nil, label)
  end)

  -- ------------------------------------------------------------ inlay hints ----
  -- configs/inlayhints.lua enables these on LspAttach. clangd needs no
  -- server-side setting for ParameterNames/DeducedTypes; pyright does, and that
  -- is covered in python.lua.
  t.guard("inlay-hints", function()
    local buf = vim.api.nvim_get_current_buf() -- still sigtest.cpp
    t.check("inlay hints enabled on attach", vim.lsp.inlay_hint.is_enabled { bufnr = buf })

    local hints = t.wait_for(function()
      local h = vim.lsp.inlay_hint.get { bufnr = buf }
      return #h > 0 and h or nil
    end, 10000)

    local labels_got = {}
    for _, h in ipairs(hints or {}) do
      local l = h.inlay_hint.label
      labels_got[#labels_got + 1] = type(l) == "table" and (l[1] and l[1].value or "?") or tostring(l)
    end
    local joined = table.concat(labels_got, " ")

    t.check("clangd emits inlay hints", hints ~= nil and #hints > 0, joined)
    -- Parameter names at the call site (add(lhs: 1, rhs: 2)) and the deduced
    -- type on `auto` are the two kinds; the fixture exercises the first.
    t.check("parameter-name hints present", joined:match "lhs" ~= nil, joined)

    local ih = require "configs.inlayhints"
    ih.toggle()
    t.check("toggle turns inlay hints off", not vim.lsp.inlay_hint.is_enabled { bufnr = buf })
    ih.toggle()
    t.check("toggle turns them back on", vim.lsp.inlay_hint.is_enabled { bufnr = buf })
  end)

  t.guard("cmake-diagnostics", function()
    local buf = open "scratch/CMakeLists.txt"
    t.wait_lsp "neocmake"
    local d = t.wait_diagnostics(buf, 10000)
    t.check("cmake linting reports the malformed file", #d > 0, messages(d))
  end)

  t.finish()
end, 4000)
