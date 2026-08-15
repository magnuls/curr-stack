-- Port of https://github.com/sainnhe/gruvbox-material (medium dark, material palette)

local M = {}

M.base_30 = {
  white = "#d4be98",
  darker_black = "#232323",
  black = "#282828", --  nvim bg
  black2 = "#2e2d2c",
  one_bg = "#32302f",
  one_bg2 = "#3a3735",
  one_bg3 = "#45403d",
  grey = "#504945",
  grey_fg = "#5a524c",
  grey_fg2 = "#665c54",
  light_grey = "#7c6f64",
  red = "#ea6962",
  baby_pink = "#ef7a74",
  pink = "#d3869b",
  line = "#363433", -- for lines like vertsplit
  green = "#a9b665",
  vibrant_green = "#b8c47a",
  nord_blue = "#7daea3",
  blue = "#7daea3",
  yellow = "#d8a657",
  sun = "#e0b066",
  purple = "#d3869b",
  dark_purple = "#c67b90",
  teal = "#89b482",
  orange = "#e78a4e",
  cyan = "#89b482",
  statusline_bg = "#2c2b2a",
  lightbg = "#3a3735",
  pmenu_bg = "#a9b665",
  folder_bg = "#7daea3",
}

M.base_16 = {
  base00 = "#282828",
  base01 = "#32302f",
  base02 = "#45403d",
  base03 = "#5a524c",
  base04 = "#928374",
  base05 = "#d4be98",
  base06 = "#ddc7a1",
  base07 = "#e2cca9",
  base08 = "#ea6962",
  base09 = "#e78a4e",
  base0A = "#d8a657",
  base0B = "#a9b665",
  base0C = "#89b482",
  base0D = "#7daea3",
  base0E = "#d3869b",
  base0F = "#e78a4e",
}

M.type = "dark"

M = require("base46").override_theme(M, "gruvbox_material")

return M
