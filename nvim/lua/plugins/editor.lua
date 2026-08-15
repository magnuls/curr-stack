-- Editing experience: syntax, file tree, completion, window navigation.
-- None of this is C++-specific; the C/C++ toolchain lives in cpp.lua.

return {
  -- Syntax / parsers -------------------------------------------------------
  -- nvim-treesitter's default branch is now `main`, a rewrite whose setup()
  -- takes ONLY install_dir -- `ensure_installed` is silently ignored, NvChad's
  -- included, so the stock config installs zero parsers. Neovim 0.12 bundles
  -- c/lua/markdown/query/vim/vimdoc but NOT cpp, so C++ gets no highlighting
  -- at all. Hence the explicit install() + vim.treesitter.start() below.
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local ts = require "nvim-treesitter"
      ts.setup {}

      local want = { "c", "cpp", "cmake", "python", "lua", "luadoc", "printf", "vim", "vimdoc" }
      local installed = ts.get_installed "parsers"
      local missing = vim.tbl_filter(function(p)
        return not vim.tbl_contains(installed, p)
      end, want)
      if #missing > 0 then
        ts.install(missing)
      end

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TSStart", { clear = true }),
        pattern = want,
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },

  -- File tree --------------------------------------------------------------
  {
    "nvim-tree/nvim-tree.lua",
    opts = function(_, opts)
      -- NvChad ships dotfiles = false, i.e. *show* them. Hide the clutter;
      -- H toggles dotfiles, I toggles git-ignored.
      opts.filters = vim.tbl_deep_extend("force", opts.filters or {}, {
        dotfiles = true,
        git_ignored = true,
      })

      -- nvim-tree ships diagnostics off. Note these come from vim.diagnostic,
      -- which only has data for LOADED buffers -- a broken file you have not
      -- opened still shows nothing. Marks land in the tree's signcolumn, so
      -- they do not collide with the git glyphs (git_placement = "before").
      opts.diagnostics = vim.tbl_deep_extend("force", opts.diagnostics or {}, {
        enable = true,
        -- Roll a child's worst diagnostic up onto a COLLAPSED folder; an
        -- expanded one would just duplicate what is already visible.
        show_on_dirs = true,
        show_on_open_dirs = false,
        -- Errors only, matching configs/diagnostics.lua. Set here too so
        -- startup is consistent whichever loads first; <leader>dt then moves
        -- this and vim.diagnostic's floor together at runtime.
        severity = { min = vim.diagnostic.severity.ERROR },
      })

      -- nvim-tree binds `s` to "Run System", which shells out to `open` and
      -- launches a Mac app. Restore neo-tree's meaning: s = vsplit, S = hsplit.
      opts.on_attach = function(bufnr)
        local api = require "nvim-tree.api"
        -- Defaults FIRST; calling this after would undo the overrides.
        api.map.on_attach.default(bufnr)

        local function o(desc)
          return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
        end
        vim.keymap.set("n", "s", api.node.open.vertical, o "Open: Vertical Split")
        vim.keymap.set("n", "S", api.node.open.horizontal, o "Open: Horizontal Split")
      end
      return opts
    end,
  },

  -- Completion -------------------------------------------------------------
  -- NvChad binds <CR> but not <C-y>, so <C-y> fell through to Vim's builtin
  -- "copy char from line above". Confirming is also what applies clangd's
  -- additionalTextEdits, i.e. the auto-#include.
  --
  -- opts must be a FUNCTION mutating the merged table; assigning a fresh
  -- `mapping` would discard <Tab>, <CR> and the rest.
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require "cmp"
      opts.mapping["<C-y>"] = cmp.mapping.confirm { select = true }
      return opts
    end,
  },

  -- Signature help ---------------------------------------------------------
  -- The parameter list that pops up inside foo(|) -- CLion's "Parameter Info".
  -- Neovim 0.12 renders this natively and even cycles overloads, but only on
  -- demand (insert <C-S>) and its cycle key is buffer-local to the float and
  -- normal-mode only, so you cannot page through std::string's 12 constructors
  -- without leaving insert mode. This plugin is what makes it automatic.
  --
  -- Prerequisite: configs/lspconfig.lua no longer kills signatureHelpProvider.
  --
  -- VeryLazy, NOT LspAttach: setup() registers its own LspAttach autocmd, so
  -- loading it on LspAttach would miss the client that just attached. VeryLazy
  -- fires on UIEnter, ahead of NvChad's "User FilePost" that loads lspconfig.
  {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    opts = {
      bind = true, -- required for handler_opts.border to apply
      handler_opts = { border = "rounded" },
      floating_window = true,
      -- Above the line, like CLion, so it does not sit on top of the argument
      -- you are typing.
      floating_window_above_cur_line = true,
      -- Reposition the signature float around cmp's menu when both are up.
      -- Default is already true; set explicitly because this is the setting
      -- that answers the "signature popup fights the completion menu" problem
      -- upstream solved by disabling signature help outright. It moves the
      -- float out of the way -- it does not hide it.
      check_completion_visible = true,
      -- The `<- param` virtual text. Off: inlay hints (configs/inlayhints.lua)
      -- already annotate this line, and two sets of virtual text on one line is
      -- unreadable.
      hint_enable = false,
      hi_parameter = "LspSignatureActiveParameter", -- base46 defines it already
      max_height = 12,
      max_width = 100,
      wrap = true,
      doc_lines = 3,
      -- Cycle overloads without leaving insert mode -- the thing native cannot
      -- do (its <C-s> is buffer-local to the float and normal-mode only).
      --
      -- <C-q> costs nothing: its only insert-mode meaning is "insert literal
      -- character", a duplicate of <C-v>, which still works.
      --
      -- Do NOT use <C-\> here. Neovim's input layer treats CTRL-\ as a prefix
      -- awaiting CTRL-N/G/O, so a lone <C-\> mapping never fires -- verified by
      -- feeding a raw 0x1C byte through a pty. It registers fine and silently
      -- does nothing, which is the worst possible failure mode.
      select_signature_key = "<C-q>",
      timer_interval = 100,
    },
  },

  -- Window / tmux navigation -----------------------------------------------
  -- Its own <C-h/j/k/l> maps are set at load time, before NvChad's
  -- vim.schedule'd mappings.lua -- which would then overwrite them. Disable
  -- them here and set them in mappings.lua, where they land last.
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
  },
}
