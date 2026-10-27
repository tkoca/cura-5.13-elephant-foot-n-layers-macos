#!/bin/bash
# Cura 5.13 - Elephant Foot N Layers @VERSION@ for macOS (Apple silicon) - self-extracting installer.
#   bash Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run install [CURA.APP] | uninstall | status  [--system] [--gui] [--yes|--silent]
# The embedded archive (after the __ARCHIVE__ line) is checked against the SHA-256 below before use.
set -euo pipefail
ARCHIVE_SHA256="@ARCHIVE_SHA256@"
ARCHIVE_LINE=@ARCHIVE_LINE@
self="$(cd "$(dirname -- "$0")" && pwd -P)/$(basename -- "$0")"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/cura-efnl.XXXXXX")"
trap 'rm -rf -- "$tmp"' EXIT
tail -n +"$ARCHIVE_LINE" -- "$self" > "$tmp/bundle.tar"
if [ "$(shasum -a 256 -- "$tmp/bundle.tar" | cut -d' ' -f1)" != "$ARCHIVE_SHA256" ]; then
  echo "ERROR: this installer file is damaged (checksum mismatch). Download it again." >&2; exit 1
fi
tar -xf "$tmp/bundle.tar" -C "$tmp" -o
rm -f -- "$tmp/bundle.tar"
set +e
EFNL_PROG="$(basename -- "$0")" /bin/bash "$tmp/installer/efnl.sh" "$@"
rc=$?
exit $rc
# shellcheck disable=SC2317
__ARCHIVE__
