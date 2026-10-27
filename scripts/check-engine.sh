#!/bin/bash
# Checks a macOS CuraEngine binary against the official Cura 5.13.0 engine (macOS arm64):
# thin arm64 Mach-O, deployment target <= 12.0, the same libraries (system + @rpath from
# Contents/Frameworks), exactly one LC_RPATH @loader_path, valid (ad hoc) signature,
# no user name, home folder or host name.
set -euo pipefail
bin="$1"; fail=0
ALLOWED_RPATH_LIBS="libArcus.dylib libpolyclipping.22.dylib libtbb.12.dylib libtbbmalloc.2.dylib libtbbmalloc_proxy.2.dylib"
archs="$(lipo -archs "$bin")"; echo "archs: $archs"
[[ "$archs" == arm64 ]] || { echo "FAIL: must be thin arm64"; fail=1; }
minos="$(otool -l "$bin" | awk '/LC_BUILD_VERSION/ {f=1} f && $1=="minos" {print $2; exit}')"
echo "minos: $minos (limit 12.0)"
[[ "$(printf '%s\n12.0\n' "$minos" | sort -t. -k1,1n -k2,2n | tail -1)" == 12.0 ]] || { echo "FAIL: deployment target too new"; fail=1; }
rpaths="$(otool -l "$bin" | awk '/cmd LC_RPATH/ {getline; getline; print $2}' | tr '\n' ' ')"
echo "rpaths: $rpaths"
[[ "$rpaths" == "@loader_path " ]] || { echo "FAIL: LC_RPATH must be exactly @loader_path"; fail=1; }
while read -r lib; do
  case "$lib" in
    /usr/lib/*|/System/Library/Frameworks/*) ;;
    @rpath/*) [[ " $ALLOWED_RPATH_LIBS " == *" ${lib#@rpath/} "* ]] || { echo "FAIL: library not in Cura.app: $lib"; fail=1; } ;;
    *) echo "FAIL: absolute non-system library: $lib"; fail=1 ;;
  esac
done < <(otool -L "$bin" | awk 'NR>1 {print $1}')
echo "libraries: $(otool -L "$bin" | awk 'NR>1 {print $1}' | tr '\n' ' ')"
codesign --verify --strict "$bin" || { echo "FAIL: signature invalid"; fail=1; }
# Like the official engine, the static dependencies keep some build paths (__FILE__, OPENSSLDIR);
# with EFNL_ROOT those are neutral (/Users/Shared/efnl/...). User name, home and host name must not appear.
# (user name as a whole word; the short host name only as "<host>.local", it is often a common word like "mac")
pat="$HOME|/Users/$(id -un)|/private/var/folders|\\b$(id -un)\\b|$(hostname -s)\\.local"
n=$(strings -n 6 "$bin" | grep -cE "$pat" || true)
echo "neutral build-path strings: $(strings -n 6 "$bin" | grep -c '/Users/Shared/efnl' || true)"
echo "host path/user strings: $n"
[[ "$n" == 0 ]] || { strings -n 6 "$bin" | grep -E "$pat" | head -5 || true; echo "FAIL: leak"; fail=1; }
shasum -a 256 "$bin"
if [[ $fail == 0 ]]; then echo "CHECK PASS"; else echo "CHECK FAIL"; exit 1; fi
