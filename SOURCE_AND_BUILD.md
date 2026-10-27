# Source and build (macOS)

[English](SOURCE_AND_BUILD.md) · [Türkçe](SOURCE_AND_BUILD_tr.md)

Everything needed to rebuild `Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run` is in this repository.

## Contents

| Path | Content |
| --- | --- |
| `patches/CuraEngine-5.13.0.patch` | Change to `src/slicer.cpp` of CuraEngine 5.13.0 (identical to the Windows and Linux projects) |
| `patches/Cura-5.13.0.patch` | Changes to three Cura resource files (`fdmprinter.def.json`, Turkish `.po`, `expert.cfg`); the Turkish `.mo` is compiled from the patched `.po` by `scripts/po2mo.py` (identical to the Windows and Linux projects) |
| `patches/Uranium-5.13.0-macos.patch` | macOS only: the LocalContainerProvider plugin of the copy uses its own definition cache folder (`definitions-efnl`), see below |
| `scripts/setup-tools.sh` | Installs the pinned build tools into `/Users/Shared/efnl`: Python 3.12 (via uv), Conan 2.32.0, CMake 3.31.6, Ninja 1.13.2 |
| `scripts/build-curaengine.sh` | Builds CuraEngine natively with the Xcode command line tools (`--unpatched` for a control build) |
| `scripts/check-engine.sh` | Binary checks: thin arm64, deployment target ≤ macOS 12.0, only system libraries and the five libraries of `Cura.app/Contents/Frameworks`, single `LC_RPATH` `@loader_path`, valid signature, no user/host names |
| `scripts/apply_patch.py`, `scripts/make_payload.py`, `scripts/make_bundle.py` | Apply the patches; build the payload and the bundle (deterministic tar) |
| `scripts/build-installer.sh` | Builds the self-extracting `.run` file into `dist/` |
| `installer/` | Installer (`efnl.sh`, bash 3.2), `.run` header, English/Turkish messages |
| `tests/installer-tests.sh` | Installer tests (74 checks) |
| `tests/engine/` | Slicing tests (26 checks) against the official Cura 5.13.0 engine |
| `docs/macos-layout.md` | Measured layout of the official 5.13.0 macOS app |

## Why these build choices

The official app (`UltiMaker-Cura-5.13.0-macos-ARM64.dmg`) contains a thin arm64 `CuraEngine` in `Contents/Frameworks` (deployment target macOS 12.0) that loads `libArcus`, `libpolyclipping`, `libtbb`, `libtbbmalloc` and `libtbbmalloc_proxy` from the same folder through a single `LC_RPATH @loader_path`; everything else (protobuf, gRPC, abseil, OpenSSL, …) is linked statically. The patched engine is built the same way: Conan with the UltiMaker Conan configuration (`Ultimaker/conan-config`, the same pinned commit as on Linux), `os.version=12.0`, and the rpath is set to exactly `@loader_path`. It is stripped and signed ad hoc (arm64 code must be signed).

Apple clang 19 and newer reject a construct in gRPC 1.54.3 (pinned by CuraEngine 5.13.0) by default; the build passes `-Wno-missing-template-arg-list-after-template-kw` for it. The Conan home is the neutral path `/Users/Shared/efnl` and `-ffile-prefix-map` maps it to `.`, so no user name ends up in the binary. The official engine is larger because it is built with Sentry crash reporting; like the Windows and Linux versions, this build keeps the default options (Sentry off).

Modifying files inside an app bundle invalidates its code signature, so the installer works on a copy that it signs again (ad hoc) and never touches the Ultimaker-signed `Cura.app`. On macOS, Cura keeps the definition cache inside the profile (`~/Library/Application Support/cura/5.13/cache`) and ignores `XDG_CACHE_HOME`, and the cache is chosen by file modification time. Without a separate cache folder the unmodified Cura would load the patched cached `fdmprinter` definition (and show the two settings without effect) after the copy has run. The core module `UM/Resources.py` is frozen into the app executable and cannot be changed, but plugins are loaded from their `.py` files, so `patches/Uranium-5.13.0-macos.patch` changes the cache folder name in the LocalContainerProvider plugin of the copy.

## Build

Requirements: a Mac with Apple silicon, the Xcode command line tools (`xcode-select --install`), about 10 GB of free disk space. The first build compiles all dependencies from source and took about 8 minutes on an Apple M5 (10 cores); later builds take about 30 seconds.

```sh
# upstream sources (tag archives)
curl -L -o CuraEngine-5.13.0.tar.gz https://github.com/Ultimaker/CuraEngine/archive/refs/tags/5.13.0.tar.gz
curl -L -o Cura-5.13.0.tar.gz       https://github.com/Ultimaker/Cura/archive/refs/tags/5.13.0.tar.gz
curl -L -o Uranium-5.13.0.tar.gz    https://github.com/Ultimaker/Uranium/archive/refs/tags/5.13.0.tar.gz

scripts/setup-tools.sh                                            # once
scripts/build-curaengine.sh CuraEngine-5.13.0.tar.gz out          # -> out/CuraEngine, CHECK PASS
scripts/build-installer.sh  Cura-5.13.0.tar.gz Uranium-5.13.0.tar.gz out/CuraEngine dist
```

The build is reproducible: building twice gives the same `CuraEngine` and the same `.run` file (same SHA-256 values as in the release notes).

## Tests

```sh
scripts/build-curaengine.sh --unpatched CuraEngine-5.13.0.tar.gz out   # optional control build
python3 scripts/make_payload.py Cura-5.13.0.tar.gz Uranium-5.13.0.tar.gz out/CuraEngine build

tests/engine/slice-tests.sh "/Applications/UltiMaker Cura.app" out/CuraEngine \
    build/payload/Resources/share/cura/resources/definitions/fdmprinter.def.json out/CuraEngine.unpatched
tests/installer-tests.sh "/Applications/UltiMaker Cura.app" build/payload \
    dist/Cura-5.13-Elephant-Foot-N-Layers-macOS-arm64.run
```

The slicing tests run the official engine from `Cura.app` and the built engines next to links to its libraries, like Cura does. They check that layer count 1 gives G-code identical to the official engine, the per-layer wall inset for N layers with and without gradual compensation, and that the unpatched control build gives G-code identical to the official engine (so differences come only from the patch). The installer tests run in a temporary home folder (`/Users/Shared/efnl/installer-tests.noindex`, excluded from Spotlight) with APFS clones of the real app; they never touch the real profile, `/Applications` or the original `Cura.app`.
