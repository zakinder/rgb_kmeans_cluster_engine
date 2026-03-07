# RGB Cluster Verification Environment

This package provides a practical hybrid verification flow for the uploaded VHDL design:

- `rgb_cluster_pkg.vhd`
- `rgb_cluster_core.vhd`
- `rgb_kmeans_cluster_engine.vhd`
- `square_root.vhd`

It includes:

- self-checking VHDL testbench for `square_root`
- self-checking VHDL testbench for `rgb_cluster_core`
- image-driven VHDL testbench skeleton for `rgb_kmeans_cluster_engine`
- Python utilities to convert images to pixel streams and rebuild output BMPs
- a software golden model for nearest-centroid RGB clustering
- a pixel/image comparison script

## Directory contents

- `tb_square_root.vhd`
- `tb_rgb_cluster_core.vhd`
- `tb_rgb_kmeans_cluster_engine_image.vhd`
- `image_to_pixels.py`
- `pixels_to_bmp.py`
- `golden_rgb_cluster.py`
- `compare_pixels.py`
- `sample_input_pixels.txt`

## Recommended flow

### 1) Unit-verify the math blocks

Run:

- `tb_square_root.vhd`
- `tb_rgb_cluster_core.vhd`

These are self-checking and assert on mismatch.

### 2) Prepare an image stimulus

Convert an image to a simple text pixel stream:

```bash
python3 image_to_pixels.py input.bmp input_pixels.txt --width 64 --height 64
```

Pixel file format:

```text
# width height
64 64
# x y r g b
0 0 120 45 32
1 0 121 46 33
...
```

### 3) Simulate the engine with image input

`tb_rgb_kmeans_cluster_engine_image.vhd` reads the pixel file, drives the DUT, and dumps output pixels.

Expected DUT I/O assumptions:

- input/output channel fields match `rgb_cluster_pkg.channel`
- RGB is 10-bit in DUT, mapped from 8-bit image values using left shift by 2
- the DUT output RGB is converted back to 8-bit by taking bits `[9:2]`

### 4) Rebuild the DUT output image

```bash
python3 pixels_to_bmp.py dut_output_pixels.txt dut_output.bmp
```

### 5) Build a golden reference image

```bash
python3 golden_rgb_cluster.py input_pixels.txt golden_pixels.txt --centroids centroids.txt
python3 pixels_to_bmp.py golden_pixels.txt golden.bmp
```

Centroid file format:

```text
# id r g b
1 255 255 255
2 128 128 128
3 0 0 0
```

### 6) Compare DUT vs golden

```bash
python3 compare_pixels.py dut_output_pixels.txt golden_pixels.txt
```

## Notes

### About the top engine

The engine source is large and heavily LUT-driven. This environment is intended to verify:

- frame integrity
- image I/O correctness
- deterministic output generation
- pixel-by-pixel agreement against a software model once your selected centroid bank and write/read programming scheme are fixed

### About simulation tools

The VHDL uses `textio`, records, and integer/`numeric_std` math. It should be portable to common simulators with minor syntax adjustments if a tool is strict about record defaults.

### About the DUT latency

The image testbench uses a simple output capture model based on `pixel_out_rgb.valid = '1'`.
If you want strict cycle-aligned checking, add a scoreboard queue with the exact measured DUT latency.
