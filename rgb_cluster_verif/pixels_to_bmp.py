#!/usr/bin/env python3
from __future__ import annotations
import argparse
from pathlib import Path
from PIL import Image


def parse_pixels(path: Path):
    rows = []
    max_x = -1
    max_y = -1
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            parts = s.split()
            if len(parts) == 2 and max_x < 0 and max_y < 0:
                # optional width height header
                continue
            if len(parts) < 5:
                continue
            x, y, r, g, b = map(int, parts[:5])
            rows.append((x, y, r, g, b))
            max_x = max(max_x, x)
            max_y = max(max_y, y)
    if max_x < 0 or max_y < 0:
        raise ValueError("No pixel rows found")
    return rows, max_x + 1, max_y + 1


def main() -> None:
    ap = argparse.ArgumentParser(description="Rebuild BMP/PNG image from text pixels.")
    ap.add_argument("input_pixels")
    ap.add_argument("output_image")
    args = ap.parse_args()

    rows, w, h = parse_pixels(Path(args.input_pixels))
    img = Image.new("RGB", (w, h))
    for x, y, r, g, b in rows:
        img.putpixel((x, y), (max(0, min(255, r)), max(0, min(255, g)), max(0, min(255, b))))
    img.save(args.output_image)


if __name__ == "__main__":
    main()
