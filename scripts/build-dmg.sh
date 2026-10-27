#!/bin/bash
# Builds dist/Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.dmg: double-click Install / Uninstall apps
# (AppleScript applets running installer/efnl.sh --gui) and a read-me.
#   scripts/build-dmg.sh <Cura-5.13.0.tar.gz> <Uranium-5.13.0.tar.gz> <patched CuraEngine> [dist-dir]
# The apps are signed ad hoc (no Apple Developer ID): on first open macOS asks for "Open Anyway" once.
# Unlike the .run file the .dmg is not bit-for-bit reproducible (applet and disk image metadata);
# its payload is (same payload-SHA256SUMS.txt as the .run file).
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
CURA_SRC="$1"; URANIUM_SRC="$2"; ENGINE="$3"; mkdir -p "${4:-$REPO/dist}"; DIST="$(cd "${4:-$REPO/dist}" && pwd)"
VERSION="$(sed -n 's/^readonly VERSION="\(.*\)"/\1/p' "$REPO/installer/efnl.sh")"
NAME="Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.dmg"
INSTALL_APP="Install Elephant Foot N Layers.app"; UNINSTALL_APP="Uninstall Elephant Foot N Layers.app"
"$REPO/scripts/check-engine.sh" "$ENGINE" >/dev/null || { echo "engine check FAILED (scripts/check-engine.sh $ENGINE)" >&2; exit 1; }
work="$(mktemp -d)"; trap 'rm -rf -- "$work"' EXIT
python3 "$REPO/scripts/make_payload.py" "$CURA_SRC" "$URANIUM_SRC" "$ENGINE" "$work" >/dev/null
stage="$work/stage"; mkdir -p "$stage"

make_app() {  # make_app <app name> <install|uninstall> <with payload: 0|1>
  local app="$stage/$1" res
  sed "s/@ACTION@/$2/" "$REPO/installer/app/main.applescript" > "$work/$2.applescript"
  osacompile -o "$app" "$work/$2.applescript"
  res="$app/Contents/Resources/installer"
  mkdir -p "$res/lang"
  cp "$REPO/installer/efnl.sh" "$res/"; chmod 755 "$res/efnl.sh"
  cp "$REPO/installer/lang/"*.sh "$res/lang/"; chmod 644 "$res/lang/"*.sh
  [[ $3 == 1 ]] && cp -R "$work/payload" "$res/payload"
  plutil -replace CFBundleIdentifier -string "cura-5.13-efnl.$2" "$app/Contents/Info.plist"
  plutil -replace CFBundleShortVersionString -string "$VERSION" "$app/Contents/Info.plist"
  xattr -cr "$app"
  codesign --force --sign - "$app" 2>/dev/null
  codesign --verify --deep --strict "$app"
}
make_app "$INSTALL_APP" install 1
make_app "$UNINSTALL_APP" uninstall 0
sed "s/@VERSION@/$VERSION/" "$REPO/installer/app/ReadMe.txt" > "$stage/Read Me - Beni Oku.txt"
# Leak check (user name, home, host name) over everything that is shipped. The repository address
# (github.com/<owner>/...) in the read-me is public and allowed, even when the owner equals the user name.
pat="$(printf '%s|/Users/%s/|\\b%s\\b|%s\\.local' "$HOME" "$(id -un)" "$(id -un)" "$(hostname -s)")"
if grep -raoE -- ".{0,11}($pat)" "$stage" | grep -vE 'github\.com/[^/]*$' >&2; then echo "leak check FAILED" >&2; exit 1; fi
rm -f "$DIST/$NAME"
hdiutil create -quiet -volname "Cura 5.13 Elephant Foot N Layers" -srcfolder "$stage" -fs HFS+ -format UDZO -ov "$DIST/$NAME"
hdiutil verify -quiet "$DIST/$NAME"
( cd "$DIST" && shasum -a 256 Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.* > SHA256SUMS.txt && cat SHA256SUMS.txt )
