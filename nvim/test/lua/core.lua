-- Startup, options, keymaps, treesitter. No LSP -- that lives in the language probes.
local t = dofile(vim.fn.expand "$SMOKE_LUA/t.lua")

t.force_load("nvim-treesitter", "nvim-tree.lua", "nvim-cmp", "vim-tmux-navigator", "lazygit.nvim", "telescope.nvim")

vim.defer_fn(function()
  -- ---------------------------------------------------------------- UI ----
  t.guard("ui", function()
    local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    t.check(
      "theme is tokyonight",
      require("nvconfig").base46.theme == "tokyonight" and normal.bg == 0x1a1b26,
      string.format("Normal.bg=#%06x (alacritty tokyo_night uses #1a1b26)", normal.bg or 0)
    )
    t.check("hybrid line numbers", vim.o.number and vim.o.relativenumber, "number+relativenumber")
    t.check("statusline set", (vim.o.statusline or ""):find "nvchad" ~= nil, vim.o.statusline)
  end)

  -- ----------------------------------------------------------- keymaps ----
  -- Assert what each key DOES, not merely that something is bound.
  t.guard("keymaps", function()
    -- maparg is picky about notation: function keys want the literal "<F5>",
    -- while some others only match once termcodes are replaced. Try both.
    local function rhs_of(lhs)
      local info = vim.fn.maparg(lhs, "n", false, true)
      if not info or not next(info) then
        info = vim.fn.maparg(vim.api.nvim_replace_termcodes(lhs, true, true, true), "n", false, true)
      end
      if not info or not next(info) then
        return nil
      end
      return info.rhs or (info.callback and "<lua>" or ""), info.desc
    end

    local expect_desc = {
      ["<F5>"] = "Debug: Start/Continue",
      ["<F1>"] = "Debug: Step Into",
      ["<F2>"] = "Debug: Step Over",
      ["<F3>"] = "Debug: Step Out",
      ["<F7>"] = "Debug: See last session result",
      ["<leader>b"] = "Debug: Toggle Breakpoint",
      ["<leader>B"] = "Debug: Set Conditional Breakpoint",
      ["<leader>dpr"] = "Debug: Python test method",
      ["\\"] = "nvimtree reveal / close",
      ["<leader>ih"] = "lsp: toggle inlay hints",
    }
    for lhs, want in pairs(expect_desc) do
      local _, desc = rhs_of(lhs)
      t.check("map " .. lhs, desc == want, string.format("desc=%s (want %s)", tostring(desc), want))
    end

    -- tmux navigation must beat NvChad's plain <C-w>h
    for _, k in ipairs { "<C-h>", "<C-j>", "<C-k>", "<C-l>" } do
      local rhs = rhs_of(k)
      t.check("map " .. k .. " -> tmux", (rhs or ""):match "TmuxNavigate" ~= nil, tostring(rhs))
    end

    -- lazygit + the diagnostics picker
    for lhs, want in pairs {
      ["<leader>gg"] = "LazyGit",
      ["<leader>gf"] = "LazyGitFilterCurrentFile",
      ["<leader>fd"] = "Telescope diagnostics",
    } do
      local rhs = rhs_of(lhs)
      t.check("map " .. lhs, (rhs or ""):match(want) ~= nil, tostring(rhs))
    end

    -- NvChad defaults that must survive
    for _, k in ipairs { "<C-n>", "<leader>ff", "<leader>fw", "<leader>fm", "<leader>ch", "<leader>e" } do
      t.check("nvchad map " .. k, rhs_of(k) ~= nil, "still bound")
    end

    t.check("; -> :", rhs_of ";" == ":", "command mode")
    local ins = vim.fn.maparg("jk", "i", false, true)
    t.check("jk -> Esc (insert)", ins and next(ins) ~= nil, "insert-mode escape")
  end)

  -- -------------------------------------------------------- completion ----
  t.guard("cmp", function()
    local mapping = require("cmp").get_config().mapping
    -- cmp normalises control keys to uppercase
    for _, k in ipairs { "<C-Y>", "<CR>", "<Tab>", "<S-Tab>", "<C-N>", "<C-P>", "<C-Space>", "<C-E>" } do
      t.check("cmp " .. k, mapping[k] ~= nil, "bound")
    end
  end)

  -- -------------------------------------------------------- treesitter ----
  t.guard("treesitter", function()
    local installed = require("nvim-treesitter").get_installed "parsers"
    for _, p in ipairs { "c", "cpp", "cmake", "python", "lua" } do
      t.check("parser " .. p, vim.tbl_contains(installed, p), table.concat(installed, " "))
    end
  end)

  -- Highlighter must actually activate per filetype (the `main` branch needs
  -- vim.treesitter.start() called by hand; ensure_installed is a no-op there).
  local root = os.getenv "SMOKE_FIXTURE"
  local samples = {
    cpp = root .. "/src/main.cpp",
    c = root .. "/legacy/util.c",
    cmake = root .. "/CMakeLists.txt",
    python = root .. "/py/app.py",
    lua = root .. "/mangled.lua",
  }
  for ft, path in pairs(samples) do
    t.guard("ts-hl-" .. ft, function()
      vim.cmd("edit " .. vim.fn.fnameescape(path))
      local buf = vim.api.nvim_get_current_buf()
      local active = t.wait_for(function()
        return vim.treesitter.highlighter.active[buf] ~= nil or nil
      end, 5000)
      t.check(
        "treesitter highlight: " .. ft,
        active == true and vim.bo.filetype == ft,
        string.format("filetype=%s", vim.bo.filetype)
      )
    end)
  end

  -- ------------------------------------------------------------ indent ----
  t.guard("indent", function()
    vim.cmd("edit " .. vim.fn.fnameescape(root .. "/src/main.cpp"))
    t.check(
      "cpp indent width 4",
      vim.bo.shiftwidth == 4 and vim.bo.tabstop == 4 and vim.bo.softtabstop == 4 and vim.bo.smartindent == false,
      string.format(
        "sw=%d ts=%d sts=%d smartindent=%s",
        vim.bo.shiftwidth,
        vim.bo.tabstop,
        vim.bo.softtabstop,
        tostring(vim.bo.smartindent)
      )
    )
    -- `o` on a brace line must open a block at 4, matching .clang-format
    vim.cmd "enew"
    vim.bo.filetype = "cpp"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "int main() {", "}" })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd "normal! oint y = 1;"
    local line = vim.api.nvim_buf_get_lines(0, 1, 2, false)[1] or ""
    t.check("cpp `o` indents 4", #(line:match "^ *") == 4, string.format("[%s]", line))

    vim.cmd("edit " .. vim.fn.fnameescape(root .. "/mangled.lua"))
    t.check("lua indent stays 2", vim.bo.shiftwidth == 2, "sw=" .. vim.bo.shiftwidth)
  end)

  -- --------------------------------------------------------------- dap ----
  t.guard("dap-wiring", function()
    t.force_load("nvim-dap", "mason-nvim-dap.nvim", "nvim-dap-ui")
    local dap = require "dap"
    t.check("codelldb adapter registered", dap.adapters.codelldb ~= nil)
    local cpp = dap.configurations.cpp or {}
    t.check(
      "codelldb remembers last program",
      #cpp == 2 and type(cpp[1].program) == "function",
      string.format("%d configs", #cpp)
    )
    t.check("dapui listeners installed", dap.listeners.after.event_initialized["dapui_config"] ~= nil)
  end)

  t.finish()
end, 4000)
