#!/usr/bin/env python3
import pathlib
import struct
import sys


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: build-icns.py ICONSET_DIR OUTPUT.icns")

    iconset = pathlib.Path(sys.argv[1])
    output = pathlib.Path(sys.argv[2])
    entries = [
        ("ic11", "icon_16x16@2x.png"),
        ("ic12", "icon_32x32@2x.png"),
        ("ic07", "icon_128x128.png"),
        ("ic13", "icon_128x128@2x.png"),
        ("ic08", "icon_256x256.png"),
        ("ic14", "icon_256x256@2x.png"),
        ("ic09", "icon_512x512.png"),
        ("ic10", "icon_512x512@2x.png"),
    ]

    chunks = []
    for chunk_type, filename in entries:
        data = (iconset / filename).read_bytes()
        chunks.append(
            chunk_type.encode("ascii")
            + struct.pack(">I", len(data) + 8)
            + data
        )

    body = b"".join(chunks)
    output.write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)


if __name__ == "__main__":
    main()
