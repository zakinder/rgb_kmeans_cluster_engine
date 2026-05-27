# RGB K-Means Cluster Engine — Design Document

**Repository:** `zakinder/rgb_kmeans_cluster_engine`  
**Design Name:** `rgb_kmeans_cluster_engine`  
**Designer Name:** Sakinder Ali  
**Document Type:** Hardware Design Document  
**Target Domain:** FPGA / VHDL real-time RGB image processing

---

## 1. Purpose

The `rgb_kmeans_cluster_engine` is a hardware-oriented RGB clustering block designed for real-time image and video processing pipelines. The engine receives a streaming RGB pixel, compares that pixel against a programmable or preloaded set of RGB centroids, selects the closest centroid, and outputs the corresponding clustered RGB value.

The design implements a K-means-style pixel classification operation in hardware, where each input pixel is assigned to the nearest color centroid. This enables color quantization, segmentation, region classification, and palette-style image simplification inside an FPGA pipeline.

---

## 2. Design Objectives

The design is intended to provide:

1. **Real-time pixel classification** using a streaming RGB input interface.
2. **Centroid-based color clustering** using stored RGB centroid tables.
3. **Deterministic output behavior** suitable for FPGA timing analysis.
4. **Low-latency operation** through registered and/or pipelined datapath stages.
5. **Programmable centroid access** through write and readback signals.
6. **Metadata preservation** for frame, line, valid, and coordinate tracking.
7. **Scalable architecture** for extending the centroid count or pipeline depth.

---

## 3. System Context

The `rgb_kmeans_cluster_engine` operates as a color-classification stage inside a video-processing chain.

```text
Input RGB Pixel Stream
        |
        v
+----------------------------+
| rgb_kmeans_cluster_engine  |
|                            |
|  1. Capture RGB pixel      |
|  2. Read centroid entries  |
|  3. Compute distances      |
|  4. Select minimum         |
|  5. Output centroid color  |
+----------------------------+
        |
        v
Clustered RGB Pixel Stream
```

The block can be positioned after camera capture, color-space conversion, preprocessing, or frame-buffer readout, and before display output, object-detection logic, image segmentation, compression, or analysis stages.

---

## 4. Top-Level Interface

### 4.1 Entity

```vhdl
entity rgb_kmeans_cluster_engine is
    generic (
        i_data_width : integer := 8
    );
    port (
        clk                 : in  std_logic;
        rst_n               : in  std_logic;
        pixel_in_rgb        : in  channel;
        centroid_lut_select : in  natural;
        centroid_lut_in     : in  std_logic_vector(23 downto 0);
        centroid_lut_out    : out std_logic_vector(31 downto 0);
        k_ind_w             : in  natural;
        k_ind_r             : in  natural;
        pixel_out_rgb       : out channel
    );
end rgb_kmeans_cluster_engine;
```

### 4.2 Interface Summary

| Signal | Direction | Type | Purpose |
|---|---:|---|---|
| `clk` | Input | `std_logic` | System clock. |
| `rst_n` | Input | `std_logic` | Active-low reset. |
| `pixel_in_rgb` | Input | `channel` | Streaming RGB pixel input with metadata. |
| `centroid_lut_select` | Input | `natural` | Selects a centroid LUT/profile or target entry context. |
| `centroid_lut_in` | Input | `std_logic_vector(23 downto 0)` | Packed RGB centroid write data. |
| `centroid_lut_out` | Output | `std_logic_vector(31 downto 0)` | Centroid readback/debug output. |
| `k_ind_w` | Input | `natural` | Centroid write index. |
| `k_ind_r` | Input | `natural` | Centroid read index. |
| `pixel_out_rgb` | Output | `channel` | Clustered RGB pixel output with aligned metadata. |

---

## 5. Input and Output Data Model

### 5.1 Pixel Input

The input pixel is represented by a `channel` record. The record is expected to include RGB data and stream-control metadata such as:

- red component
- green component
- blue component
- valid flag
- start-of-frame marker
- end-of-line marker
- end-of-frame marker
- x coordinate
- y coordinate

The RGB fields are used for clustering. The metadata fields must be delayed and forwarded so that the output pixel remains aligned with the correct frame position.

### 5.2 Centroid Data

Each centroid stores an RGB tuple:

```text
C(i) = (Ri, Gi, Bi)
```

The 24-bit programming input is interpreted as:

```text
centroid_lut_in[23:16] = red
centroid_lut_in[15:8]  = green
centroid_lut_in[7:0]   = blue
```

The 32-bit readback output may expose the centroid value with optional upper-bit padding:

```text
centroid_lut_out[23:16] = red
centroid_lut_out[15:8]  = green
centroid_lut_out[7:0]   = blue
```

---

## 6. Functional Architecture

The engine is divided into the following functional blocks:

```text
+-------------------------+
| Input Stream Capture    |
+-----------+-------------+
            |
            v
+-------------------------+
| Centroid LUT / Profiles |
+-----------+-------------+
            |
            v
+-------------------------+
| RGB Distance Engine     |
+-----------+-------------+
            |
            v
+-------------------------+
| Minimum Selector        |
+-----------+-------------+
            |
            v
+-------------------------+
| Output RGB Mapper       |
+-----------+-------------+
            |
            v
+-------------------------+
| Metadata-Aligned Output |
+-------------------------+
```

### 6.1 Input Stream Capture

The input stage samples the incoming `pixel_in_rgb` record on `clk`. It extracts the red, green, and blue components for computation while also registering the metadata path.

### 6.2 Centroid LUT / Profile Storage

The centroid storage block holds multiple RGB centroid entries. These entries may be implemented as constants, register arrays, distributed RAM, or BRAM depending on the selected FPGA implementation.

Responsibilities:

- Store active centroid RGB values.
- Support centroid profile selection.
- Support centroid write by index.
- Support centroid readback by index.
- Present centroid values to the distance-computation block.

### 6.3 RGB Distance Engine

For each centroid, the engine computes a color distance between the input pixel and centroid value.

A hardware-efficient metric is Manhattan distance:

```text
D(i) = |R - Ri| + |G - Gi| + |B - Bi|
```

This avoids multipliers and square-root hardware while still providing useful nearest-centroid classification behavior.

An optional Euclidean-style mode may be supported in future versions:

```text
D(i) = sqrt((R - Ri)^2 + (G - Gi)^2 + (B - Bi)^2)
```

### 6.4 Minimum Selector

The minimum selector compares all computed distance values and selects the centroid index with the smallest distance:

```text
best_cluster = argmin D(i)
```

For small centroid counts, this may be implemented as direct combinational comparison. For larger centroid counts, a registered comparator tree is preferred for timing closure.

### 6.5 Output RGB Mapper

The output mapper uses the winning centroid index to select the final RGB output value:

```text
pixel_out_rgb.red   = centroid(best_cluster).red
pixel_out_rgb.green = centroid(best_cluster).green
pixel_out_rgb.blue  = centroid(best_cluster).blue
```

Metadata is forwarded through a matching delay path so that the output control signals describe the same pixel that produced the selected centroid.

---

## 7. Algorithmic Flow

For every valid input pixel:

1. Capture input RGB and metadata.
2. Read or expose the active centroid set.
3. Compute distance from the input pixel to each centroid.
4. Compare all distances.
5. Select the minimum-distance centroid.
6. Output the selected centroid RGB as the clustered pixel.
7. Forward valid, frame, line, and coordinate metadata in alignment with the processed RGB result.

Pseudocode:

```text
for each input pixel P = (R, G, B):
    for each centroid C(i) = (Ri, Gi, Bi):
        D(i) = abs(R - Ri) + abs(G - Gi) + abs(B - Bi)

    best_cluster = index of minimum D(i)
    output_pixel = C(best_cluster)
```

---

## 8. Pipeline and Timing Model

The design is synchronous to `clk`. A typical pipeline may be organized as:

| Stage | Function |
|---:|---|
| Stage 0 | Input pixel capture and metadata registration. |
| Stage 1 | RGB-to-centroid distance computation. |
| Stage 2 | Distance accumulation. |
| Stage 3 | Comparator tree / minimum selector. |
| Stage 4 | Winning centroid RGB selection. |
| Stage 5 | Output registration. |

The total latency is:

```text
L_total = L_input + L_distance + L_compare + L_mux + L_output
```

If a square-root or Euclidean-magnitude stage is added, then:

```text
L_total = L_input + L_distance + L_sqrt + L_compare + L_mux + L_output
```

### 8.1 Throughput Target

The preferred streaming target is:

```text
1 input pixel per clock
1 output pixel per clock after pipeline fill
```

### 8.2 Metadata Alignment Rule

All metadata must be delayed by exactly the same number of cycles as the RGB datapath:

```text
metadata_delay = L_total
```

For any pixel entering at cycle `t0`:

```text
input RGB + metadata @ t0
clustered RGB output @ t0 + L_total
output metadata       @ t0 + L_total
```

---

## 9. Reset Behavior

The reset input is active-low.

When `rst_n = '0'`, the design should:

- Clear output registers.
- Deassert output valid.
- Reset internal selection state.
- Place centroid readback/output paths into known values.
- Flush or clear pipeline metadata registers.

After reset release, the pipeline must refill before the first valid clustered output appears.

---

## 10. Centroid Programming and Readback

### 10.1 Write Operation

A centroid write operation updates one centroid entry using:

- `k_ind_w`
- `centroid_lut_select`
- `centroid_lut_in`

Recommended write behavior:

```text
centroid[k_ind_w] <= centroid_lut_in[23:0]
```

### 10.2 Read Operation

A centroid readback operation exposes one selected centroid using:

- `k_ind_r`
- `centroid_lut_out`

Recommended readback behavior:

```text
centroid_lut_out <= zero_pad(centroid[k_ind_r])
```

### 10.3 Write/Read Safety

When centroid updates occur during active streaming, the design should define whether writes immediately affect the active centroid set or are applied through a controlled update boundary. For robust video behavior, a future enhancement should use double-buffered or shadow-buffered centroid profiles so active pixels are not classified against partially updated centroid tables.

---

## 11. Resource Considerations

Primary FPGA resources include:

| Resource | Usage |
|---|---|
| LUTs | Absolute difference logic, adders, comparator tree, output muxing. |
| Flip-flops | Pipeline registers, metadata delay registers, control state. |
| BRAM / distributed RAM | Optional centroid storage implementation. |
| DSP blocks | Usually not required for Manhattan distance; may be used for Euclidean distance. |

Resource cost scales with:

- centroid count `K`
- data width `i_data_width`
- number of parallel distance engines
- comparator tree depth
- pipeline depth
- centroid storage style

---

## 12. Verification Strategy

Verification should prove that pixel classification, timing, metadata alignment, reset behavior, and centroid access are correct.

### 12.1 Core Tests

| Test | Objective |
|---|---|
| Single-pixel classification | Confirm that one input pixel maps to the expected nearest centroid. |
| Known centroid comparison | Use fixed centroids and check selected index/output RGB. |
| Continuous stream | Confirm one output per clock after pipeline fill. |
| Metadata alignment | Verify `valid`, `sof`, `eol`, `eof`, `xcnt`, and `ycnt` match the processed pixel. |
| Reset during stream | Confirm pipeline flush and clean restart. |
| Centroid write/readback | Confirm written centroid values can be read back correctly. |
| Boundary values | Test RGB values at `0`, `255`, and near-centroid boundaries. |
| Tie condition | Define and verify deterministic behavior when two centroids have equal distance. |

### 12.2 Expected Reference Model

A software or testbench reference model should calculate:

```text
D(i) = |R - Ri| + |G - Gi| + |B - Bi|
expected_index = argmin D(i)
expected_rgb = centroid(expected_index)
```

The testbench should compare `pixel_out_rgb` against `expected_rgb` after the documented pipeline latency.

---

## 13. Implementation Constraints

1. Every distance compared in one decision must correspond to the same input pixel.
2. The winning centroid index must remain aligned with the selected centroid RGB value.
3. Metadata delay must exactly match datapath latency.
4. Any pipeline-depth change requires updating metadata delay logic and verification expectations.
5. Read and write index ranges must be constrained to valid centroid table entries.
6. Centroid LUT updates during active video must be specified to avoid partial-update artifacts.
7. Comparator tree depth should be registered when timing closure requires it.

---

## 14. Known Design Limitations

- Clustering quality depends on centroid selection.
- Manhattan distance is efficient but less precise than full Euclidean distance.
- Large centroid counts increase comparator and memory pressure.
- Training or centroid optimization is expected to occur outside this module unless later added.
- Runtime centroid writes may require shadow buffering for glitch-safe live reconfiguration.

---

## 15. Recommended Enhancements

Future design improvements may include:

1. Parameterized centroid count `K`.
2. Shadow centroid LUT for safe runtime updates.
3. Explicit write-enable and read-enable controls.
4. Tie-break policy documentation.
5. Optional Euclidean distance mode.
6. AXI-stream-compatible input/output wrapping.
7. AXI-lite or register-map interface for centroid programming.
8. Formal assertions for metadata alignment and index bounds.
9. Synthesis reports documenting LUT, FF, BRAM, and timing results.
10. Versioned centroid profile libraries for application-specific color maps.

---

## 16. Design Summary

The `rgb_kmeans_cluster_engine` is a VHDL FPGA module for real-time RGB centroid classification. It accepts a streaming pixel, compares the pixel against stored RGB centroid values, selects the nearest centroid, and outputs the selected centroid color while preserving frame and coordinate metadata. The design is suitable for deterministic FPGA video pipelines where low-latency color quantization, segmentation, or region classification is required.

The core value of the design is its direct hardware mapping of K-means-style color classification into a streaming architecture, avoiding software-style full-frame iteration and supporting predictable pixel-throughput operation.
