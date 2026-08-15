-- Inlay hints: the greyed-in annotations at call sites and on deduced types --
-- CLion's `memcpy(dst: buf, src: src, count: 64)` and `auto n: size_t = ...`.
-- Applied from configs/lspconfig.lua, toggled by <leader>ih in mappings.lua.
--
-- Rendering is entirely Neovim's (vim.lsp.inlay_hint, 0.10+); all this module
-- does is decide which buffers get it switched on. What each server actually
-- emits is a server-side setting:
--   clangd  -- ParameterNames and DeducedTypes are on by default in clangd 22,
--             so nothing to configure. Override via InlayHints: in
--             ~/Library/Preferences/clangd/config.yaml if that ever changes.
--   pyright -- every hint defaults to OFF; switched on in the `settings` table
--             in configs/lspconfig.lua.
-- A server that supports none of this is skipped rather than erroring.

local M = {}

-- Default on. Public so the toggle and any probe can read it.
M.enabled = true

function M.apply()
  -- Enable per buffer as each client attaches. inlay_hint.enable is a no-op for
  -- a buffer whose server has no hints, but supports_method keeps the autocmd
  -- honest and cheap for ruff, which advertises none.
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("InlayHints", { clear = true }),
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      -- Method-call form: 0.11 deprecated the dot-call client.supports_method.
      if client and client:supports_method "textDocument/inlayHint" then
        vim.lsp.inlay_hint.enable(M.enabled, { bufnr = args.buf })
      end
    end,
  })

  -- The autocmd above only fires for clients that attach AFTER it is created.
  -- This file is required at the bottom of configs/lspconfig.lua, which lazy
  -- loads on "User FilePost" -- normally before any client attaches, but not
  -- after a :source or a Lazy reload. Catch up on whatever is already attached.
  for _, client in ipairs(vim.lsp.get_clients()) do
    if client:supports_method "textDocument/inlayHint" then
      for bufnr in pairs(client.attached_buffers or {}) do
        vim.lsp.inlay_hint.enable(M.enabled, { bufnr = bufnr })
      end
    end
  end
end

function M.toggle()
  M.enabled = not M.enabled
  -- No filter = every buffer, so one press clears the whole session rather than
  -- just the one you are looking at. New buffers then follow M.enabled via the
  -- LspAttach autocmd above.
  vim.lsp.inlay_hint.enable(M.enabled)
  vim.notify(M.enabled and "Inlay hints: on" or "Inlay hints: off", vim.log.levels.INFO)
end

return M
