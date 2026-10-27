#!/bin/bash
# Cura 5.13 - Elephant Foot N Layers: macOS installer / uninstaller (Apple Silicon).
#
#   efnl.sh install [CURA.APP] | uninstall | status   [--system] [--gui] [--yes|--silent]
#
# Model: the official UltiMaker Cura 5.13.0 app (arm64) is verified (Ultimaker code signature, version,
# SHA-256 of the files that change), copied into a staging folder, its six files and Info.plist are
# replaced in the copy, the copy is signed again (ad hoc, because its content changed) and moved into
# place atomically. The user's Cura.app is never modified.
#
# Install locations
#   user   : ~/Applications/UltiMaker Cura 5.13 (Elephant Foot N Layers).app
#   system : /Applications/UltiMaker Cura 5.13 (Elephant Foot N Layers).app  (sudo only if needed)
#
# On macOS Cura keeps the definition cache inside the profile (~/Library/Application Support/cura/5.13/cache),
# shared by every Cura 5.13 app. The patched LocalContainerProvider of the copy uses cache/definitions-efnl,
# so that it and the unmodified Cura.app never load each other's cached fdmprinter definition (Cura picks
# the cache by modification time).
#
# Works with the bash 3.2 that comes with macOS. Exit codes: 0 done (warnings on stderr as
# "WARNING: ..."), 1 not done / incomplete, 2 usage.
set -euo pipefail
umask 022

readonly VERSION="5.0.1"
readonly ID="cura-5.13-efnl"
readonly APP_NAME="UltiMaker Cura 5.13 (Elephant Foot N Layers).app"
readonly BUNDLE_ID="nl.ultimaker.cura_UltiMaker_Cura"
readonly NEW_BUNDLE_ID="nl.ultimaker.cura_UltiMaker_Cura.efnl"
readonly TEAM_ID="V4B3JXRRQS"            # Ultimaker B.V. (Developer ID)
readonly FILES=(
  "Frameworks/CuraEngine"
  "Resources/share/cura/resources/definitions/fdmprinter.def.json"
  "Resources/share/cura/resources/i18n/tr_TR/fdmprinter.def.json.po"
  "Resources/share/cura/resources/i18n/tr_TR/LC_MESSAGES/fdmprinter.def.json.mo"
  "Resources/share/cura/resources/setting_visibility/expert.cfg"
  "Resources/share/uranium/plugins/LocalContainerProvider/LocalContainerProvider.py"
)
readonly ORIGINAL_HASHES=(
  "b7e19c3da83e83767529ad2711383c22b6fafb70f79b9fd7c2298b77bf5d28f7"
  "8fbbf8b779e806bd8d0b0e2b8b9be17bdd26a575b7ea1875c20481eb2c7e11ee"
  "ace33455f77ad50ed5d10dbd2f1c2b5732d2c59dcc5e99a9e715ad1bd3f51a85"
  "16dda401341e0805149bdcd674677bf5081413163c6b059255c637187599d3ad"
  "9b646941fa24799eda46ce207f586ab72687d7b02f837264287bb022b720a4ba"
  "d778d89795589c00f304447355ea67ead0e7498405b71053889eb6652432ffad"
)
readonly PLIST="Info.plist"
readonly PLIST_HASH="82d1a180a0f0e5a9a92e445f541b9fa3fb64dd946db942397a4b27c58452d4f7"
readonly KEY_LAYERS="elephant_foot_compensation_layers"
readonly KEY_TAPER="elephant_foot_compensation_taper"
readonly MARK="# ${ID} (managed file, do not edit)"
readonly LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
NEED_MB=1100   # copy of Cura.app ~480 MB during staging + the previous copy during an update + margin

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PAYLOAD_DIR="${EFNL_PAYLOAD_DIR:-$HERE/payload}"   # payload/<FILES> + payload/SHA256SUMS

# ------------------------------------------------------------------ language
lang_tag="${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}"
if [[ -z "$lang_tag" ]]; then lang_tag="$(defaults read -g AppleLocale 2>/dev/null || true)"; fi
if [[ "$lang_tag" == tr* ]]; then LANGF="tr"; else LANGF="en"; fi
# shellcheck source=lang/en.sh
source "$HERE/lang/$LANGF.sh"
m() { local n="MSG_$1"; shift; # shellcheck disable=SC2059
  printf "${!n}" "$@"; }

# ------------------------------------------------------------------ options
ACTION=""; SRC_APP=""; SYSTEM=0; GUI=0; YES=0; SILENT=0; MACHINE_PART=0
PROG="${EFNL_PROG:-$(basename "$0")}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    install|uninstall|status) [[ -z "$ACTION" ]] || { m bad_args "$1" >&2; echo >&2; exit 2; }; ACTION="$1" ;;
    --system) SYSTEM=1 ;;
    --gui) GUI=1 ;;
    --yes|-y) YES=1 ;;
    --silent) YES=1; SILENT=1 ;;
    --machine-part) MACHINE_PART=1 ;;                 # internal: root half of --system
    -h|--help|help) m usage "$PROG"; echo; exit 0 ;;
    -*) m bad_args "$1" >&2; echo >&2; exit 2 ;;
    *) if [[ "$ACTION" == install && -z "$SRC_APP" ]]; then SRC_APP="${1%/}"; else m bad_args "$1" >&2; echo >&2; exit 2; fi ;;
  esac
  shift
done
[[ -n "$ACTION" ]] || { m usage "$PROG" >&2; echo >&2; exit 2; }

# ------------------------------------------------------------------ locations
TEST_ROOT="${EFNL_TEST_ROOT:-}"
[[ -n "$TEST_ROOT" && -n "${EFNL_TEST_NEED_MB:-}" ]] && NEED_MB="$EFNL_TEST_NEED_MB"
SYS="${TEST_ROOT:+$TEST_ROOT/sys}"
if [[ $SYSTEM == 1 ]]; then PREFIX="$SYS/Applications/$APP_NAME"; else PREFIX="$HOME/Applications/$APP_NAME"; fi
STATE="$PREFIX/Contents/Resources/efnl"
PROFILE="$HOME/Library/Application Support/cura/5.13"
SHARED_CACHE="$PROFILE/cache"
OWN_CACHE="$SHARED_CACHE/definitions-efnl"

# ------------------------------------------------------------------ output
WARNINGS=()
warn() { WARNINGS+=("$1"); }
osa_text() { local t="$1"; t="${t//\\/\\\\}"; t="${t//\"/\\\"}"; printf '%s' "$t"; }
# Tests: EFNL_TEST_DIALOG_LOG (with EFNL_TEST_ROOT) receives the dialog texts instead of showing them.
DIALOG_LOG=""; [[ -n "${EFNL_TEST_ROOT:-}" ]] && DIALOG_LOG="${EFNL_TEST_DIALOG_LOG:-}"
dialog() {  # dialog <osascript command> <kind> <text>: 0 = OK/Yes
  if [[ -n "$DIALOG_LOG" ]]; then printf '%s: %s\n' "$2" "$3" >> "$DIALOG_LOG"; return 0; fi
  osascript -e "$1" >/dev/null 2>&1
}
say() {
  [[ $SILENT == 1 ]] || printf '%s\n' "$1"
  # Progress in --gui mode (Install/Uninstall apps of the .dmg): a notification, no button to press.
  if [[ $GUI == 1 && $MACHINE_PART == 0 && $SILENT == 0 ]]; then
    dialog "display notification \"$(osa_text "$1")\" with title \"$(osa_text "$(m title)")\"" progress "$1" || true
  fi
}
report() {  # report <error|warning|info> <text>
  local kind="$1" text="$2"
  if [[ $SILENT == 1 || $MACHINE_PART == 1 ]]; then
    case "$kind" in error) printf 'ERROR: %s\n' "$text" >&2 ;; warning) printf 'WARNING: %s\n' "$text" >&2 ;; *) [[ $SILENT == 1 ]] || printf '%s\n' "$text" ;; esac
    return
  fi
  if [[ $GUI == 1 ]]; then
    local icon=note; [[ $kind == error ]] && icon=stop; [[ $kind == warning ]] && icon=caution
    dialog "display dialog \"$(osa_text "$text")\" with title \"$(osa_text "$(m title)")\" buttons {\"OK\"} default button 1 with icon $icon" "$kind" "$text" || true
  fi
  case "$kind" in error) printf 'ERROR: %s\n' "$text" >&2 ;; warning) printf 'WARNING: %s\n' "$text" >&2 ;; *) printf '%s\n' "$text" ;; esac
}
die() { report error "$1"; exit 1; }
confirm() {
  [[ $YES == 1 ]] && return 0
  if [[ $GUI == 1 ]]; then
    dialog "display dialog \"$(osa_text "$1")\" with title \"$(osa_text "$(m title)")\" buttons {\"$(osa_text "$(m no)")\", \"$(osa_text "$(m yes)")\"} default button 2 cancel button 1 with icon caution" question "$1"
    return
  fi
  [[ -t 0 ]] || return 1
  local answer; printf '%s\n[y/N/e/H] ' "$1"; read -r answer || return 1
  [[ "$answer" =~ ^[yYeE] ]]
}
finish() {  # prints warnings, exits 0
  local w; for w in "${WARNINGS[@]+"${WARNINGS[@]}"}"; do report warning "$w"; done
  exit 0
}

# ------------------------------------------------------------------ helpers
sha() { shasum -a 256 -- "$1" | cut -d' ' -f1; }
for tool in shasum ditto codesign plutil xattr tar awk mktemp find df ps; do command -v "$tool" >/dev/null 2>&1 || die "$(m missing_tool "$tool")"; done
[[ "$(uname -s)" == Darwin ]] || die "$(m not_mac "$(uname -s)")"
[[ "$(sysctl -n hw.optional.arm64 2>/dev/null || echo 0)" == 1 ]] || die "$(m not_arm "$(uname -m)")"

no_links() {  # fails if any existing component of the path (below /) is a symlink
  local p="$1" cur="" part
  local IFS=/
  for part in $p; do
    [[ -z "$part" ]] && continue
    cur="$cur/$part"
    # macOS system links above the home folder (/var, /tmp, /etc) are allowed.
    if [[ -L "$cur" && "$cur" != /var && "$cur" != /tmp && "$cur" != /etc ]]; then return 1; fi
    [[ -e "$cur" ]] || break
  done
  return 0
}

running_pid() {  # prints the PID of a process whose executable is inside the app bundle $1
  local dir="$1/Contents/" pid cmd
  while read -r pid cmd; do
    if [[ "$cmd" == "$dir"* ]]; then printf '%s' "$pid"; return 0; fi
  done < <(ps -axww -o pid= -o command= 2>/dev/null)
  return 1
}
ensure_stopped() { local pid; if pid="$(running_pid "$1")"; then die "$(m running "$1" "$pid")"; fi; }

installed() { [[ -f "$STATE/manifest" && ! -L "$STATE/manifest" ]]; }

payload_hash() {  # payload_hash <index>
  awk -v f="${FILES[$1]}" '{ n=$0; sub(/^[0-9a-f]+  /, "", n); if (n == f) { print $1; exit } }' "$PAYLOAD_DIR/SHA256SUMS"
}
check_payload() {
  [[ -f "$PAYLOAD_DIR/SHA256SUMS" ]] || die "$(m bad_payload SHA256SUMS)"
  local i h
  for i in "${!FILES[@]}"; do
    h="$(payload_hash "$i")"
    [[ -n "$h" && -f "$PAYLOAD_DIR/${FILES[$i]}" && "$(sha "$PAYLOAD_DIR/${FILES[$i]}")" == "$h" ]] || die "$(m bad_payload "${FILES[$i]}")"
  done
}

atomic_write() {  # atomic_write <dest> <mode>  (content on stdin)
  local dest="$1" tmp
  mkdir -p -- "$(dirname -- "$dest")"
  tmp="$(mktemp "$(dirname -- "$dest")/.${ID}.XXXXXX")" || return 1
  { cat > "$tmp" && chmod "$2" "$tmp" && mv -f -- "$tmp" "$dest"; } || { rm -f -- "$tmp"; return 1; }
}

remove_dir() {  # rename first so that a half-deleted folder is never taken for an installation
  local d="$1" doomed
  [[ -e "$d" || -L "$d" ]] || return 0
  if [[ -L "$d" ]]; then rm -f -- "$d"; return 0; fi
  doomed="$(dirname -- "$d")/.$ID.delete-$$-$RANDOM"
  mv -- "$d" "$doomed" && rm -rf -- "$doomed"
}

ls_register() {  # ls_register <-f|-u> <app>: Launchpad / Spotlight / "Open With" (not in tests)
  [[ -z "$TEST_ROOT" && -x "$LSREGISTER" ]] || return 0
  "$LSREGISTER" "$1" "$2" >/dev/null 2>&1 || true
}

# ------------------------------------------------------------------ Cura.app lookup and verification
plist_get() { /usr/libexec/PlistBuddy -c "Print :$2" "$1/Contents/Info.plist" 2>/dev/null || true; }
is_cura_513() { [[ -d "$1/Contents" && "$(plist_get "$1" CFBundleIdentifier)" == "$BUNDLE_ID" && "$(plist_get "$1" CFBundleShortVersionString)" == 5.13.0 ]]; }

find_cura() {
  local c found=()
  say "$(m searching)"
  for c in "$SYS/Applications/UltiMaker Cura.app" "$HOME/Applications/UltiMaker Cura.app"; do
    is_cura_513 "$c" && found+=("$c")
  done
  if [[ ${#found[@]} -eq 0 && -z "$TEST_ROOT" ]] && command -v mdfind >/dev/null 2>&1; then
    while IFS= read -r c; do
      [[ "$c" == *"/$APP_NAME" ]] && continue
      is_cura_513 "$c" && found+=("$c")
    done < <(mdfind "kMDItemCFBundleIdentifier == '$BUNDLE_ID'" 2>/dev/null)
  fi
  if [[ ${#found[@]} -eq 0 ]]; then
    for c in "$SYS"/Applications/*Cura*.app "$HOME"/Applications/*Cura*.app; do
      [[ -d "$c" && "$c" != *"/$APP_NAME" ]] && warn "$(m other_cura "$c")"
    done
    local w; for w in "${WARNINGS[@]+"${WARNINGS[@]}"}"; do report warning "$w"; done
    die "$(m not_found "$PROG")"
  fi
  if [[ ${#found[@]} -eq 1 ]]; then SRC_APP="${found[0]}"; return; fi
  [[ $YES == 0 && -t 0 ]] || die "$(m several_silent)"
  say "$(m several)"; local i; for i in "${!found[@]}"; do say "  $((i+1))) ${found[$i]}"; done
  local n; printf '%s' "$(m choose)"; read -r n || n=1; n="${n:-1}"
  [[ "$n" =~ ^[0-9]+$ && $n -ge 1 && $n -le ${#found[@]} ]] || die "$(m cancelled)"
  SRC_APP="${found[$((n-1))]}"
}

verify_cura() {  # verify_cura <app>: official, unmodified UltiMaker Cura 5.13.0 for Apple Silicon
  local app="$1" i info
  is_cura_513 "$app" || die "$(m bad_app "$app")"
  [[ "$(lipo -archs "$app/Contents/MacOS/UltiMaker-Cura" 2>/dev/null)" == arm64 ]] || die "$(m intel_app "$app")"
  codesign --verify --deep --strict -- "$app" >/dev/null 2>&1 || die "$(m bad_signature "$app")"
  info="$(codesign -dv -- "$app" 2>&1 || true)"
  [[ "$info" == *"TeamIdentifier=$TEAM_ID"* ]] || die "$(m bad_signature "$app")"
  [[ "$(sha "$app/Contents/$PLIST")" == "$PLIST_HASH" ]] || die "$(m bad_app "$app")"
  for i in "${!FILES[@]}"; do
    [[ -f "$app/Contents/${FILES[$i]}" && "$(sha "$app/Contents/${FILES[$i]}")" == "${ORIGINAL_HASHES[$i]}" ]] || die "$(m bad_app "$app")"
  done
}

# ------------------------------------------------------------------ elevation (--system)
run_machine_part() {  # re-runs this script as root for the machine part when /Applications is not writable
  if [[ -n "$TEST_ROOT" || $EUID == 0 || -w "$(dirname -- "$PREFIX")" ]]; then return 1; fi   # caller does the work itself
  local args=("$ACTION" --system --machine-part --yes) rc
  [[ $SILENT == 1 ]] && args+=(--silent)
  [[ "$ACTION" == install ]] && args=("$ACTION" "$SRC_APP" --system --machine-part --yes)
  command -v sudo >/dev/null 2>&1 || die "$(m no_sudo)"
  set +e
  sudo -- env LANG="${LANG:-}" LC_ALL="${LC_ALL:-}" EFNL_PAYLOAD_DIR="$PAYLOAD_DIR" EFNL_PROG="$PROG" /bin/bash "$HERE/efnl.sh" "${args[@]}"
  rc=$?
  set -e
  [[ $rc == 0 ]] || die "$(m elev_failed "$rc")"
  return 0
}

# ------------------------------------------------------------------ install
machine_install() {
  local parent stage app old="" i
  parent="$(dirname -- "$PREFIX")"
  mkdir -p -- "$parent" 2>/dev/null || die "$(m no_write "$parent")"
  [[ -w "$parent" ]] || die "$(m no_write "$parent")"
  no_links "$PREFIX" || die "$(m foreign_dir "$PREFIX")"
  if [[ -e "$PREFIX" ]] && ! installed; then die "$(m foreign_dir "$PREFIX")"; fi
  ensure_stopped "$PREFIX"
  local free_mb; free_mb="$(df -Pm -- "$parent" | awk 'NR==2 {print $4}')"
  [[ "$free_mb" =~ ^[0-9]+$ ]] || free_mb=0
  (( free_mb >= NEED_MB )) || die "$(m no_space "$parent" "$free_mb" "$NEED_MB")"

  stage="$(mktemp -d "$parent/.$ID.new-XXXXXX")" || die "$(m no_write "$parent")"
  # shellcheck disable=SC2064
  trap "rm -rf -- '$stage'" EXIT
  fail() { rm -rf -- "$stage"; trap - EXIT; die "$1"; }
  cleanup_fail() { fail "$(m failed_rollback "$1")"; }

  say "$(m copying)"
  app="$stage/$APP_NAME"
  # --clone: on APFS the unchanged files share their blocks with Cura.app (no extra disk space).
  ditto --clone --noqtn -- "$SRC_APP" "$app" 2>/dev/null || fail "$(m copy_failed)"
  # The copy is a new, locally modified app: it is not a download, so it carries no quarantine flag.
  xattr -dr com.apple.quarantine "$app" 2>/dev/null || true
  for i in "${!FILES[@]}"; do
    [[ -f "$app/Contents/${FILES[$i]}" && "$(sha "$app/Contents/${FILES[$i]}")" == "${ORIGINAL_HASHES[$i]}" ]] || fail "$(m layout_bad "${FILES[$i]}")"
  done
  [[ "$(sha "$app/Contents/$PLIST")" == "$PLIST_HASH" ]] || fail "$(m layout_bad "$PLIST")"

  if [[ -n "$TEST_ROOT" && "${EFNL_TEST_FAIL:-}" == write ]]; then cleanup_fail "test"; fi
  # Replace the files with the payload (each verified), then Info.plist (own name and bundle identifier).
  local manifest=""
  for i in "${!FILES[@]}"; do
    local f="$app/Contents/${FILES[$i]}" ph; ph="$(payload_hash "$i")"
    cp -- "$PAYLOAD_DIR/${FILES[$i]}" "$f.efnl-tmp" || cleanup_fail "write"
    [[ "$(sha "$f.efnl-tmp")" == "$ph" ]] || cleanup_fail "$(m verify_failed "${FILES[$i]}")"
    if [[ $i == 0 ]]; then chmod 755 "$f.efnl-tmp"; else chmod 644 "$f.efnl-tmp"; fi
    mv -f -- "$f.efnl-tmp" "$f"
    manifest+="${FILES[$i]}|${ORIGINAL_HASHES[$i]}|$ph"$'\n'
  done
  local pl="$app/Contents/$PLIST" display
  display="$(source "$HERE/lang/en.sh"; printf '%s' "$MSG_app_name")"
  { plutil -replace CFBundleIdentifier -string "$NEW_BUNDLE_ID" "$pl" &&
    plutil -replace CFBundleName -string "UltiMaker Cura EFNL" "$pl" &&
    plutil -replace CFBundleDisplayName -string "$display" "$pl" &&
    plutil -replace CFBundleGetInfoString -string "UltiMaker Cura 5.13.0 + Elephant Foot N Layers $VERSION" "$pl" &&
    plutil -lint -s "$pl"; } || cleanup_fail "Info.plist"
  manifest+="$PLIST|$PLIST_HASH|$(sha "$pl")"$'\n'

  # The uninstaller lives inside the app (works even if the installer file is deleted).
  local st="$app/Contents/Resources/efnl"
  mkdir -p "$st/lang" "$st/payload"
  cp -- "$HERE/efnl.sh" "$st/efnl.sh"; cp -- "$HERE"/lang/*.sh "$st/lang/"
  cp -- "$PAYLOAD_DIR/SHA256SUMS" "$st/payload/SHA256SUMS"
  local mode=user; [[ $SYSTEM == 1 ]] && mode=system
  atomic_write "$st/uninstall" 755 <<EOF
#!/bin/sh
$MARK
exec /bin/bash "$PREFIX/Contents/Resources/efnl/efnl.sh" uninstall $([[ $SYSTEM == 1 ]] && echo --system) "\$@"
EOF
  printf 'version=%s\nmode=%s\nsource=%s\ninstalled=%s\n' "$VERSION" "$mode" "$SRC_APP" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$st/info"
  printf '%s' "$manifest" > "$st/manifest"   # marks a complete installation
  chmod -R go-w "$app"
  # Files copied from a downloaded installer (.dmg) may carry its quarantine flag; the copy must not.
  xattr -dr com.apple.quarantine "$app" 2>/dev/null || true

  # The content changed, so Ultimaker's signature no longer matches the bundle: sign the copy again
  # (ad hoc, same entitlements). The unchanged frameworks keep Ultimaker's signatures.
  say "$(m signing)"
  if [[ -n "$TEST_ROOT" && "${EFNL_TEST_FAIL:-}" == sign ]]; then cleanup_fail "codesign"; fi
  codesign --force --sign - --preserve-metadata=entitlements -- "$app" >/dev/null 2>&1 || cleanup_fail "codesign"
  codesign --verify --deep --strict -- "$app" >/dev/null 2>&1 || cleanup_fail "codesign"

  # Swap into place. The previous installation (if any) is kept until the new one is verified,
  # so that any failure restores the exact previous state.
  if [[ -e "$PREFIX" ]]; then
    old="$parent/.$ID.old-$$-$RANDOM"
    mv -- "$PREFIX" "$old" || cleanup_fail "rename"
    if ! mv -- "$app" "$PREFIX"; then mv -- "$old" "$PREFIX"; cleanup_fail "rename"; fi
  elif [[ -n "$TEST_ROOT" && "${EFNL_TEST_FAIL:-}" == swap ]]; then cleanup_fail "test"
  else
    mv -- "$app" "$PREFIX" || cleanup_fail "rename"
  fi
  rollback() {  # rollback <reason>: remove the new copy, put the previous one back
    rm -rf -- "$PREFIX"
    [[ -n "$old" ]] && mv -- "$old" "$PREFIX"
    rm -rf -- "$stage"; trap - EXIT
    die "$(m failed_rollback "$1")"
  }
  for i in "${!FILES[@]}"; do
    [[ "$(sha "$PREFIX/Contents/${FILES[$i]}")" == "$(payload_hash "$i")" ]] || rollback "$(m verify_failed "${FILES[$i]}")"
  done
  if [[ -n "$TEST_ROOT" && "${EFNL_TEST_FAIL:-}" == verify ]]; then rollback "test"; fi
  codesign --verify --deep --strict -- "$PREFIX" >/dev/null 2>&1 || rollback "codesign"
  [[ -n "$old" ]] && rm -rf -- "$old"
  rm -rf -- "$stage"; trap - EXIT
  ls_register -f "$PREFIX"
}

do_install() {
  [[ $MACHINE_PART == 1 || $SYSTEM == 0 || -n "$TEST_ROOT" || $EUID != 0 ]] || die "$(m need_root)"
  check_payload
  if [[ -z "$SRC_APP" ]]; then find_cura; fi
  [[ -d "$SRC_APP" ]] || die "$(m not_found "$PROG")"
  SRC_APP="$(cd "$SRC_APP" && pwd -P)"
  [[ "$SRC_APP" != "$PREFIX" ]] || die "$(m bad_app "$SRC_APP")"
  say "$(m checking "$SRC_APP")"
  verify_cura "$SRC_APP"
  if [[ $MACHINE_PART == 0 ]]; then
    if installed; then confirm "$(m confirm_update "$PREFIX")" || die "$(m cancelled)"
    else confirm "$(m confirm_install "$PREFIX" "$SRC_APP")" || die "$(m cancelled)"; fi
  fi
  if [[ $SYSTEM == 1 && $MACHINE_PART == 0 ]] && run_machine_part; then :; else machine_install; fi
  [[ $MACHINE_PART == 1 ]] && finish
  report info "$(m installed "$PREFIX")"
  finish
}

# ------------------------------------------------------------------ uninstall
machine_uninstall() {
  installed || return 0
  no_links "$PREFIX" || die "$(m foreign_dir "$PREFIX")"
  ensure_stopped "$PREFIX"
  # Report files of the copy that changed after installation (they go away with the copy).
  local f _orig ph
  while IFS='|' read -r f _orig ph; do
    [[ -n "$f" ]] || continue
    if [[ ! -f "$PREFIX/Contents/$f" || "$(sha "$PREFIX/Contents/$f")" != "$ph" ]]; then warn "$(m changed_file "$f")"; fi
  done < "$STATE/manifest"
  ls_register -u "$PREFIX"
  # Manifest first: without it the folder is no longer treated as an installation.
  rm -f -- "$STATE/manifest"
  remove_dir "$PREFIX"
}

clean_cfg_file() {  # clean_cfg_file <file> <1 = cura.cfg (setting-key lists too)>
  local f="$1" vis="$2" tmp
  grep -qE "$KEY_LAYERS|$KEY_TAPER" -- "$f" || return 0
  tmp="$(mktemp "$(dirname -- "$f")/.${ID}.XXXXXX")"
  awk -v vis="$vis" -v a="$KEY_LAYERS" -v b="$KEY_TAPER" '
    {
      line = $0; cr = ""
      if (sub(/\r$/, "", line)) cr = "\r"
      if (line ~ "^[ \t]*(" a "|" b ")[ \t]*=") next
      if (vis == 1 && match(line, /^((custom_)?visible_settings|categories_expanded)[ \t]*=[ \t]*/)) {
        head = substr(line, 1, RLENGTH); rest = substr(line, RLENGTH + 1)
        n = split(rest, parts, ";"); out = ""; first = 1
        for (i = 1; i <= n; i++) {
          p = parts[i]; t = p; gsub(/^[ \t]+|[ \t]+$/, "", t)
          if (t == a || t == b) continue
          out = first ? p : out ";" p; first = 0
        }
        line = head out
      }
      print line cr
    }' "$f" > "$tmp" || { rm -f -- "$tmp"; return 1; }
  if cmp -s -- "$tmp" "$f"; then rm -f -- "$tmp"; else chmod "$(stat -f %Lp "$f")" "$tmp" 2>/dev/null || true; mv -f -- "$tmp" "$f"; fi
  if grep -qE "$KEY_LAYERS|$KEY_TAPER" -- "$f"; then warn "$(m unknown_form "$f")"; fi
}

clean_profile() {
  local link f
  [[ -e "$PROFILE" ]] || return 0
  no_links "$PROFILE" || { report error "$(m profile_link "$PROFILE")"; return 1; }
  link="$(find "$PROFILE" -path "$PROFILE/plugins" -prune -o -type l -print -quit 2>/dev/null)"
  [[ -z "$link" ]] || { report error "$(m profile_link "$link")"; return 1; }
  if [[ -f "$PROFILE/cura.cfg" ]]; then clean_cfg_file "$PROFILE/cura.cfg" 1; fi
  while IFS= read -r -d '' f; do
    [[ "$f" == "$PROFILE/cura.cfg" ]] && continue
    clean_cfg_file "$f" 0
  done < <(find "$PROFILE" \( -path "$PROFILE/plugins" -o -path "$SHARED_CACHE" \) -prune -o -type f -name '*.cfg' -print0)
  # Definition cache: the add-on's own folder, and (should it ever contain them) cached definitions
  # of the shared folder that contain the add-on settings.
  [[ -d "$OWN_CACHE" ]] && rm -rf -- "$OWN_CACHE"
  if [[ -d "$SHARED_CACHE" ]]; then
    while IFS= read -r -d '' f; do
      grep -qaF -- "$KEY_LAYERS" "$f" && rm -f -- "$f"
    done < <(find "$SHARED_CACHE" -type f -print0)
  fi
  return 0
}

do_uninstall() {
  if [[ $MACHINE_PART == 0 ]] && ! installed; then
    # Not installed: still clean leftovers in the profile (idempotent), like Windows.
    clean_profile || exit 1
    report info "$(m not_installed)"; finish
  fi
  if [[ $MACHINE_PART == 0 ]]; then confirm "$(m confirm_uninstall)" || die "$(m cancelled)"; fi
  if [[ $SYSTEM == 1 && $MACHINE_PART == 0 ]]; then
    ensure_stopped "$PREFIX"
    run_machine_part || machine_uninstall
  else
    machine_uninstall
  fi
  [[ $MACHINE_PART == 1 ]] && finish
  clean_profile || exit 1   # runs as the calling user
  report info "$(m removed)"
  finish
}

# ------------------------------------------------------------------ status
do_status() {
  if ! installed; then say "$(m status_none "$PREFIX")"; exit 1; fi
  local bad="" ver f _orig ph
  ver="$(sed -n 's/^version=//p' "$STATE/info" 2>/dev/null)"
  while IFS='|' read -r f _orig ph; do
    [[ -n "$f" ]] || continue
    [[ -f "$PREFIX/Contents/$f" && "$(sha "$PREFIX/Contents/$f")" == "$ph" ]] || bad+="$f "
  done < "$STATE/manifest"
  codesign --verify --deep --strict -- "$PREFIX" >/dev/null 2>&1 || bad+="(code signature) "
  if [[ -z "$bad" ]]; then say "$(m status_installed "$PREFIX" "$ver" "$(m status_intact)")"; exit 0; fi
  say "$(m status_installed "$PREFIX" "$ver" "$(m status_damaged "$bad")")"; exit 1
}

case "$ACTION" in
  install) do_install ;;
  uninstall) do_uninstall ;;
  status) do_status ;;
esac
