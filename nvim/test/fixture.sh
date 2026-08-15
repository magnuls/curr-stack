#!/usr/bin/env bash
# Builds the polyglot test project the smoke suite runs against.
# Usage: fixture.sh <dir>     (dir is created; anything already there is removed)
#
# Deliberately covers, in ONE project:
#   - C++23 and C89-ish C, both including headers from a shared include/ dir
#     using .h for both languages (the ambiguous case for clangd)
#   - CMake with two targets so compile_commands.json carries both languages
#   - a Python package with a .venv holding a package available nowhere else
#   - files with deliberate errors, for diagnostics
#   - git history, a dirty file and a second branch, for gitsigns/lazygit
set -euo pipefail

DIR="${1:?usage: fixture.sh <dir>}"
rm -rf "$DIR"
mkdir -p "$DIR"/{include,src,legacy,py,scratch}
cd "$DIR"

# ---------------------------------------------------------------- C++ / C ----
cat > include/mathlib.h <<'EOF'
// C++ header, deliberately .h rather than .hpp.
#pragma once
#include <string>
#include <vector>

namespace mathlib {

template <typename T>
constexpr T square(T v) {
    return v * v;
}

class Accumulator {
  public:
    explicit Accumulator(int start);
    auto add(this Accumulator& self, int v) -> Accumulator&;
    [[nodiscard]] auto total() const -> int;
    [[nodiscard]] auto label() const -> std::string const&;

  private:
    int total_;
    std::string label_;
};

} // namespace mathlib
EOF

cat > include/util.h <<'EOF'
/* C header, also .h. Must not be parsed as C++. */
#ifndef UTIL_H
#define UTIL_H

struct point {
    int x;
    int y;
};

int point_sum(struct point p);
int clamp_int(int v, int lo, int hi);

#endif /* UTIL_H */
EOF

cat > src/mathlib.cpp <<'EOF'
#include "mathlib.h"

#include <utility>

namespace mathlib {

Accumulator::Accumulator(int start) : total_(start), label_("acc") {}

auto Accumulator::add(this Accumulator& self, int v) -> Accumulator& {
    self.total_ += v;
    return self;
}

auto Accumulator::total() const -> int {
    return total_;
}

auto Accumulator::label() const -> std::string const& {
    return label_;
}

} // namespace mathlib
EOF

cat > src/main.cpp <<'EOF'
#include "mathlib.h"

#include <expected>
#include <print>
#include <string>

auto parse(std::string const& s) -> std::expected<int, std::string> {
    if (s.empty()) {
        return std::unexpected("empty");
    }
    return static_cast<int>(s.size());
}

int main() {
    mathlib::Accumulator acc{0};
    acc.add(2).add(3).add(5);

    int const sq = mathlib::square(7);
    auto const parsed = parse("hello");

    std::println("total={} square={} parsed={}", acc.total(), sq, parsed.value_or(-1));
    return 0;
}
EOF

cat > legacy/util.c <<'EOF'
#include "util.h"

int point_sum(struct point p) {
    return p.x + p.y;
}

int clamp_int(int v, int lo, int hi) {
    if (v < lo) {
        return lo;
    }
    if (v > hi) {
        return hi;
    }
    return v;
}
EOF

cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.20)
project(testbed C CXX)

# Debug by default. With an empty CMAKE_BUILD_TYPE cmake passes no -g at all,
# the binary carries no DWARF, and source-line breakpoints silently never bind
# -- the debugger launches the program and runs straight through.
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Debug)
endif()

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_C_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(util STATIC legacy/util.c)
target_include_directories(util PUBLIC include)

add_executable(app src/main.cpp src/mathlib.cpp)
target_include_directories(app PUBLIC include)
target_link_libraries(app PRIVATE util)
EOF

# ------------------------------------------------------------------ broken ---
cat > scratch/broken.cpp <<'EOF'
#include <string>

int main() {
    std::string s = 42;
    undefined_function();
    return 0
}
EOF

cat > scratch/CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.20)
project(broken CXX
add_executable(x y.cpp)
EOF

# ------------------------------------------------------------------ Python ---
cat > py/pyproject.toml <<'EOF'
[project]
name = "pytestbed"
version = "0.1.0"
EOF

cat > py/mathlib.py <<'EOF'
from dataclasses import dataclass


@dataclass
class Accumulator:
    total: int = 0

    def add(self, value: int) -> "Accumulator":
        self.total += value
        return self


def square(value: int) -> int:
    return value * value


def describe(acc: Accumulator) -> str:
    return f"total={acc.total}"
EOF

cat > py/app.py <<'EOF'
import mydummypkg

from mathlib import Accumulator, describe, square


def main() -> str:
    acc = Accumulator()
    acc.add(2).add(3).add(5)
    result = f"{describe(acc)} square={square(7)} venv={mydummypkg.hello()}"
    print(result)
    return result


if __name__ == "__main__":
    main()
EOF

cat > py/test_mathlib.py <<'EOF'
from mathlib import Accumulator, square


def test_square():
    assert square(7) == 49


def test_accumulator():
    acc = Accumulator()
    acc.add(2).add(3)
    assert acc.total == 5
EOF

cat > py/broken.py <<'EOF'
import sys
import os

from mathlib import square


def bad() -> int:
    value: str = square(3)
    return undefined_name
EOF

cat > py/mangled.py <<'EOF'
def  mangled( a,b ):
  return {  "a":a,"b":b }
EOF

python3 -m venv py/.venv >/dev/null 2>&1
# pytest so <leader>dpr (dap-python test_method) has something real to run.
# Tolerated if it fails -- offline runs just skip that one check.
py/.venv/bin/python -m pip install --quiet --disable-pip-version-check pytest >/dev/null 2>&1 || true
SITE=$(echo py/.venv/lib/python*/site-packages)
mkdir -p "$SITE/mydummypkg"
cat > "$SITE/mydummypkg/__init__.py" <<'EOF'
def hello() -> str:
    return "from-venv"
EOF

# --------------------------------------------------------------- lua + git ---
cat > mangled.lua <<'EOF'
local x={a=1,b=2}
local function f(  y )
return y+1
end
return {x,f}
EOF

cat > .gitignore <<'EOF'
build/
py/.venv/
EOF

git init -q
git add -A
git -c user.name=test -c user.email=test@test commit -q -m "initial fixture"
git checkout -q -b feature
echo "// dirty" >> src/main.cpp

# ------------------------------------------------------------------- build ---
# Configure AND build: compile_commands.json comes from the configure step, but
# the debug probe needs an actual executable with DWARF to launch.
cmake -S . -B build >/dev/null 2>&1
cmake --build build >/dev/null 2>&1
echo "$DIR"
