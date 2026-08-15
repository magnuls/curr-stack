-- Git. NvChad already provides gitsigns (hunk signs, staging, inline blame)
-- and Telescope pickers (<leader>cm commits, <leader>gt status).
-- lazygit covers what those don't: branches, the log graph, and rebasing.
--
-- Needs the binary: brew install lazygit
-- Keymaps (<leader>gg, <leader>gf): lua/mappings.lua

return {
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitCurrentFile", "LazyGitFilter", "LazyGitFilterCurrentFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
  },
}
