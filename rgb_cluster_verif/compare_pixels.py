#!/usr/bin/env python3
from __future__ import annotations
import argparse
from pathlib import Path


def read_map(path: Path):
    rows = {}
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if not s or s.startswith("#"):
                continue
            parts = s.split()
            if len(parts) == 2:
                continue
            if len(parts) < 5:
                continue
            x, y, r, g, b = map(int, parts[:5])
            rows[(x, y)] = (r, g, b)
    return rows


def main() -> None:
    ap = argparse.ArgumentParser(description="Compare two text pixel files.")
    ap.add_argument("dut_pixels")
    ap.add_argument("golden_pixels")
    args = ap.parse_args()

    dut = read_map(Path(args.dut_pixels))
    golden = read_map(Path(args.golden_pixels))

    all_xy = sorted(set(dut) | set(golden))
    mismatches = []
    for xy in all_xy:
        a = dut.get(xy)
        b = golden.get(xy)
        if a != b:
            mismatches.append((xy, a, b))

    print(f"Total compared locations: {len(all_xy)}")
    print(f"Mismatches: {len(mismatches)}")
    if all_xy:
        print(f"Match rate: {(len(all_xy) - len(mismatches)) / len(all_xy) * 100:.3f}%")

    for i, (xy, a, b) in enumerate(mismatches[:20]):
        print(f"Mismatch {i+1}: xy={xy} dut={a} golden={b}")

    if mismatches:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
