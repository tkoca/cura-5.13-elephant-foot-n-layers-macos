# Cura 5.13.0 — Elephant Foot Compensation for N Layers (macOS)

[English](README.md) · [Türkçe](README_tr.md)

An unofficial add-on for **UltiMaker Cura 5.13.0 on macOS with Apple silicon** (M1 or newer). It applies *Initial Layer Horizontal Expansion* to the first **N** printed layers instead of only the first one, and can optionally step the value back to the normal *Horizontal Expansion* over those layers.

This is the macOS counterpart of [cura-5.13-elephant-foot-n-layers](https://github.com/tkoca/cura-5.13-elephant-foot-n-layers) (Windows) and [cura-5.13-elephant-foot-n-layers-linux](https://github.com/tkoca/cura-5.13-elephant-foot-n-layers-linux) (Linux). All three use the same patches, the same settings and the same resource files.

> This is a community project. It is not made, endorsed or supported by UltiMaker.

## Settings

Two settings are added directly below *Initial Layer Horizontal Expansion* (category *Walls*). They are part of the *Expert* visibility preset; you can also find them with the settings search.

| Setting | Default | Effect |
| --- | --- | --- |
| Elephant Foot Compensation Layer Count | `1` | How many of the first printed layers use *Initial Layer Horizontal Expansion*. `1` is exactly the standard Cura behaviour. Cura shows a warning above 20. |
| Elephant Foot Gradual Compensation | off | Steps the value from *Initial Layer Horizontal Expansion* toward *Horizontal Expansion* over those layers. Only shown when the layer count is greater than 1. |

Example: *Initial Layer Horizontal Expansion* `-0.20 mm`, *Horizontal Expansion* `0.00 mm`, layer count `4`:

| Printed layer | Gradual off | Gradual on |
| --- | --- | --- |
| 1 | -0.20 | -0.20 |
| 2 | -0.20 | -0.15 |
| 3 | -0.20 | -0.10 |
| 4 | -0.20 | -0.05 |
| 5 and above | 0.00 | 0.00 |

All N layers are compensated; the layer after them uses the normal value. If *Horizontal Expansion* is not zero, the steps lead toward that value instead of 0.

In the Turkish interface the settings are called *Fil Ayağı Telafi Katman Sayısı* and *Fil Ayağı Kademeli Telafi*.

Profiles made with the Windows or Linux version work unchanged: the setting names are the same.

## Requirements

- A Mac with Apple silicon (M1 or newer), macOS 12 Monterey or newer.
- The official **UltiMaker Cura 5.13.0** app, installed from **`UltiMaker-Cura-5.13.0-macos-ARM64.dmg`** of the [UltiMaker Cura 5.13.0 release](https://github.com/Ultimaker/Cura/releases/tag/5.13.0) (normally `/Applications/UltiMaker Cura.app`). The installer checks Ultimaker's code signature and the SHA-256 of the affected files.
- Nothing else: the installer uses only programs that come with macOS (`/bin/bash` 3.2, `ditto`, `codesign`, `shasum`, `plutil`). Homebrew, Python, Xcode and administrator rights are **not** needed.
- Not supported: Intel Macs and the Intel build of Cura (`…-macos-X64.dmg`).

## Install

1. Download `Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run` from [Releases](../../releases) and check that its SHA-256 matches the value in the release notes:
   ```sh
   shasum -a 256 ~/Downloads/Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run
   ```
2. Quit Cura.
3. In Terminal, install (Cura is found in `/Applications` or `~/Applications`; you can also pass its location):
   ```sh
   bash ~/Downloads/Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run install
   ```
4. Start **UltiMaker Cura 5.13 (Elephant Foot N Layers)** from Launchpad or Spotlight. It is in `~/Applications`.

Run the file with `bash` as shown: double-clicking it does not work, because it is a script and not a signed app.

How it works: the installer checks your Cura.app (Ultimaker code signature, version 5.13.0, Apple silicon build, SHA-256 of the six affected files and `Info.plist`), copies it (APFS clone: the unchanged files take no extra disk space), replaces six files in the copy, gives the copy its own name and bundle identifier and signs it again (ad hoc), because Ultimaker's signature does not cover changed content. **Your Cura.app is not changed** — you can keep using it as the normal Cura. The copy is created on your Mac, so it carries no download quarantine and opens without a Gatekeeper prompt. The installation is atomic: if anything fails, nothing is left behind (and an existing installation keeps working).

Both apps share your Cura profile (`~/Library/Application Support/cura/5.13`), like the Windows and Linux versions. The patched copy keeps its own definition cache (`…/cura/5.13/cache/definitions-efnl`), so the two apps never load each other's cached settings definition. The unmodified Cura ignores the two settings.

Messages are in Turkish when the language of macOS (or `LANG`) is Turkish, otherwise in English.

## Uninstall

```sh
~/Applications/"UltiMaker Cura 5.13 (Elephant Foot N Layers).app"/Contents/Resources/efnl/uninstall   # works without the .run file
# or
bash Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run uninstall
```

- The patched copy is removed. Your Cura.app was never changed.
- The two settings are removed from your Cura profile (`~/Library/Application Support/cura/5.13`, including your saved custom profiles; `plugins/` is not touched), and the definition cache of the copy is deleted.
- If a file of the patched copy changed after installation you get a warning naming it.
- For safety the profile is not touched if it contains a symbolic link.

Simply moving the app to the Trash also works, but leaves the two settings in your profile (the normal Cura ignores them).

Remove the add-on before switching to another Cura version.

## What is changed on your computer

| Location | Content |
| --- | --- |
| `~/Applications/UltiMaker Cura 5.13 (Elephant Foot N Layers).app` | Copy of Cura 5.13.0 with the files below replaced, signed ad hoc |
| `…/Contents/Frameworks/CuraEngine` | Patched CuraEngine 5.13.0 (arm64) |
| `…/Contents/Resources/share/cura/resources/definitions/fdmprinter.def.json` | The two new settings |
| `…/resources/i18n/tr_TR/fdmprinter.def.json.po` and `LC_MESSAGES/fdmprinter.def.json.mo` | Turkish names and descriptions |
| `…/resources/setting_visibility/expert.cfg` | Settings listed in the Expert preset |
| `…/Contents/Resources/share/uranium/plugins/LocalContainerProvider/LocalContainerProvider.py` | Own definition cache folder (`definitions-efnl`), see above |
| `…/Contents/Info.plist` | Own name and bundle identifier (`nl.ultimaker.cura_UltiMaker_Cura.efnl`) |
| `…/Contents/Resources/efnl/` | Manifest (SHA-256), uninstaller |
| `~/Library/Application Support/cura/5.13/cache/definitions-efnl/` | Definition cache of the patched copy (created by Cura) |

With `--system` the copy goes to `/Applications` (for all users); the administrator password is asked only if your account cannot write to `/Applications`.

### Command line

```text
bash Cura-5.13-…-arm64.run install [CURA.APP] [--system] [--gui] [--yes|--silent]
bash Cura-5.13-…-arm64.run uninstall          [--system] [--gui] [--yes|--silent]
bash Cura-5.13-…-arm64.run status             [--system]
```

- `--system`: install for all users in `/Applications`. The profile cleanup always runs as your own user. Do not start the installer itself with `sudo`.
- `--gui`: questions and results in dialog windows.
- `--yes`: no questions. `--silent`: like `--yes`, messages only on standard error (warnings as `WARNING: …`).
- Exit code `0` means success (possibly with warnings); `1` means nothing or not everything was done; `2` means a usage error.

## Source and build

Everything needed to rebuild the installer is in this repository: the patches, the installer, the build scripts and the tests. See [SOURCE_AND_BUILD.md](SOURCE_AND_BUILD.md).

## License

GNU Affero General Public License v3.0 or later ([LICENSE](LICENSE)), the license of CuraEngine. The Cura and Uranium resource files are © UltiMaker, LGPL-3.0-or-later. The source code for the `CuraEngine` included in the installer is UltiMaker CuraEngine 5.13.0 plus [`patches/CuraEngine-5.13.0.patch`](patches/CuraEngine-5.13.0.patch), built with [`scripts/build-curaengine.sh`](scripts/build-curaengine.sh). The installer does not contain or redistribute UltiMaker Cura itself; it makes a modified copy of your own installed Cura.app.

Use at your own risk; try it on a small calibration print first.
