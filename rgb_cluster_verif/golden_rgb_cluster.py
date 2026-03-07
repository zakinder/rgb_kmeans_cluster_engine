#!/usr/bin/env python3
from __future__ import annotations
import argparse
import math
from pathlib import Path
from typing import List, Tuple

Pixel = Tuple[int, int, int, int, int]
Centroid = Tuple[int, int, int, int]


def read_pixels(path: Path) -> Tuple[List[Pixel], int, int]:
    pixels: List[Pixel] = []
    width = height = None
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            parts = s.split()
            if len(parts) == 2 and width is None and height is None:
                width, height = map(int, parts)
                continue
            if len(parts) >= 5:
                x, y, r, g, b = map(int, parts[:5])
                pixels.append((x, y, r, g, b))
    if width is None or height is None:
        width = max(p[0] for p in pixels) + 1
        height = max(p[1] for p in pixels) + 1
    return pixels, width, height


def read_centroids(path: Path) -> List[Centroid]:
    centroids: List[Centroid] = []
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            idx, r, g, b = map(int, s.split()[:4])
            centroids.append((idx, r, g, b))
    if not centroids:
        raise ValueError("No centroids found")
    return centroids


def nearest_centroid(r: int, g: int, b: int, centroids: List[Centroid]) -> Tuple[int, int, int, int]:
    best = None
    for idx, cr, cg, cb in centroids:
        d = math.isqrt((r - cr) ** 2 + (g - cg) ** 2 + (b - cb) ** 2)
        if best is None or d < best[0] or (d == best[0] and idx < best[1]):
            best = (d, idx, cr, cg, cb)
    assert best is not None
    return best[1], best[2], best[3], best[4]


def main() -> None:
    ap = argparse.ArgumentParser(description="Golden nearest-centroid RGB clustering model.")
    ap.add_argument("input_pixels")
    ap.add_argument("output_pixels")
    ap.add_argument("--centroids", required=True, help="Text file: id r g b")
    args = ap.parse_args()

    pixels, width, height = read_pixels(Path(args.input_pixels))
    centroids = read_centroids(Path(args.centroids))

    with Path(args.output_pixels).open("w", encoding="utf-8") as f:
        f.write("# width height\n")
        f.write(f"{width} {height}\n")
        f.write("# x y r g b cluster_id\n")
        for x, y, r, g, b in pixels:
            idx, rr, gg, bb = nearest_centroid(r, g, b, centroids)
            f.write(f"{x} {y} {rr} {gg} {bb} {idx}\n")


if __name__ == "__main__":
    main()
