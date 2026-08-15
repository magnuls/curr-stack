-- NvChad UI. Full option list: https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
--
-- Do NOT delete ~/.local/share/nvim/base46/ to force a theme rebuild -- init.lua
-- dofile()s that cache before anything can regenerate it and startup aborts.
-- Use <leader>th; recovery command is in CONFIG-REFERENCE.md.

---@type ChadrcConfig
local M = {}

M.base46 = {
  -- Matches Alacritty (themes/tokyo_night.toml) and tmux (tokyo-night-tmux),
  -- so the statusline doesn't clash with the tmux bar right below it.
  theme = "catppuccin-latte",
}

return M
