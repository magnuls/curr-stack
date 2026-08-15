-- Format-on-save for every configured filetype.
-- Asserts the buffer actually changed to the expected shape -- a formatter that
-- times out or isn't installed silently leaves the file alone, which is exactly
-- how the black timeout went unnoticed.
local t = dofile(vim.fn.expand "$SMOKE_LUA/t.lua")
local root = os.getenv "SMOKE_FIXTURE"

t.force_load "conform.nvim"

--- Write `content` to `path`, open it, :w, and return the resulting lines.
local function save_and_read(path, content)
  vim.fn.writefile(vim.split(content, "\n"), path)
  vim.cmd("edit! " .. vim.fn.fnameescape(path))
  local avail = {}
  for _, f in ipairs(require("conform").list_formatters(0)) do
    avail[#avail + 1] = f.name .. "=" .. tostring(f.available)
  end
  vim.cmd "silent write"
  vim.wait(3000)
  vim.cmd "edit!"
  return vim.api.nvim_buf_get_lines(0, 0, -1, false), table.concat(avail, ",")
end

vim.defer_fn(function()
  local tmp = root .. "/scratch"

  -- C++ -- must land on 4 spaces, per ~/.clang-format IndentWidth: 4
  t.guard("fmt-cpp", function()
    local lines, avail = save_and_read(tmp .. "/fmt.cpp", "int main(){\nint x=1;\n  if(x){return 0;}\nreturn 1;\n}")
    local indent = #((lines[2] or ""):match "^ *")
    t.check("clang-format on save", (lines[1] or ""):match "int main%(%) {" ~= nil, table.concat(lines, "|"))
    t.check("clang-format uses 4 spaces", indent == 4, string.format("indent=%d  formatters=%s", indent, avail))
  end)

  -- CMake
  t.guard("fmt-cmake", function()
    local lines, avail = save_and_read(
      tmp .. "/fmt.cmake",
      "cmake_minimum_required(VERSION 3.20)\n   set(FOO    bar)\nadd_executable(app\nsrc/a.cpp\n     src/b.cpp)"
    )
    local joined = table.concat(lines, "\n")
    t.check(
      "gersemi on save",
      joined:match "\nset%(FOO bar%)" ~= nil and joined:match "add_executable%(app src/a%.cpp src/b%.cpp%)" ~= nil,
      "formatters=" .. avail .. " result=" .. joined:gsub("\n", "|")
    )
  end)

  -- Python -- clear black's bytecode cache first so the cold-start path (the
  -- one that used to exceed conform's 500ms timeout) is genuinely exercised.
  t.guard("fmt-python", function()
    vim.fn.system {
      "find",
      vim.fn.stdpath "data" .. "/mason/packages/black",
      "-name",
      "__pycache__",
      "-type",
      "d",
      "-exec",
      "rm",
      "-rf",
      "{}",
      "+",
    }
    local lines, avail = save_and_read(tmp .. "/fmt.py", 'def  f( x,y ):\n  return {  "a":1,"b":2 }')
    t.check(
      "black on save (cold start)",
      (lines[1] or "") == "def f(x, y):" and (lines[2] or ""):match '^    return {"a": 1, "b": 2}' ~= nil,
      "formatters=" .. avail .. " result=" .. table.concat(lines, "|")
    )
  end)

  -- Lua
  t.guard("fmt-lua", function()
    local lines, avail =
      save_and_read(tmp .. "/fmt.lua", "local x={a=1,b=2}\nlocal function f(  y )\nreturn y+1\nend\nreturn {x,f}")
    t.check(
      "stylua on save",
      (lines[1] or "") == "local x = { a = 1, b = 2 }",
      "formatters=" .. avail .. " result=" .. table.concat(lines, "|")
    )
  end)

  t.finish()
end, 3000)
