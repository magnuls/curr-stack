-- Language servers. Spec: plugins/cpp.lua.
-- Servers are installed by mason-tool-installer, not from here.

require("nvchad.configs.lspconfig").defaults()

-- clangd ---------------------------------------------------------------------
-- vim.lsp.config + vim.lsp.enable is the Neovim 0.11 API NvChad v2.5 uses;
-- upstream's lspconfig.clangd.setup{} is the older one.
vim.lsp.config("clangd", {
  -- Defaults leave clangd frontend-only and open-buffers-only. Both flags are
  -- built into clangd 22.x, so there is nothing extra to install.
  --   --background-index: index the whole project, not just open files.
  --     Without it grr and grn silently miss uses in unopened files, so a
  --     rename can half-apply with no warning.
  --   --clang-tidy: bug patterns -Wall/-Wextra cannot see (use-after-move,
  --     missing override, narrowing, ignored [[nodiscard]]).
  -- Unlisted flags keep their clangd defaults, so --header-insertion=iwyu --
  -- the auto-#include on <C-y> -- is unaffected.
  -- Bare "clangd" resolves to mason's copy; mason prepends its bin to PATH.
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
  },

  -- The default C++ standard, and the ONLY place it is set. fallbackFlags
  -- apply only when a file has no compile database, so a real project always
  -- wins: compile_commands.json (CMake) > this.
  --
  -- Do not move this into ~/Library/Preferences/clangd/config.yaml --
  -- CompileFlags.Add there appends *after* the compile command and would
  -- override CMake. That bug once pinned everything to c++20.
  --
  -- These flags are language-agnostic and clang rejects -std=c++23 on C, so
  -- that config.yaml strips it back off for .c files.
  init_options = {
    fallbackFlags = { "-std=c++23" },
  },

  -- signatureHelpProvider is deliberately NOT disabled here any more. Upstream
  -- turned it off because the native popup fought the completion menu; that is
  -- now lsp_signature.nvim's job (plugins/editor.lua), whose
  -- check_completion_visible repositions the float around cmp's menu instead.
  -- Disabling the capability killed the parameter list for every server,
  -- including the overload list on std:: constructors.
  --
  -- Inlay hints need nothing from clangd: ParameterNames and DeducedTypes are
  -- on by default in clangd 22, and ~/Library/Preferences/clangd/config.yaml
  -- has no InlayHints: block overriding them. pyright is the opposite -- see
  -- below.
})

vim.lsp.enable "clangd"

-- neocmakelsp ----------------------------------------------------------------
-- Completion, hover, go-to-definition and diagnostics for CMakeLists.txt.
-- nvim-lspconfig ships the config, so enabling is all that's needed.
-- It only returns completions when the client advertises snippetSupport,
-- which NvChad already sets in its "*" capabilities.
vim.lsp.enable "neocmake"

-- Python ---------------------------------------------------------------------
-- pyright: types, completion, go-to-definition.
--
-- Finds a project-local .venv, so pip-installed imports don't all read as
-- "could not be resolved". venvPath must be ABSOLUTE: a relative "." (as the
-- old kickstart config used) silently fails to resolve over LSP, even when
-- root_dir is set. Computed at attach because the project isn't known earlier.
vim.lsp.config("pyright", {
  -- No inlay hint settings here on purpose. Open-source pyright does not
  -- implement textDocument/inlayHint at all -- it advertises no
  -- inlayHintProvider, so python.analysis.inlayHints.* is read by nothing.
  -- Those keys belong to Pylance and to basedpyright, which is a drop-in fork
  -- (mason has it) if Python inlay hints are ever worth switching for.
  -- Signature help is unaffected: pyright does advertise signatureHelpProvider.
  --
  -- Must mutate client.settings: that is what answers pyright's
  -- workspace/configuration pull. Setting config.settings in before_init does
  -- NOT reach it -- the reply comes back carrying only python.analysis.
  --
  -- pythonPath (the interpreter), not venvPath: it is what editors are expected
  -- to send, and it survives the pull reliably.
  on_init = function(client)
    local root = client.root_dir or vim.uv.cwd()
    local py = root and (root .. "/.venv/bin/python")
    if py and vim.uv.fs_stat(py) then
      client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
        python = { pythonPath = py, venvPath = root, venv = ".venv" },
      })
      client:notify("workspace/didChangeConfiguration", { settings = client.settings })
    end
  end,
})
vim.lsp.enable "pyright"

-- ruff: linting (and import sorting). This is the Rust server built into the
-- ruff binary -- upstream installs ruff-lsp, which mason no longer carries.
vim.lsp.enable "ruff"

-- Adding a server: vim.lsp.config(name, {...}) then vim.lsp.enable(name),
-- plus the binary in plugins/tools.lua. See :h vim.lsp.config

-- Diagnostics --------------------------------------------------------------
-- Errors only by default; <leader>dt toggles everything back on. Must run
-- AFTER the nvchad defaults() call at the top of this file -- that is what
-- sets the sign icons apply() reads back and preserves.
require("configs.diagnostics").apply()

-- Inlay hints ----------------------------------------------------------------
-- On by default; <leader>ih toggles. Registers an LspAttach autocmd, so it has
-- to run before the servers above actually attach -- which they do on the next
-- BufReadPost, well after this file finishes.
require("configs.inlayhints").apply()
