#!/usr/bin/env python3
from __future__ import annotations
import argparse
from pathlib import Path
from PIL import Image


def main() -> None:
    ap = argparse.ArgumentParser(description="Convert image to text pixel stimulus.")
    ap.add_argument("input_image")
    ap.add_argument("output_pixels")
    ap.add_argument("--width", type=int, default=None)
    ap.add_argument("--height", type=int, default=None)
    args = ap.parse_args()

    img = Image.open(args.input_image).convert("RGB")
    if args.width and args.height:
        img = img.resize((args.width, args.height))

    w, h = img.size
    out = Path(args.output_pixels)
    with out.open("w", encoding="utf-8") as f:
        f.write("# width height\n")
        f.write(f"{w} {h}\n")
        f.write("# x y r g b\n")
        for y in range(h):
            for x in range(w):
                r, g, b = img.getpixel((x, y))
                f.write(f"{x} {y} {r} {g} {b}\n")


if __name__ == "__main__":
    main()
