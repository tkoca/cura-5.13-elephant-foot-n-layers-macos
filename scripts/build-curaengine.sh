#!/bin/bash
# Builds CuraEngine 5.13.0 for macOS arm64 (Apple Silicon) natively with the Xcode command line tools.
#
#   scripts/build-curaengine.sh [--unpatched] <CuraEngine-5.13.0.tar.gz> <out-dir>
#
# 1. Extracts the upstream CuraEngine 5.13.0 tag archive into $EFNL_ROOT/work.
# 2. Verifies the pristine src/slicer.cpp (SHA-256, LF).
# 3. Applies patches/CuraEngine-5.13.0.patch (skipped with --unpatched: control build).
# 4. conan build with the UltiMaker Conan configuration, default CuraEngine options
#    (Arcus + plugins on, Sentry off), Release, deployment target macOS 12.0 like the official engine.
# 5. Sets the same single LC_RPATH as the official engine (@loader_path: the libraries come from
#    Contents/Frameworks of Cura.app), strips the binary, signs it ad hoc and checks it
#    (scripts/check-engine.sh).
#
# EFNL_ROOT (default /Users/Shared/efnl) holds the Conan home and the work folder. It is a neutral
# path so that no user name ends up in the binary; the -ffile-prefix-map flags map it to ".".
# Needs: Xcode command line tools, python3, and conan 2.32.0 / cmake 3.31.6 / ninja 1.13.2 on PATH
# (scripts/setup-tools.sh installs them into $EFNL_ROOT/tools).
set -euo pipefail

UNPATCHED=0
if [[ "${1:-}" == "--unpatched" ]]; then UNPATCHED=1; shift; fi
[[ $# -eq 2 ]] || { echo "usage: $0 [--unpatched] <CuraEngine-5.13.0.tar.gz> <out-dir>" >&2; exit 2; }
[[ "$(uname -s)" == Darwin && "$(uname -m)" == arm64 ]] || { echo "build on macOS arm64" >&2; exit 2; }

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC_TGZ="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
mkdir -p "$2"; OUT="$(cd "$2" && pwd)"
EFNL_ROOT="${EFNL_ROOT:-/Users/Shared/efnl}"
CONAN_CONFIG_REF="${EFNL_CONAN_CONFIG_REF:-bba7984a7363709f239fc13a3a3e0b02ecc2488b}"
JOBS="${EFNL_JOBS:-$(sysctl -n hw.ncpu)}"
PRISTINE=0397cf03e606bd7f2f3653ee7fce28d0ad73b28c146e66aa78f3e7c49e89e5ef
[[ "$EFNL_ROOT" != *" "* ]] || { echo "EFNL_ROOT must not contain spaces" >&2; exit 2; }
export PATH="$EFNL_ROOT/tools/bin:$PATH"
for t in conan cmake ninja; do command -v "$t" >/dev/null || { echo "$t not found (run scripts/setup-tools.sh)" >&2; exit 1; }; done
export CONAN_HOME="$EFNL_ROOT/conan" TMPDIR="$EFNL_ROOT/conan/tmp" MACOSX_DEPLOYMENT_TARGET=12.0
mkdir -p "$TMPDIR"

if [[ ! -f "$CONAN_HOME/.efnl-config-$CONAN_CONFIG_REF" ]]; then
  rm -rf "$EFNL_ROOT/cc"
  git clone -q https://github.com/Ultimaker/conan-config.git "$EFNL_ROOT/cc"
  git -C "$EFNL_ROOT/cc" checkout -q "$CONAN_CONFIG_REF"
  conan config install "$EFNL_ROOT/cc"
  conan profile detect --force >/dev/null
  touch "$CONAN_HOME/.efnl-config-$CONAN_CONFIG_REF"
fi

rm -rf "$EFNL_ROOT/work" && mkdir -p "$EFNL_ROOT/work" && cd "$EFNL_ROOT/work"
tar -xzf "$SRC_TGZ"
cd CuraEngine-5.13.0
actual=$(tr -d "\r" < src/slicer.cpp | shasum -a 256 | cut -d" " -f1)
[[ "$actual" == "$PRISTINE" ]] || { echo "Unexpected upstream slicer.cpp ($actual). Is this CuraEngine 5.13.0?" >&2; exit 1; }
if [[ "$UNPATCHED" == 0 ]]; then
  python3 "$REPO/scripts/apply_patch.py" "$REPO/patches/CuraEngine-5.13.0.patch" .
fi
map="-ffile-prefix-map=$EFNL_ROOT=."
# gRPC 1.54.3 (pinned by CuraEngine 5.13.0) predates clang 19, which turned this warning into an error.
compat="-Wno-missing-template-arg-list-after-template-kw"
conan build . --build=missing -s build_type=Release -s arch=armv8 -s os.version=12.0 -c tools.build:jobs="$JOBS" \
  -c "tools.build:cflags=[\"$map\"]" -c "tools.build:cxxflags=[\"$map\", \"$compat\"]" \
  -c "tools.cmake.cmaketoolchain:extra_variables={\"CMAKE_SKIP_BUILD_RPATH\": \"ON\", \"CMAKE_SKIP_INSTALL_RPATH\": \"ON\", \"CMAKE_SKIP_RPATH\": \"ON\"}"
bin=$(find . -type f -name CuraEngine -perm -u+x | head -1)
[[ -n "$bin" ]] || { echo "CuraEngine not produced" >&2; exit 1; }
name=CuraEngine; [[ "$UNPATCHED" == 1 ]] && name=CuraEngine.unpatched
dst="$OUT/$name"
cp "$bin" "$dst"
# Libraries by @rpath only, then the single rpath of the official engine.
for lib in $(otool -L "$dst" | awk 'NR>1 {print $1}' | grep -vE '^(/usr/lib/|/System/|@rpath/)' || true); do
  install_name_tool -change "$lib" "@rpath/$(basename "$lib")" "$dst"
done
for rp in $(otool -l "$dst" | awk '/cmd LC_RPATH/ {getline; getline; print $2}'); do install_name_tool -delete_rpath "$rp" "$dst"; done
install_name_tool -add_rpath @loader_path "$dst"
strip "$dst"
codesign --force --sign - --identifier CuraEngine "$dst"
"$REPO/scripts/check-engine.sh" "$dst"
