# Architecture Specification — RGB K-Means Clustering Engine

**Designer Name:** Sakinder Ali  
**Module:** `rgb_kmeans_cluster_engine`  
**Domain:** FPGA / VHDL / Real-Time Image Processing

---

## 1. Overview

The RGB K-Means Clustering Engine is a streaming FPGA datapath that classifies each input RGB pixel against a set of RGB centroid values. The selected centroid becomes the output color for that pixel, producing a clustered or quantized RGB stream.

The design is structured around deterministic, clocked hardware stages so it can operate inside real-time video pipelines.

---

## 2. Architectural Position

```text
Camera / Frame Source
        |
        v
RGB Pixel Stream
        |
        v
+----------------------------+
| rgb_kmeans_cluster_engine  |
+----------------------------+
        |
        v
Clustered RGB Stream
        |
        v
Display / Detection / Storage
```

The engine may be placed after RGB capture or preprocessing and before segmentation, object-region detection, display output, or compression.

---

## 3. Major Blocks

| Block | Responsibility |
|---|---|
| Input Stream Capture | Registers RGB pixel data and stream metadata. |
| Centroid LUT / Profile Bank | Stores RGB centroid values used for classification. |
| Distance Computation Unit | Computes RGB distance from the pixel to each centroid. |
| Minimum-Distance Selector | Selects the nearest centroid. |
| Output MUX / Pixel Generator | Maps the winning centroid into output RGB. |
| Metadata Pipeline | Delays valid/frame/line/coordinate fields to match datapath latency. |

---

## 4. Data Path

```text
pixel_in_rgb
    |
    v
[Input Register]
    |
    v
[Distance Computation vs K Centroids]
    |
    v
[Comparator Tree / Minimum Selector]
    |
    v
[Centroid RGB Output MUX]
    |
    v
pixel_out_rgb
```

The datapath is designed to support one-pixel-per-clock throughput after pipeline fill, subject to implementation timing and centroid count.

---

## 5. Control Path

The control path preserves stream metadata:

- `valid`
- `sof`
- `eol`
- `eof`
- `xcnt`
- `ycnt`

These fields must be delayed by the same number of cycles as the RGB processing path.

---

## 6. Centroid Storage Architecture

Centroid values may be stored using:

1. Constant arrays for fixed palettes.
2. Register arrays for programmable centroid banks.
3. Distributed RAM for small configurable tables.
4. BRAM for larger centroid-profile storage.

Each centroid entry represents:

```text
C(i) = (Ri, Gi, Bi)
```

---

## 7. Distance Architecture

The preferred hardware distance metric is Manhattan distance:

```text
D(i) = |R - Ri| + |G - Gi| + |B - Bi|
```

This is suitable for FPGA implementation because it uses subtractors, absolute-value logic, and adders without requiring multipliers or square-root hardware.

---

## 8. Comparator Architecture

The minimum-distance selector may be implemented as:

- linear comparator chain for small `K`
- balanced comparator tree for moderate `K`
- pipelined comparator tree for higher clock targets

The selector outputs:

```text
best_cluster_id
best_distance
```

---

## 9. Output Architecture

The output stage selects the winning centroid RGB value:

```text
pixel_out_rgb = centroid(best_cluster_id)
```

The output metadata must describe the same pixel that generated the winning centroid decision.

---

## 10. Scalability

The architecture scales through:

- configurable channel width
- configurable centroid count
- selectable centroid profiles
- deeper pipelining
- memory-based centroid storage
- registered comparator-tree stages

---

## 11. Design Summary

The architecture maps K-means-style RGB classification into a deterministic FPGA streaming pipeline. It separates centroid storage, distance computation, minimum selection, and output mapping so each block can be verified and optimized independently.
