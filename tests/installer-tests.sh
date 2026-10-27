#!/bin/bash
# shellcheck disable=SC2016,SC2034  # check() evaluates its condition later (eval)
# Scenario tests for installer/efnl.sh (and the .run bundle), macOS.
#   tests/installer-tests.sh <official UltiMaker Cura.app> <payload dir> [run file]
# Every test runs with a fake HOME and EFNL_TEST_ROOT (system paths redirected), so the real profile,
# /Applications and LaunchServices are never touched; the official Cura.app is only read (and copied
# with APFS clones). The work folder ends in .noindex so that Spotlight does not register the test apps.
set -uo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
abs() { printf '%s/%s' "$(cd "$(dirname "$1")" && pwd -P)" "$(basename "$1")"; }
CURA="$(cd "$1" && pwd -P)"; PAYLOAD="$(cd "$2" && pwd -P)"; RUNFILE="${3:+$(abs "$3")}"
WORK="${EFNL_TEST_WORK:-/Users/Shared/efnl/installer-tests.noindex}"
EFNL="$REPO/installer/efnl.sh"
APPN="UltiMaker Cura 5.13 (Elephant Foot N Layers).app"
FILES=(Frameworks/CuraEngine Resources/share/cura/resources/definitions/fdmprinter.def.json
  Resources/share/cura/resources/i18n/tr_TR/fdmprinter.def.json.po Resources/share/cura/resources/i18n/tr_TR/LC_MESSAGES/fdmprinter.def.json.mo
  Resources/share/cura/resources/setting_visibility/expert.cfg Resources/share/uranium/plugins/LocalContainerProvider/LocalContainerProvider.py)
ORIG=(b7e19c3da83e83767529ad2711383c22b6fafb70f79b9fd7c2298b77bf5d28f7 8fbbf8b779e806bd8d0b0e2b8b9be17bdd26a575b7ea1875c20481eb2c7e11ee
  ace33455f77ad50ed5d10dbd2f1c2b5732d2c59dcc5e99a9e715ad1bd3f51a85 16dda401341e0805149bdcd674677bf5081413163c6b059255c637187599d3ad
  9b646941fa24799eda46ce207f586ab72687d7b02f837264287bb022b720a4ba d778d89795589c00f304447355ea67ead0e7498405b71053889eb6652432ffad)
PLIST_SHA=82d1a180a0f0e5a9a92e445f541b9fa3fb64dd946db942397a4b27c58452d4f7
PASS=0; FAIL=0
check() { if eval "$2"; then PASS=$((PASS+1)); echo "  PASS  $1"; else FAIL=$((FAIL+1)); echo "  FAIL  $1"; fi; }
sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
PH=(); for f in "${FILES[@]}"; do PH+=("$(awk -v f="$f" '$2==f{print $1}' "$PAYLOAD/SHA256SUMS")"); done
same_as() {  # same_as <app> <@P|@O>
  local i h; for i in "${!FILES[@]}"; do
    h="$(sha "$1/Contents/${FILES[$i]}")"
    [[ "$2" == @P && "$h" == "${PH[$i]}" || "$2" == @O && "$h" == "${ORIG[$i]}" ]] || return 1
  done
}
cura_untouched() { same_as "$CURA" @O && [[ "$(sha "$CURA/Contents/Info.plist")" == "$PLIST_SHA" ]]; }
signed_ok() { codesign --verify --deep --strict "$1" 2>/dev/null; }
same_as "$CURA" @O && signed_ok "$CURA" || { echo "not the official, unmodified Cura 5.13.0 app: $CURA"; exit 2; }

reset() {
  chmod -R u+w "$WORK" 2>/dev/null; rm -rf "$WORK"; mkdir -p "$WORK"
  export HOME="$WORK/home"; export EFNL_TEST_ROOT="$WORK/root"
  unset EFNL_TEST_FAIL EFNL_TEST_NEED_MB
  mkdir -p "$HOME/Applications" "$EFNL_TEST_ROOT/sys/Applications"
  PREFIX="$HOME/Applications/$APPN"
  PRO="$HOME/Library/Application Support/cura/5.13"; CCH="$PRO/cache"
  mkdir -p "$PRO/user" "$PRO/quality_changes" "$PRO/plugins/SomePlugin" "$CCH/definitions/5.13.0" "$CCH/definitions-efnl/5.13.0"
  printf '[general]\nvisible_settings = xy_offset;elephant_foot_compensation_layers;xy_offset_layer_0;elephant_foot_compensation_taper\ntheme = cura-light\ncategories_expanded = ;alternate_extra_perimeter;elephant_foot_compensation_layers;elephant_foot_compensation_taper;fill_outline_gaps\n' > "$PRO/cura.cfg"
  printf '[general]\r\nversion = 4\r\n\r\n[values]\r\nelephant_foot_compensation_layers = 4\r\nelephant_foot_compensation_taper = True\r\nxy_offset_layer_0 = -0.2\r\n' > "$PRO/user/custom_user.inst.cfg"
  printf '[values]\nelephant_foot_compensation_layers = 3\nlayer_height = 0.2\n' > "$PRO/quality_changes/my_profile.inst.cfg"
  printf 'elephant_foot_compensation_layers = keep\n' > "$PRO/plugins/SomePlugin/plugin.cfg"
  printf 'binary... elephant_foot_compensation_layers ...' > "$CCH/definitions-efnl/5.13.0/fdmprinter"
  printf 'binary... elephant_foot_compensation_layers ...' > "$CCH/definitions/5.13.0/fdmprinter"   # stale (should never happen)
  printf 'no added settings' > "$CCH/definitions/5.13.0/other_printer"
  printf 'sqlite' > "$CCH/containers.db"
}
run() { EFNL_PAYLOAD_DIR="$PAYLOAD" LANG="${TLANG:-en_US.UTF-8}" LC_ALL="" /bin/bash "$EFNL" "$@" >"$WORK/out" 2>"$WORK/err" </dev/null; RC=$?; sed 's/^/        /' "$WORK/err"; return 0; }
nostage() { [[ -z "$(find "$HOME/Applications" "$EFNL_TEST_ROOT/sys/Applications" -maxdepth 1 -name '.cura-5.13-efnl*' 2>/dev/null)" ]]; }
clone_cura() { mkdir -p "$(dirname "$1")"; cp -cR "$CURA" "$1"; }   # APFS clone: instant, no space

echo "T1 fresh install (Cura found in ~/Applications)"
reset; clone_cura "$HOME/Applications/UltiMaker Cura.app"; run install --yes
check 'exit 0' '[[ $RC == 0 ]]'
check 'six files = payload' 'same_as "$PREFIX" @P'
check 'code signature of the copy valid (ad hoc)' 'signed_ok "$PREFIX" && [[ "$(codesign -dv "$PREFIX" 2>&1)" == *Signature=adhoc* ]]'
check 'unchanged frameworks keep the Ultimaker signature' '[[ "$(codesign -dv "$PREFIX/Contents/Frameworks/libArcus.dylib" 2>&1)" == *TeamIdentifier=V4B3JXRRQS* ]]'
check 'own bundle identifier and name' '[[ $(plutil -extract CFBundleIdentifier raw "$PREFIX/Contents/Info.plist") == nl.ultimaker.cura_UltiMaker_Cura.efnl && $(plutil -extract CFBundleDisplayName raw "$PREFIX/Contents/Info.plist") == "UltiMaker Cura 5.13 (Elephant Foot N Layers)" ]]'
check 'no quarantine flag on the copy' '[[ -z "$(find "$PREFIX" -xattrname com.apple.quarantine 2>/dev/null | head -1)" ]]'
check 'manifest + uninstaller + info' '[[ -f $PREFIX/Contents/Resources/efnl/manifest && -x $PREFIX/Contents/Resources/efnl/uninstall && $(grep -c version=5.0.0 "$PREFIX/Contents/Resources/efnl/info") == 1 ]]'
check 'manifest lists six files + Info.plist' '[[ $(wc -l < "$PREFIX/Contents/Resources/efnl/manifest") -eq 7 ]]'
check 'patched engine starts inside the copy (libraries from Frameworks)' '"$PREFIX/Contents/Resources/CuraEngine" help 2>&1 | grep -q "version 5.13.0"'
check 'no staging folders left' 'nostage'
check 'source Cura.app untouched (files, Info.plist, signature)' 'same_as "$HOME/Applications/UltiMaker Cura.app" @O && signed_ok "$HOME/Applications/UltiMaker Cura.app" && cura_untouched'
check 'status exit 0' 'run status; [[ $RC == 0 ]] && grep -q "all files intact" "$WORK/out"'

echo "T2 reinstall over itself (explicit path)"
run install "$CURA" --yes
check 'exit 0' '[[ $RC == 0 ]]'
check 'files unchanged, signature valid' 'same_as "$PREFIX" @P && signed_ok "$PREFIX" && nostage'

echo "T3 uninstall removes the copy, cleans profile/cache"
run uninstall --yes
check 'exit 0' '[[ $RC == 0 ]]'
check 'copy removed, no leftovers' '[[ ! -e $PREFIX && $(ls -A "$HOME/Applications") == "UltiMaker Cura.app" ]]'
check 'cura.cfg visibility cleaned, other values kept' '! grep -q elephant_foot "$PRO/cura.cfg" && grep -qx "visible_settings = xy_offset;xy_offset_layer_0" "$PRO/cura.cfg" && grep -qx "theme = cura-light" "$PRO/cura.cfg"'
check 'cura.cfg expanded groups cleaned' 'grep -qx "categories_expanded = ;alternate_extra_perimeter;fill_outline_gaps" "$PRO/cura.cfg"'
check 'user profile cleaned (CRLF kept)' '! grep -q elephant_foot "$PRO/user/custom_user.inst.cfg" && grep -q $'"'"'xy_offset_layer_0 = -0.2\r'"'"' "$PRO/user/custom_user.inst.cfg"'
check 'quality_changes cleaned' '! grep -q elephant_foot "$PRO/quality_changes/my_profile.inst.cfg" && grep -q "layer_height = 0.2" "$PRO/quality_changes/my_profile.inst.cfg"'
check 'plugins folder untouched' 'grep -q elephant_foot "$PRO/plugins/SomePlugin/plugin.cfg"'
check 'own definition cache removed' '[[ ! -e $CCH/definitions-efnl ]]'
check 'stale shared fdmprinter cache deleted, other cache kept' '[[ ! -e $CCH/definitions/5.13.0/fdmprinter && -e $CCH/definitions/5.13.0/other_printer && -e $CCH/containers.db ]]'
check 'status exit 1' 'run status; [[ $RC == 1 ]]'

echo "T4 uninstall when nothing is installed"
run uninstall --yes
check 'exit 0' '[[ $RC == 0 ]]'

echo "T5 changed, unsigned or wrong Cura.app is refused"
reset; X="$WORK/src/UltiMaker Cura.app"; clone_cura "$X"; printf 'x' >> "$X/Contents/Resources/share/cura/resources/setting_visibility/expert.cfg"
run install "$X" --yes
check 'modified file -> exit 1, nothing written' '[[ $RC == 1 && ! -e $PREFIX ]] && nostage && grep -q "nothing was installed" "$WORK/err"'
rm -rf "$X"; clone_cura "$X"; codesign --force --sign - "$X" 2>/dev/null
run install "$X" --yes
check 're-signed (not Ultimaker) -> exit 1' '[[ $RC == 1 && ! -e $PREFIX ]] && grep -q "code signature" "$WORK/err"'
rm -rf "$X"; clone_cura "$X"; plutil -replace CFBundleShortVersionString -string 5.12.0 "$X/Contents/Info.plist"
run install "$X" --yes
check 'other version -> exit 1' '[[ $RC == 1 && ! -e $PREFIX ]]'
run install "$WORK/does-not-exist.app" --yes
check 'missing app -> exit 1' '[[ $RC == 1 ]]'
run install --yes
check 'no Cura found -> exit 1 with download hint' '[[ $RC == 1 ]] && grep -q "macos-ARM64.dmg" "$WORK/err"'

echo "T6 file of the copy changed after install -> removed anyway, WARNING, exit 0"
reset; run install "$CURA" --yes; chmod u+w "$PREFIX/Contents/Frameworks/CuraEngine"; printf x >> "$PREFIX/Contents/Frameworks/CuraEngine"
check 'status reports damage (exit 1)' 'run status; [[ $RC == 1 ]] && grep -q DAMAGED "$WORK/out"'
run uninstall --silent
check 'exit 0 with WARNING' '[[ $RC == 0 ]] && grep -q "^WARNING:" "$WORK/err"'
check 'copy removed' '[[ ! -e $PREFIX ]]'

echo "T7 foreign app/folder at the install location is not touched"
reset; mkdir -p "$PREFIX"; echo mine > "$PREFIX/file"
run install "$CURA" --yes
check 'exit 1, folder untouched' '[[ $RC == 1 && $(cat "$PREFIX/file") == mine ]]'
rm -rf "$PREFIX"; mkdir -p "$WORK/elsewhere"; ln -s "$WORK/elsewhere" "$PREFIX"
run install "$CURA" --yes
check 'symlink at install location -> exit 1' '[[ $RC == 1 && -z "$(ls -A "$WORK/elsewhere")" ]]'

echo "T8 Cura running from the copy -> refused"
# a process whose executable path is inside the copy (as Cura shows in ps)
reset; run install "$CURA" --yes; ( exec -a "$PREFIX/Contents/MacOS/UltiMaker-Cura" /bin/sleep 30 ) & SP=$!; sleep 0.5
run uninstall --yes
check 'uninstall exit 1' '[[ $RC == 1 ]] && grep -qi running "$WORK/err"'
run install "$CURA" --yes
check 'reinstall exit 1' '[[ $RC == 1 ]]'
check 'copy still intact' 'same_as "$PREFIX" @P'
kill $SP 2>/dev/null; wait $SP 2>/dev/null
run uninstall --yes
check 'uninstall after quitting -> exit 0' '[[ $RC == 0 && ! -e $PREFIX ]]'

echo "T9 failure during install -> nothing left behind"
reset; export EFNL_TEST_FAIL=write; run install "$CURA" --yes; unset EFNL_TEST_FAIL
check 'exit 1, no copy, no staging' '[[ $RC == 1 && ! -e $PREFIX ]] && nostage && grep -q "rolled back" "$WORK/err"'
reset; export EFNL_TEST_FAIL=sign; run install "$CURA" --yes; unset EFNL_TEST_FAIL
check 'failure while signing: exit 1, clean' '[[ $RC == 1 && ! -e $PREFIX ]] && nostage'
reset; export EFNL_TEST_FAIL=swap; run install "$CURA" --yes; unset EFNL_TEST_FAIL
check 'failure at final move: exit 1, clean' '[[ $RC == 1 && ! -e $PREFIX ]] && nostage'
reset; run install "$CURA" --yes; export EFNL_TEST_FAIL=write; run install "$CURA" --yes; unset EFNL_TEST_FAIL
check 'failed reinstall keeps the working installation' '[[ $RC == 1 ]] && same_as "$PREFIX" @P && signed_ok "$PREFIX" && nostage'
reset; export EFNL_TEST_FAIL=verify; run install "$CURA" --yes; unset EFNL_TEST_FAIL
check 'failure after swap: exit 1, copy removed' '[[ $RC == 1 && ! -e $PREFIX ]] && nostage && [[ -z $(ls -A "$HOME/Applications") ]]'
reset; run install "$CURA" --yes; touch "$PREFIX/Contents/Resources/efnl/marker-old"; export EFNL_TEST_FAIL=verify; run install "$CURA" --yes; unset EFNL_TEST_FAIL
check 'failure after swap on reinstall: previous installation restored' '[[ $RC == 1 && -e $PREFIX/Contents/Resources/efnl/marker-old ]] && same_as "$PREFIX" @P && nostage && [[ $(ls -A "$HOME/Applications") == "$APPN" ]]'

echo "T10 not enough disk space / no write permission"
reset; export EFNL_TEST_NEED_MB=99999999; run install "$CURA" --yes; unset EFNL_TEST_NEED_MB
check 'no space: exit 1, nothing written' '[[ $RC == 1 && ! -e $PREFIX ]] && nostage && grep -q "disk space" "$WORK/err"'
reset; chmod 555 "$HOME/Applications"
if [[ $EUID != 0 ]]; then run install "$CURA" --yes; check 'read-only ~/Applications: exit 1' '[[ $RC == 1 && ! -e $PREFIX ]]'; fi
chmod 755 "$HOME/Applications"

echo "T11 symlink inside the profile is refused"
reset; run install "$CURA" --yes; mkdir -p "$WORK/outside"; echo 'elephant_foot_compensation_layers = 2' > "$WORK/outside/victim.cfg"
ln -s "$WORK/outside" "$PRO/user/link"
run uninstall --yes
check 'exit 1' '[[ $RC == 1 ]]'
check 'file behind the link untouched' 'grep -q elephant_foot "$WORK/outside/victim.cfg"'
check 'copy removed nevertheless' '[[ ! -e $PREFIX ]]'

echo "T12 Turkish / English messages"
reset; TLANG=tr_TR.UTF-8 run install "$WORK/yok.app" --silent
check 'Turkish message' 'grep -q "bulunamadı" "$WORK/err"'
TLANG=C run install "$WORK/yok.app" --silent
check 'English message' 'grep -q "was not found" "$WORK/err"'
TLANG=tr_TR.UTF-8 run install "$CURA" --yes
check 'Turkish install message' '[[ $RC == 0 ]] && grep -q "Eklenti kuruldu" "$WORK/out"'

echo "T13 home folder with spaces and Turkish characters"
reset; export HOME="$WORK/ev klasörü/Kullanıcı Ğüşiöç"; mkdir -p "$HOME/Applications"
PREFIX="$HOME/Applications/$APPN"; PRO="$HOME/Library/Application Support/cura/5.13"; mkdir -p "$PRO"
printf 'visible_settings = a;elephant_foot_compensation_taper;b\n' > "$PRO/cura.cfg"
clone_cura "$HOME/Applications/UltiMaker Cura.app"; run install --yes
check 'found and installed, exit 0' '[[ $RC == 0 ]] && same_as "$PREFIX" @P && signed_ok "$PREFIX"'
run uninstall --yes
check 'profile cleaned' '[[ $RC == 0 ]] && grep -qx "visible_settings = a;b" "$PRO/cura.cfg" && [[ ! -e $PREFIX ]]'

echo "T14 --system mode (system paths redirected by EFNL_TEST_ROOT)"
reset; S="$EFNL_TEST_ROOT/sys/Applications"; clone_cura "$S/UltiMaker Cura.app"; run install --system --yes
check 'exit 0, found in /Applications, copy in /Applications' '[[ $RC == 0 ]] && same_as "$S/$APPN" @P'
check 'nothing in the user folders' '[[ ! -e $PREFIX ]]'
check 'installed uninstaller passes --system' 'grep -q -- "uninstall --system" "$S/$APPN/Contents/Resources/efnl/uninstall"'
run uninstall --system --yes
check 'uninstall exit 0, copy removed, Cura.app kept' '[[ $RC == 0 && ! -e "$S/$APPN" ]] && same_as "$S/UltiMaker Cura.app" @O'
check 'profile cleaned in the user account' '! grep -q elephant_foot "$PRO/cura.cfg"'

echo "T15 the patched copy itself is not accepted as source"
reset; run install "$CURA" --yes; run install "$PREFIX" --yes
check 'exit 1' '[[ $RC == 1 ]] && same_as "$PREFIX" @P'

echo "T16 damaged payload is refused"
reset; cp -R "$PAYLOAD" "$WORK/badpayload"; printf x >> "$WORK/badpayload/Resources/share/cura/resources/setting_visibility/expert.cfg"
EFNL_PAYLOAD_DIR="$WORK/badpayload" /bin/bash "$EFNL" install "$CURA" --yes >/dev/null 2>"$WORK/err" </dev/null; RC=$?
check 'exit 1, nothing written' '[[ $RC == 1 && ! -e $PREFIX ]]'

echo "T17 installed uninstaller works without the setup file"
reset; run install "$CURA" --yes
LANG=C /bin/sh -c "'$PREFIX/Contents/Resources/efnl/uninstall' --yes" >/dev/null 2>"$WORK/err" </dev/null; RC=$?
check 'exit 0, removed' '[[ $RC == 0 && ! -e $PREFIX ]]'
check 'profile cleaned' '! grep -q elephant_foot "$PRO/cura.cfg"'

echo "T18 usage errors / non-interactive without --yes"
reset; run frobnicate; check 'unknown action -> exit 2' '[[ $RC == 2 ]]'
run install --yes --bogus; check 'unknown option -> exit 2' '[[ $RC == 2 ]]'
run install "$CURA"; check 'no terminal, no --yes -> cancelled (exit 1), nothing written' '[[ $RC == 1 && ! -e $PREFIX ]]'

if [[ -n "$RUNFILE" ]]; then
  echo "T19 self-extracting .run file"
  reset; LANG=C /bin/bash "$RUNFILE" install "$CURA" --yes >/dev/null 2>"$WORK/err" </dev/null; RC=$?
  check '.run install exit 0' '[[ $RC == 0 ]]'
  check 'files = payload SHA of the release, signature valid' 'same_as "$PREFIX" @P && signed_ok "$PREFIX"'
  LANG=C /bin/bash "$RUNFILE" status >/dev/null 2>&1; check '.run status exit 0' '[[ $? == 0 ]]'
  LANG=C /bin/bash "$RUNFILE" uninstall --yes >/dev/null 2>"$WORK/err" </dev/null; RC=$?
  check '.run uninstall exit 0' '[[ $RC == 0 && ! -e $PREFIX ]]'
  cp "$RUNFILE" "$WORK/bad.run"; printf 'x' >> "$WORK/bad.run"
  /bin/bash "$WORK/bad.run" install "$CURA" --yes >/dev/null 2>"$WORK/err" </dev/null; RC=$?
  check 'damaged .run -> exit 1' '[[ $RC == 1 ]] && grep -q damaged "$WORK/err" && [[ ! -e $PREFIX ]]'
  check 'no temp folders left' '[[ -z "$(find "${TMPDIR:-/tmp}" -maxdepth 1 -name "cura-efnl.*" -user "$(id -u)" 2>/dev/null)" ]]'
fi

echo "T20 official Cura.app never modified"
check 'files, Info.plist and signature unchanged' 'cura_untouched && signed_ok "$CURA"'

chmod -R u+w "$WORK" 2>/dev/null; rm -rf "$WORK"
echo; echo "RESULT: $PASS passed, $FAIL failed"
[[ $FAIL == 0 ]]
