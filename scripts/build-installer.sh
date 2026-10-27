#!/bin/bash
# Builds dist/Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run and dist/SHA256SUMS.txt
#   scripts/build-installer.sh <Cura-5.13.0.tar.gz> <Uranium-5.13.0.tar.gz> <patched CuraEngine> [dist-dir]
# Refuses binaries/resources that contain the builder's user name, home path or host name.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
CURA_SRC="$1"; URANIUM_SRC="$2"; ENGINE="$3"; mkdir -p "${4:-$REPO/dist}"; DIST="$(cd "${4:-$REPO/dist}" && pwd)"
VERSION="$(sed -n 's/^readonly VERSION="\(.*\)"/\1/p' "$REPO/installer/efnl.sh")"
NAME="Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run"
"$REPO/scripts/check-engine.sh" "$ENGINE" >/dev/null || { echo "engine check FAILED (scripts/check-engine.sh $ENGINE)" >&2; exit 1; }
work="$(mktemp -d)"; trap 'rm -rf -- "$work"' EXIT
python3 "$REPO/scripts/make_payload.py" "$CURA_SRC" "$URANIUM_SRC" "$ENGINE" "$work"
mkdir -p "$work/bundle/installer/lang"
cp "$REPO/installer/efnl.sh" "$work/bundle/installer/"; chmod 755 "$work/bundle/installer/efnl.sh"
cp "$REPO/installer/lang/"*.sh "$work/bundle/installer/lang/"; chmod 644 "$work/bundle/installer/lang/"*.sh
cp -R "$work/payload" "$work/bundle/installer/payload"
# Leak check (user name, home, host name) over everything that is shipped.
pat="$(printf '%s|/Users/%s/|\\b%s\\b|%s\\.local' "$HOME" "$(id -un)" "$(id -un)" "$(hostname -s)")"
if grep -raE -- "$pat" "$work/bundle" >/dev/null; then echo "leak check FAILED:" >&2; grep -ralE -- "$pat" "$work/bundle" >&2; exit 1; fi
python3 "$REPO/scripts/make_bundle.py" "$work/bundle" installer "$work/bundle.tar"
hdr="$(cat "$REPO/installer/run-header.sh")"
lines=$(( $(printf '%s\n' "$hdr" | wc -l) + 1 ))
{ printf '%s\n' "$hdr" | sed -e "s/@VERSION@/$VERSION/" -e "s/@ARCHIVE_SHA256@/$(shasum -a 256 "$work/bundle.tar" | cut -d' ' -f1)/" -e "s/@ARCHIVE_LINE@/$lines/"
  cat "$work/bundle.tar"; } > "$DIST/$NAME"
chmod 755 "$DIST/$NAME"
( cd "$DIST" && shasum -a 256 "$NAME" > SHA256SUMS.txt && cat SHA256SUMS.txt )
cp "$work/payload/SHA256SUMS" "$DIST/payload-SHA256SUMS.txt"
