-- Port of https://github.com/scottmckendry/cyberdream.nvim (default dark palette)

local M = {}

M.base_30 = {
  white = "#ffffff",
  darker_black = "#101214",
  black = "#16181a", --  nvim bg
  black2 = "#1c1f21",
  one_bg = "#212427",
  one_bg2 = "#282b2f",
  one_bg3 = "#2f3337",
  grey = "#3c4048",
  grey_fg = "#4a4f58",
  grey_fg2 = "#575d66",
  light_grey = "#7b8496",
  red = "#ff6e5e",
  baby_pink = "#ff8a7a",
  pink = "#ff5ea0",
  line = "#24272a", -- for lines like vertsplit
  green = "#5eff6c",
  vibrant_green = "#7dff88",
  nord_blue = "#7ab4ff",
  blue = "#5ea1ff",
  yellow = "#f1ff5e",
  sun = "#f5ff7e",
  purple = "#bd5eff",
  dark_purple = "#a94ee8",
  teal = "#5edfce",
  orange = "#ffbd5e",
  cyan = "#5ef1ff",
  statusline_bg = "#1b1e20",
  lightbg = "#24272a",
  pmenu_bg = "#5ea1ff",
  folder_bg = "#5ea1ff",
}

M.base_16 = {
  base00 = "#16181a",
  base01 = "#1e2124",
  base02 = "#3c4048",
  base03 = "#7b8496",
  base04 = "#7b8496",
  base05 = "#ffffff",
  base06 = "#ffffff",
  base07 = "#ffffff",
  base08 = "#ff6e5e",
  base09 = "#ffbd5e",
  base0A = "#f1ff5e",
  base0B = "#5eff6c",
  base0C = "#5ef1ff",
  base0D = "#5ea1ff",
  base0E = "#ff5ef1",
  base0F = "#ff5ea0",
}

M.type = "dark"

M = require("base46").override_theme(M, "cyberdream")

return M
