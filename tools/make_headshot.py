"""Generate assets/headshot.jpg from a camera original (HEIC, JPEG, PNG...).

    pip install pillow pillow-heif
    python tools/make_headshot.py path/to/photo.heic

Browsers cannot display HEIC, so the original is never published -- *.heic is
gitignored. This script does the conversion: applies EXIF rotation, takes a
square crop, resizes to 3x the on-page display size for high-DPI screens, and
drops EXIF (which otherwise carries capture time, device, and possibly GPS).

CROP is in pixel coordinates of the EXIF-rotated original. To reframe, pass
--preview to write a numbered grid alongside the crop so you can read off new
values, or just edit CROP and re-run -- it is cheap.
"""

import argparse
from pathlib import Path

from PIL import Image, ImageOps

try:
    import pillow_heif

    pillow_heif.register_heif_opener()
except ImportError:  # only needed for HEIC input
    pass

# (left, top, right, bottom) on the 3024x4032 original; squared off below.
CROP = (432, 1440, 2678, 3686)
SIZE = 480  # displayed at ~150px in .headshot, so 3x
QUALITY = 86

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "headshot.jpg"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("source", type=Path)
    ap.add_argument("--out", type=Path, default=OUT)
    ap.add_argument(
        "--preview",
        action="store_true",
        help="also write headshot-preview.png: the full frame with a coordinate "
        "grid every 500px, for picking a new CROP",
    )
    args = ap.parse_args()

    im = ImageOps.exif_transpose(Image.open(args.source)).convert("RGB")
    print(f"source {args.source.name}: {im.size[0]}x{im.size[1]}")

    if args.preview:
        from PIL import ImageDraw

        p = im.copy()
        d = ImageDraw.Draw(p)
        for x in range(0, p.width, 500):
            d.line([(x, 0), (x, p.height)], fill="red", width=4)
            d.text((x + 8, 8), str(x), fill="red")
        for y in range(0, p.height, 500):
            d.line([(0, y), (p.width, y)], fill="red", width=4)
            d.text((8, y + 8), str(y), fill="red")
        p.thumbnail((900, 900))
        preview_path = args.out.with_name("headshot-preview.png")
        p.save(preview_path)
        print(f"preview -> {preview_path}")

    left, top, right, bottom = CROP
    side = min(right - left, bottom - top)  # force square; object-fit would crop anyway
    im = im.crop((left, top, left + side, top + side))
    im = im.resize((SIZE, SIZE), Image.LANCZOS)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    im.save(args.out, "JPEG", quality=QUALITY, optimize=True, progressive=True)

    written = args.out.stat().st_size
    exif = "present" if Image.open(args.out).getexif() else "stripped"
    print(f"wrote {args.out.relative_to(ROOT)}  {SIZE}x{SIZE}  {written:,} bytes  EXIF {exif}")


if __name__ == "__main__":
    main()
