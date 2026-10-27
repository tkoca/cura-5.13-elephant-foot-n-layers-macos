#!/bin/bash
# Installs the pinned build tools into $EFNL_ROOT (default /Users/Shared/efnl):
#   Python 3.12 (python-build-standalone via uv; the CuraEngine conanfile needs Python >= 3.10,
#   macOS ships 3.9), conan 2.32.0, cmake 3.31.6, ninja 1.13.2 in $EFNL_ROOT/tools.
# CMake 3.x on purpose: several Conan recipes still declare cmake_minimum_required(< 3.5), which CMake 4 rejects.
# Nothing is installed outside $EFNL_ROOT.
set -euo pipefail
EFNL_ROOT="${EFNL_ROOT:-/Users/Shared/efnl}"
mkdir -p "$EFNL_ROOT"
/usr/bin/python3 -m venv "$EFNL_ROOT/uv"
"$EFNL_ROOT/uv/bin/pip" install -q uv==0.9.5
UV_PYTHON_INSTALL_DIR="$EFNL_ROOT/python" UV_PYTHON_INSTALL_BIN=0 "$EFNL_ROOT/uv/bin/uv" python install 3.12
py="$(ls "$EFNL_ROOT"/python/cpython-3.12*/bin/python3.12 | head -1)"
rm -rf "$EFNL_ROOT/tools"
"$py" -m venv "$EFNL_ROOT/tools"
"$EFNL_ROOT/tools/bin/pip" install -q --upgrade pip
"$EFNL_ROOT/tools/bin/pip" install -q conan==2.32.0 cmake==3.31.6 ninja==1.13.2
"$EFNL_ROOT/tools/bin/python" --version
"$EFNL_ROOT/tools/bin/conan" --version
