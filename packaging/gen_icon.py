"""Emit the Quartz app icon as a PNG. Usage: gen_icon.py <out.png> [size] [src]."""

import sys
from pathlib import Path

from PIL import Image

# Callers run from the repo root (Makefile, install scripts, the PowerShell
# builders), so the default source has to be anchored to this file, not to CWD.
DEFAULT_SRC = Path(__file__).resolve().parent / "icon.png"


def main() -> None:
    out = sys.argv[1]
    size = int(sys.argv[2]) if len(sys.argv) > 2 else 256
    src = sys.argv[3] if len(sys.argv) > 3 else str(DEFAULT_SRC)
    with Image.open(src) as img:
        img = img.resize((size, size))
        img.save(out)


if __name__ == "__main__":
    main()
