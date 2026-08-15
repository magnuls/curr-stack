-- Port of the Moon variant from https://rosepinetheme.com/
-- Role mapping mirrors base46's built-in rosepine.lua with the moon palette swapped in.

local M = {}

M.base_30 = {
  black = "#232136", --  nvim bg
  darker_black = "#1d1b2e",
  white = "#e0def4",
  black2 = "#292740",
  one_bg = "#2f2c47",
  one_bg2 = "#36334e",
  one_bg3 = "#3d3a55",
  grey = "#44415a",
  grey_fg = "#4d4a63",
  grey_fg2 = "#56526e",
  light_grey = "#615d79",
  red = "#eb6f92",
  baby_pink = "#f5799c",
  pink = "#ff83a6",
  line = "#343150", -- for lines like vertsplit
  green = "#ABE9B3",
  vibrant_green = "#b5f3bd",
  nord_blue = "#89bac6",
  blue = "#9ccfd8",
  yellow = "#f6c177",
  sun = "#fec97f",
  purple = "#c4a7e7",
  dark_purple = "#bb9ede",
  teal = "#4f9cbd",
  orange = "#ea9a97",
  cyan = "#9ccfd8",
  statusline_bg = "#26233c",
  lightbg = "#36334e",
  pmenu_bg = "#c4a7e7",
  folder_bg = "#6aadc8",
}

M.base_16 = {
  base00 = "#232136",
  base01 = "#2a273f",
  base02 = "#393552",
  base03 = "#6e6a86",
  base04 = "#908caa",
  base05 = "#e0def4",
  base06 = "#e0def4",
  base07 = "#56526e",
  base08 = "#eb6f92",
  base09 = "#f6c177",
  base0A = "#ea9a97",
  base0B = "#3e8fb0",
  base0C = "#9ccfd8",
  base0D = "#c4a7e7",
  base0E = "#f6c177",
  base0F = "#56526e",
}

M.type = "dark"

M = require("base46").override_theme(M, "rosepine-moon")

return M
