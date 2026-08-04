"""Emit the Quartz app icon as a PNG. Usage: gen_icon.py <out.png> [size]."""

import sys

from PIL import Image, ImageDraw


def main() -> None:
    out = sys.argv[1]
    size = int(sys.argv[2]) if len(sys.argv) > 2 else 256
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pad = size // 12
    d.rounded_rectangle(
        [pad, pad, size - pad, size - pad],
        radius=size // 5,
        fill=(124, 77, 255, 255),
    )
    try:
        from PIL import ImageFont

        font = ImageFont.truetype("DejaVuSans-Bold.ttf", int(size * 0.55))
    except Exception:
        font = None
    d.text((size / 2, size / 2), "Q", fill="white", anchor="mm", font=font)
    img.save(out)


if __name__ == "__main__":
    main()
