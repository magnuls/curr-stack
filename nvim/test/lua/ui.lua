-- PTY-only: things that need a real UI attached.
-- cmp draws a floating window and lazygit needs a terminal, so neither works
-- under --headless. Run via: script -q /dev/null nvim ...
--
-- Real keystrokes go through nvim_input, which is only consumed when control
-- returns to the main loop -- hence t.chain() rather than vim.wait() between
-- them. vim.wait does not flush pending insert-mode input.
local t = dofile(vim.fn.expand "$SMOKE_LUA/t.lua")
local root = os.getenv "SMOKE_FIXTURE"

local function tree_buf()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].filetype == "NvimTree" then
      return b
    end
  end
end

local function rendered(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
end

-- ------------------------- completion menu + <C-y> + auto-include ----------
local function test_cmp(done)
  local path = root .. "/scratch/cmptest.cpp"
  vim.fn.writefile({ "#include <string>", "", "int main() {", '    std::string s = "hi";', "    return 0;", "}" }, path)
  vim.cmd("edit! " .. vim.fn.fnameescape(path))
  local client = t.wait_lsp("clangd", 25000)
  t.check("clangd attaches in pty session", client ~= nil)

  t.chain({
    {
      6000,
      function()
        vim.api.nvim_win_set_cursor(0, { 4, 24 })
        vim.api.nvim_input "o"
      end,
    },
    {
      1500,
      function()
        vim.api.nvim_input "std::vec"
      end,
    },
    {
      4000,
      function()
        local cmp = require "cmp"
        -- Synthetic input bursts don't always trip cmp's debounced auto-trigger;
        -- ask explicitly so this tests confirm-and-apply, not the debounce.
        if not cmp.visible() then
          cmp.complete()
        end
      end,
    },
    {
      3000,
      function()
        local cmp = require "cmp"
        local entries = cmp.get_entries()
        t.check("cmp menu populates for clangd", #entries > 0, string.format("%d entries", #entries))
        local first = entries[1] and entries[1]:get_completion_item()
        t.check(
          "clangd offers the header-insert edit",
          first ~= nil and first.additionalTextEdits ~= nil and #first.additionalTextEdits > 0,
          first and first.label or "no entries"
        )
        vim.api.nvim_input "<C-y>"
      end,
    },
    {
      2500,
      function()
        vim.api.nvim_input "<Esc>"
      end,
    },
    {
      1500,
      function()
        local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
        t.check("<C-y> accepts the completion", text:match "std::vector" ~= nil, text:gsub("\n", "|"))
        t.check("accepting auto-inserts #include <vector>", text:match "#include <vector>" ~= nil, text:gsub("\n", "|"))
      end,
    },
  }, done)
end

-- ------------------------------------------------- signature help float ----
-- The float itself, not the LSP response -- cpp.lua already covers the wire
-- protocol. lsp_signature draws a real floating window, so this is pty-only.
--
-- Checks the CLion behaviour specifically: it must appear from typing "(" with
-- no key pressed to summon it.
local function test_signature(done)
  local path = root .. "/scratch/sigfloat.cpp"
  vim.fn.writefile({
    "#include <string>",
    "",
    "int main() {",
    "    return 0;",
    "}",
  }, path)
  vim.cmd "silent! only"
  vim.cmd("edit! " .. vim.fn.fnameescape(path))
  local client = t.wait_lsp("clangd", 25000)
  t.check("clangd attaches for the signature float", client ~= nil)

  --- Any floating window other than the current one, plus its rendered text.
  local function float_text()
    local cur = vim.api.nvim_get_current_win()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if w ~= cur and vim.api.nvim_win_get_config(w).relative ~= "" then
        return rendered(vim.api.nvim_win_get_buf(w))
      end
    end
  end

  t.chain({
    {
      6000,
      function()
        vim.api.nvim_win_set_cursor(0, { 3, 12 })
        vim.api.nvim_input "o"
      end,
    },
    {
      1500,
      function()
        -- Typing the "(" is the trigger. Nothing is pressed to summon the float.
        vim.api.nvim_input "std::string s("
      end,
    },
    {
      5000,
      function()
        local text = float_text()
        t.check("signature float opens by itself on (", text ~= nil, text and text:gsub("\n", " | ") or "no float")
        t.check(
          "float shows a std::string constructor",
          text ~= nil and text:match "basic_string" ~= nil,
          text and text:gsub("\n", " | ") or "no float"
        )
        vim.g.smoke_sig_first = (text or ""):match "[^\n]*"

        -- Cycling is checked by calling the plugin, NOT by sending the key.
        -- nvim_input cannot deliver every keycode, and asserting on delivery
        -- here would make this probe fail whenever the key is rebound. That the
        -- key is bound at all is asserted separately below.
        require("lsp_signature").signature { trigger = "NextSignature" }
      end,
    },
    {
      3000,
      function()
        local first = ((float_text() or ""):match "[^\n]*")
        t.check(
          "cycling moves to a different overload",
          first ~= nil and first ~= vim.g.smoke_sig_first,
          string.format("before=%s after=%s", tostring(vim.g.smoke_sig_first), tostring(first))
        )

        -- The insert-mode cycle key must exist and point at lsp_signature.
        -- Read it from the plugin config so rebinding the key does not require
        -- editing this probe.
        local key = _LSP_SIG_CFG and _LSP_SIG_CFG.select_signature_key
        t.check("a cycle key is configured", key ~= nil, tostring(key))
        if key then
          local m = vim.fn.maparg(key, "i", false, true)
          t.check(
            "cycle key is bound in insert mode",
            m and next(m) ~= nil and (m.desc or ""):match "select signature" ~= nil,
            string.format("%s -> %s", key, tostring(m and m.desc))
          )
        end
        vim.api.nvim_input "<Esc>"
      end,
    },
    { 1500, function() end },
  }, done)
end

-- ------------------------------------------------------------- file tree ---
local function test_tree(done)
  vim.cmd "silent! only"
  vim.cmd("edit! " .. vim.fn.fnameescape(root .. "/src/main.cpp"))
  vim.cmd "Lazy! load nvim-tree.lua"

  t.chain({
    {
      1000,
      function()
        vim.cmd "NvimTreeFocus"
      end,
    },
    {
      2500,
      function()
        local buf = tree_buf()
        t.check("file tree opens", buf ~= nil)
        if buf then
          t.check(
            "dotfiles hidden by default",
            rendered(buf):match "%.gitignore" == nil,
            rendered(buf):gsub("\n", " | ")
          )
        end
        -- press H, the real key, rather than calling the api directly
        vim.api.nvim_input "H"
      end,
    },
    {
      2000,
      function()
        local buf = tree_buf()
        t.check(
          "H reveals dotfiles",
          buf and rendered(buf):match "%.gitignore" ~= nil,
          buf and rendered(buf):gsub("\n", " | ")
        )
        vim.api.nvim_input "H"
      end,
    },
    {
      1500,
      function()
        local buf = tree_buf()
        local maps = {}
        for _, m in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
          maps[m.lhs] = m.desc or ""
        end
        t.check("tree `s` = vertical split", (maps["s"] or ""):match "Vertical Split" ~= nil, maps["s"])
        t.check("tree `S` = horizontal split", (maps["S"] or ""):match "Horizontal Split" ~= nil, maps["S"])
        t.check(
          "tree defaults preserved",
          maps["<C-V>"] ~= nil and maps["g?"] ~= nil and maps["a"] ~= nil,
          "default maps intact"
        )

        -- land on a file that is not already displayed, then press `s`
        local api = require "nvim-tree.api"
        for _ = 1, 30 do
          local node = api.tree.get_node_under_cursor()
          if node and node.type == "file" and node.name ~= "main.cpp" then
            break
          end
          vim.cmd "normal! j"
        end
        vim.g.smoke_wins_before = #vim.api.nvim_list_wins()
        vim.api.nvim_input "s"
      end,
    },
    {
      2000,
      function()
        local after = #vim.api.nvim_list_wins()
        t.check(
          "tree `s` opens a real vertical split",
          after == vim.g.smoke_wins_before + 1,
          string.format("%d -> %d windows", vim.g.smoke_wins_before, after)
        )
      end,
    },
  }, done)
end

-- --------------------------------------------------------------- lazygit ---
local function test_lazygit(done)
  t.chain({
    {
      500,
      function()
        vim.cmd "silent! only"
        vim.cmd("edit! " .. vim.fn.fnameescape(root .. "/src/main.cpp"))
      end,
    },
    {
      1000,
      function()
        vim.api.nvim_input " gg" -- <leader>gg
      end,
    },
    {
      8000,
      function()
        local term
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.bo[b].buftype == "terminal" and vim.api.nvim_buf_get_name(b):match "lazygit" then
            term = b
          end
        end
        t.check("<leader>gg spawns lazygit", term ~= nil)
        if term then
          local text = rendered(term)
          t.check(
            "lazygit renders its panels",
            text:match "Status" ~= nil and text:match "Files" ~= nil,
            "chars=" .. #text
          )
          t.check("lazygit sees the fixture branch", text:match "feature" ~= nil, "branch panel")
        end
        vim.api.nvim_input "q"
      end,
    },
    { 2000, function() end },
  }, done)
end

-- --------------------------------------------------- diagnostics picker ---
-- A keymap can resolve and still blow up on invoke, so press the key and check
-- a populated picker actually appears.
local function test_diag_picker(done)
  t.chain({
    {
      500,
      function()
        vim.cmd "silent! only"
        vim.cmd("edit! " .. vim.fn.fnameescape(root .. "/scratch/broken.cpp"))
      end,
    },
    {
      9000,
      function()
        t.check("broken.cpp has diagnostics to list", #vim.diagnostic.get(0) > 0, "prerequisite")
        vim.api.nvim_input " fd" -- <leader>fd
      end,
    },
    {
      4000,
      function()
        local prompt, results
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          local ft = vim.bo[b].filetype
          if ft == "TelescopePrompt" then
            prompt = b
          elseif ft == "TelescopeResults" then
            results = b
          end
        end
        t.check("<leader>fd opens the telescope diagnostics picker", prompt ~= nil, "TelescopePrompt buffer")
        if results then
          local lines = vim.api.nvim_buf_get_lines(results, 0, -1, false)
          local nonempty = 0
          for _, l in ipairs(lines) do
            if vim.trim(l) ~= "" then
              nonempty = nonempty + 1
            end
          end
          t.check("picker lists the diagnostics", nonempty > 0, nonempty .. " rows")
        end
        vim.api.nvim_input "<Esc>"
      end,
    },
    { 1500, function() end },
  }, done)
end

vim.defer_fn(function()
  t.check("real UI attached", #vim.api.nvim_list_uis() > 0, "prerequisite for this probe")
  test_cmp(function()
    test_signature(function()
      test_tree(function()
        test_diag_picker(function()
          test_lazygit(function()
            t.finish()
          end)
        end)
      end)
    end)
  end)
end, 5000)
