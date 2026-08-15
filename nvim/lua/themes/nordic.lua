-- Port of https://github.com/AlexvZyl/nordic.nvim (darker, warmer Nord)
-- Role mapping mirrors base46's built-in nord.lua with nordic's deeper backgrounds.

local M = {}

M.base_30 = {
  white = "#d8dee9",
  darker_black = "#16191f",
  black = "#191d24", --  nvim bg
  black2 = "#1e222a",
  one_bg = "#242933",
  one_bg2 = "#2e3440",
  one_bg3 = "#3b4252",
  grey = "#434c5e",
  grey_fg = "#4c566a",
  grey_fg2 = "#556075",
  light_grey = "#60728a",
  red = "#bf616a",
  baby_pink = "#c5727a",
  pink = "#d57780",
  line = "#262b35", -- for lines like vertsplit
  green = "#a3be8c",
  vibrant_green = "#afca98",
  blue = "#81a1c1",
  nord_blue = "#88c0d0",
  yellow = "#ebcb8b",
  sun = "#e1c181",
  purple = "#b48ead",
  dark_purple = "#a983a2",
  teal = "#8fbcbb",
  orange = "#d08770",
  cyan = "#9fc6c5",
  statusline_bg = "#1c2028",
  lightbg = "#2e3440",
  pmenu_bg = "#a3be8c",
  folder_bg = "#81a1c1",
}

M.base_16 = {
  base00 = "#191d24",
  base01 = "#242933",
  base02 = "#2e3440",
  base03 = "#4c566a",
  base04 = "#d8dee9",
  base05 = "#e5e9f0",
  base06 = "#eceff4",
  base07 = "#8fbcbb",
  base08 = "#88c0d0",
  base09 = "#81a1c1",
  base0A = "#88c0d0",
  base0B = "#a3be8c",
  base0C = "#81a1c1",
  base0D = "#81a1c1",
  base0E = "#81a1c1",
  base0F = "#b48ead",
}

M.polish_hl = {
  treesitter = {
    ["@punctuation.bracket"] = { fg = M.base_30.white },
    ["@punctuation.delimiter"] = { fg = M.base_30.white },
  },
}

M.type = "dark"

M = require("base46").override_theme(M, "nordic")

return M
