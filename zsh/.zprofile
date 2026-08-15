# Homebrew — sets PATH, MANPATH, etc. Checks both prefixes so this works on
# Apple Silicon (/opt/homebrew) and Intel (/usr/local).
for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  if [ -x "$brew_bin" ]; then
    eval "$("$brew_bin" shellenv)"
    break
  fi
done
unset brew_bin

# python.org framework builds, if any are installed. Iterated oldest-first so
# the newest ends up prepended last and therefore wins the PATH lookup.
# Skipped entirely on machines with only Homebrew or system python.
for py_ver in 3.13 3.14 3.15; do
  py_bin="/Library/Frameworks/Python.framework/Versions/$py_ver/bin"
  [ -d "$py_bin" ] && PATH="$py_bin:$PATH"
done
unset py_ver py_bin
export PATH
