# shellcheck shell=bash
# English messages (MSG_<key>, bash 3.2: no associative arrays). %s placeholders are filled with printf.
# shellcheck disable=SC2034
MSG_title="Cura 5.13 - Elephant Foot N Layers"
MSG_usage="Usage: %s {install [CURA.APP] | uninstall | status} [--system] [--gui] [--yes|--silent]

  install    Checks the official UltiMaker Cura 5.13.0 app and installs a patched copy of it as
             \"UltiMaker Cura 5.13 (Elephant Foot N Layers)\". Your Cura.app is not changed.
  uninstall  Removes the patched copy and removes the add-on settings from your Cura profile and
             the definition cache.
  status     Shows whether the add-on is installed and whether its files are intact.

  --system   Install for all users in /Applications (asks for an administrator password only if needed).
  --gui      Ask and report with dialog windows.
  --yes      Do not ask for confirmation.  --silent: --yes, messages only on stderr.
Exit code: 0 = done, 1 = not done or incomplete (a message explains why)."
MSG_bad_args="Unknown argument: %s"
MSG_missing_tool="Required program not found: %s"
MSG_not_mac="This installer is for macOS; this system is %s."
MSG_not_arm="Only Macs with Apple silicon (M1 or newer) are supported; this Mac is %s."
MSG_searching="Searching for UltiMaker Cura 5.13.0 ..."
MSG_not_found="The official UltiMaker Cura 5.13.0 app was not found. Install UltiMaker-Cura-5.13.0-macos-ARM64.dmg from https://github.com/Ultimaker/Cura/releases/tag/5.13.0 (drag it to Applications), or pass its location:
  %s install \"/Applications/UltiMaker Cura.app\""
MSG_other_cura="Note: found %s, but it is not UltiMaker Cura 5.13.0."
MSG_several="Several UltiMaker Cura 5.13.0 apps were found:"
MSG_choose="Number of the app to use (Enter = 1): "
MSG_several_silent="Several UltiMaker Cura 5.13.0 apps were found; pass the location explicitly."
MSG_checking="Checking %s ..."
MSG_bad_app="This is not the official, unmodified UltiMaker Cura 5.13.0 for macOS; nothing was installed:
%s
Only UltiMaker Cura 5.13.0 from UltiMaker-Cura-5.13.0-macos-ARM64.dmg (UltiMaker GitHub release) is supported. If it was changed, install it again from the dmg."
MSG_intel_app="This is the Intel (X64) build of Cura; on Apple silicon only the ARM64 build is supported. Install UltiMaker-Cura-5.13.0-macos-ARM64.dmg; nothing was installed:
%s"
MSG_bad_signature="The code signature of this app is not intact or not from Ultimaker B.V.; nothing was installed:
%s
Install UltiMaker Cura 5.13.0 again from the official dmg."
MSG_bad_payload="The setup file is damaged (%s); nothing was installed. Download it again."
MSG_confirm_install="Install elephant foot compensation for the first N layers into a patched copy of UltiMaker Cura 5.13.0?

New app: %s
Copied from: %s (stays unchanged and can still be used)."
MSG_confirm_update="The add-on is already installed. Reinstall (update) it?

Location: %s"
MSG_confirm_uninstall="Remove the add-on (the patched Cura app) and its settings from your Cura profile?"
MSG_cancelled="Cancelled; nothing was changed."
MSG_running="Cura is running from %s (process %s). Quit it and try again."
MSG_foreign_dir="%s exists but was not created by this add-on; nothing was installed. Move or remove it and try again."
MSG_no_space="Not enough free disk space in %s (%s MB free, %s MB needed); nothing was installed."
MSG_no_write="Cannot write to %s; nothing was installed."
MSG_copying="Copying Cura.app ..."
MSG_copy_failed="Cura.app could not be copied; nothing was installed."
MSG_signing="Signing the patched copy ..."
MSG_layout_bad="The copied app does not contain the expected Cura 5.13.0 file %s; nothing was installed."
MSG_verify_failed="A file could not be verified after writing: %s; nothing was installed."
MSG_failed_rollback="Installation failed (%s); all changes were rolled back."
MSG_installed="The add-on is installed. Start \"UltiMaker Cura 5.13 (Elephant Foot N Layers)\" from Launchpad, Spotlight or:
  %s
Settings: Walls > \"Elephant Foot Compensation Layer Count\" and \"Elephant Foot Gradual Compensation\" (Expert visibility)."
MSG_not_installed="The add-on is not installed; nothing to do."
MSG_changed_file="This file of the patched copy changed after installation; it was removed together with the copy: %s"
MSG_removed="The add-on was removed. The profile settings and the definition cache were cleaned."
MSG_profile_link="Stopped for safety: the Cura profile contains a symbolic link: %s
The patched copy was removed; the profile was not cleaned."
MSG_unknown_form="An add-on setting remains in this file in an unrecognised form; Cura ignores it and you may delete it by hand: %s"
MSG_need_root="This step needs administrator rights. Run the command again as a regular user (it asks for sudo itself)."
MSG_no_sudo="Administrator rights are needed for --system, but sudo is not available."
MSG_elev_failed="Administrator approval was not given or the system step failed (code %s)."
MSG_status_installed="Installed (%s): version %s, %s"
MSG_status_intact="all files intact"
MSG_status_damaged="DAMAGED: %s"
MSG_status_none="Not installed (%s)."
MSG_yes="Yes"
MSG_no="No"
MSG_app_name="UltiMaker Cura 5.13 (Elephant Foot N Layers)"
