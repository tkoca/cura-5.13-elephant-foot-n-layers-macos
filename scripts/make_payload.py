#!/usr/bin/env python3
"""Builds the installer payload deterministically (macOS).

Usage:
  python3 make_payload.py <Cura-5.13.0 source archive> <Uranium-5.13.0 source archive> <CuraEngine> <out dir>

(source archives: .tar.gz or .zip)

* Takes fdmprinter.def.json, tr_TR/fdmprinter.def.json.po and expert.cfg from the
  official UltiMaker Cura 5.13.0 source archive and the LocalContainerProvider plugin
  from the Uranium 5.13.0 source archive, and checks them against the SHA-256 of the files shipped in
  the official Cura 5.13.0 macOS app (identical to Windows and Linux).
* Applies patches/Cura-5.13.0.patch and patches/Uranium-5.13.0-macos.patch and
  compiles the .mo file (scripts/po2mo.py).
* Writes <out dir>/payload/<files> (paths relative to Cura.app/Contents),
  <out dir>/payload/SHA256SUMS and a deterministic <out dir>/payload.tar
  (fixed order, owner, mode and timestamp).
"""
import hashlib
import io
import shutil
import sys
import tarfile
import tempfile
import zipfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import apply_patch  # noqa: E402
import po2mo  # noqa: E402

ORIGINALS = {  # (archive, path): SHA-256
    ("cura", "resources/definitions/fdmprinter.def.json"): "8fbbf8b779e806bd8d0b0e2b8b9be17bdd26a575b7ea1875c20481eb2c7e11ee",
    ("cura", "resources/i18n/tr_TR/fdmprinter.def.json.po"): "ace33455f77ad50ed5d10dbd2f1c2b5732d2c59dcc5e99a9e715ad1bd3f51a85",
    ("cura", "resources/setting_visibility/expert.cfg"): "9b646941fa24799eda46ce207f586ab72687d7b02f837264287bb022b720a4ba",
    ("uranium", "plugins/LocalContainerProvider/LocalContainerProvider.py"): "d778d89795589c00f304447355ea67ead0e7498405b71053889eb6652432ffad",
}
PATCHES = {"cura": "Cura-5.13.0.patch", "uranium": "Uranium-5.13.0-macos.patch"}
ORDER = [
    ("Frameworks/CuraEngine", None),
    ("Resources/share/cura/resources/definitions/fdmprinter.def.json", "cura/resources/definitions/fdmprinter.def.json"),
    ("Resources/share/cura/resources/i18n/tr_TR/fdmprinter.def.json.po", "cura/resources/i18n/tr_TR/fdmprinter.def.json.po"),
    ("Resources/share/cura/resources/i18n/tr_TR/LC_MESSAGES/fdmprinter.def.json.mo", None),
    ("Resources/share/cura/resources/setting_visibility/expert.cfg", "cura/resources/setting_visibility/expert.cfg"),
    ("Resources/share/uranium/plugins/LocalContainerProvider/LocalContainerProvider.py",
     "uranium/plugins/LocalContainerProvider/LocalContainerProvider.py"),
]
ENGINE = "Frameworks/CuraEngine"
MTIME = 315532800  # 1980-01-01


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read_upstream(archive_path, rel):
    if str(archive_path).endswith(".zip"):
        with zipfile.ZipFile(archive_path) as archive:
            prefix = archive.namelist()[0].split("/")[0] + "/"
            return archive.read(prefix + rel)
    with tarfile.open(archive_path) as archive:
        prefix = archive.getnames()[0].split("/")[0] + "/"
        return archive.extractfile(prefix + rel).read()


def main():
    if len(sys.argv) != 5:
        raise SystemExit(__doc__)
    sources = {"cura": Path(sys.argv[1]), "uranium": Path(sys.argv[2])}
    engine, out = Path(sys.argv[3]), Path(sys.argv[4])
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        for (archive, rel), expected in ORIGINALS.items():
            data = read_upstream(sources[archive], rel)
            if sha(data) != expected:
                raise SystemExit("unexpected upstream file (not Cura/Uranium 5.13.0?): " + rel)
            target = tmp / archive / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(data)
        for archive, patch in PATCHES.items():
            sys.argv = ["apply_patch.py", str(HERE.parent / "patches" / patch), str(tmp / archive)]
            apply_patch.main()
        mo = tmp / "cura/resources/i18n/tr_TR/LC_MESSAGES/fdmprinter.def.json.mo"
        mo.parent.mkdir(parents=True, exist_ok=True)
        po2mo.write_mo(po2mo.parse_po(tmp / "cura/resources/i18n/tr_TR/fdmprinter.def.json.po"), mo)

        payload = out / "payload"
        if payload.exists():
            shutil.rmtree(payload)
        entries, sums = [], []
        for name, source in ORDER:
            if name == ENGINE:
                data = engine.read_bytes()
            elif name.endswith(".mo"):
                data = mo.read_bytes()
            else:
                data = (tmp / source).read_bytes()
            (payload / name).parent.mkdir(parents=True, exist_ok=True)
            (payload / name).write_bytes(data)
            (payload / name).chmod(0o755 if name == ENGINE else 0o644)
            entries.append((name, data))
            sums.append("%s  %s\n" % (sha(data), name))
            print(sha(data), name)
        (payload / "SHA256SUMS").write_text("".join(sums))
        entries.append(("SHA256SUMS", "".join(sums).encode()))

        with tarfile.open(out / "payload.tar", "w", format=tarfile.USTAR_FORMAT) as tar:
            dirs = set()
            for name, _ in entries:
                parts = ("payload/" + name).split("/")[:-1]
                for i in range(1, len(parts) + 1):
                    dirs.add("/".join(parts[:i]))
            for d in sorted(dirs):
                info = tarfile.TarInfo(d)
                info.type, info.mode, info.mtime = tarfile.DIRTYPE, 0o755, MTIME
                tar.addfile(info)
            for name, data in entries:
                info = tarfile.TarInfo("payload/" + name)
                info.size, info.mtime = len(data), MTIME
                info.mode = 0o755 if name == ENGINE else 0o644
                tar.addfile(info, io.BytesIO(data))
        print(sha((out / "payload.tar").read_bytes()), "payload.tar")


if __name__ == "__main__":
    main()
