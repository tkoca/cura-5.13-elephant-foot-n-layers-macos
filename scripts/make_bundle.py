#!/usr/bin/env python3
"""Writes a deterministic tar of a folder (sorted names, owner 0, fixed timestamp, modes 755/644).

Usage: python3 make_bundle.py <folder> <name inside the tar> <out.tar>
macOS tar (bsdtar) has no --sort/--mtime, so this replaces GNU tar's options of the Linux build.
"""
import io
import os
import sys
import tarfile

MTIME = 315532800  # 1980-01-01


def main():
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    root, top, out = sys.argv[1], sys.argv[2], sys.argv[3]
    entries = []
    for base, dirs, files in os.walk(os.path.join(root, top)):
        dirs.sort()
        rel = os.path.relpath(base, root)
        entries.append((rel, None))
        entries.extend((os.path.join(rel, f), os.path.join(base, f)) for f in sorted(files))
    with tarfile.open(out, "w", format=tarfile.USTAR_FORMAT) as tar:
        for name, path in sorted(entries):
            info = tarfile.TarInfo(name)
            info.mtime, info.uid, info.gid, info.uname, info.gname = MTIME, 0, 0, "", ""
            if path is None:
                info.type, info.mode = tarfile.DIRTYPE, 0o755
                tar.addfile(info)
            else:
                data = open(path, "rb").read()
                info.size, info.mode = len(data), 0o755 if os.access(path, os.X_OK) else 0o644
                tar.addfile(info, io.BytesIO(data))


if __name__ == "__main__":
    main()
