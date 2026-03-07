## Functional Specification: `rgb_kmeans_cluster_engine`

### Module Name

`rgb_kmeans_cluster_engine`

### Purpose

`rgb_kmeans_cluster_engine` is the **top-level centroid-based RGB clustering module** in the design.

Its purpose is to:

* receive a streaming RGB pixel input
* store and manage centroid RGB values
* compare the input pixel against multiple centroids
* select the closest centroid
* output the clustered RGB pixel
* provide centroid LUT write/read access

This module performs the **full K-means-style pixel classification operation** in hardware.

---

## Functional Role in the System

`rgb_kmeans_cluster_engine` is the **cluster selection engine** that sits above the individual comparison core.

Where `rgb_cluster_core` computes the distance between one pixel and one centroid, `rgb_kmeans_cluster_engine` manages the full clustering flow across all configured centroids.

It is responsible for:

1. centroid storage
2. centroid programming
3. pixel-to-centroid comparison across K entries
4. minimum-distance selection
5. clustered pixel output generation

---

## Interface Summary

### Inputs

* `clk`
  System clock.

* `rst_n`
  Active-low reset.

* `pixel_in_rgb : channel`
  Incoming streaming RGB pixel with frame/line metadata.

* `centroid_lut_select : natural`
  Centroid selection input for programming or targeting a specific LUT entry.

* `centroid_lut_in : std_logic_vector(23 downto 0)`
  24-bit packed RGB data used to program a centroid.

* `k_ind_w : natural`
  Write index for centroid memory.

* `k_ind_r : natural`
  Read index for centroid memory.

### Outputs

* `centroid_lut_out : std_logic_vector(31 downto 0)`
  Readback output for centroid memory.

* `pixel_out_rgb : channel`
  Clustered output pixel stream.

---

## Representative Interface

```vhdl
entity rgb_kmeans_cluster_engine is
    generic (
        i_data_width  : integer := 8
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
end;
```

---

# 1. High-Level Functional Behavior

For each valid input pixel, the module:

1. obtains the pixel RGB value
2. compares it against all active centroid RGB entries
3. computes a distance metric for each centroid
4. finds the minimum distance
5. selects the corresponding centroid index
6. outputs the centroid RGB value as the clustered pixel color
7. forwards control and coordinate metadata unchanged

At the same time, the module supports:

* programming centroid entries into the LUT
* reading centroid entries back out

---

# 2. Core Functions

## 2.1 Centroid LUT Storage

The module maintains a LUT or memory structure containing RGB centroid values.

Each centroid entry typically stores:

* red
* green
* blue

Conceptually:

```text
centroid_lut[0] = (R0, G0, B0)
centroid_lut[1] = (R1, G1, B1)
...
centroid_lut[K-1] = (RK-1, GK-1, BK-1)
```

These entries define the active cluster centers.

---

## 2.2 Centroid Programming

The module supports loading or updating centroids through:

* `centroid_lut_select`
* `centroid_lut_in`
* `k_ind_w`

A typical write operation updates one centroid entry with one 24-bit RGB value.

Packed format:

```text
centroid_lut_in[23:16] = red
centroid_lut_in[15:8]  = green
centroid_lut_in[7:0]   = blue
```

---

## 2.3 Centroid Readback

The module supports observation of centroid contents through:

* `k_ind_r`
* `centroid_lut_out`

A selected centroid entry is returned on the output bus, typically as:

```text
centroid_lut_out[23:16] = red
centroid_lut_out[15:8]  = green
centroid_lut_out[7:0]   = blue
```

Optional upper bits may be zero-padded.

---

## 2.4 Pixel-to-Centroid Comparison

For every input pixel, the module computes distance to each centroid entry.

Typical metric:

```text
D(i) = |R - Ri| + |G - Gi| + |B - Bi|
```

Where:

* `(R,G,B)` is the input pixel
* `(Ri,Gi,Bi)` is centroid `i`

---

## 2.5 Best Cluster Selection

After computing the distances, the module finds the centroid with minimum distance:

```text
best_cluster = argmin D(i)
```

This centroid is treated as the winning cluster for the current pixel.

---

## 2.6 Output Pixel Generation

The output pixel inherits the selected centroid color:

```text
pixel_out_rgb.red   = centroid(best_cluster).red
pixel_out_rgb.green = centroid(best_cluster).green
pixel_out_rgb.blue  = centroid(best_cluster).blue
```

Control signals and coordinates are propagated from the input pixel.

---

# 3. Functional Decomposition

## 3.1 Input Stream Handling

The module receives one streaming pixel record `pixel_in_rgb`.

This record includes:

* `valid`
* `sof`
* `eol`
* `eof`
* `xcnt`
* `ycnt`
* `red`
* `green`
* `blue`

The module uses the RGB channels for clustering and forwards the control fields to the output path.

---

## 3.2 Centroid Memory Block

A centroid LUT stores the set of cluster centers.

### Functional responsibilities

* initialize or reset centroids
* update one centroid entry on write
* provide one centroid entry on readback
* make centroid values available to the comparison engine

---

## 3.3 Distance Computation Block

For each centroid, compute the color separation between the input pixel and that centroid.

This may be implemented as:

* a replicated array of comparison blocks
* a loop-based comparator structure
* a pipeline over centroid indices

---

## 3.4 Minimum Comparator Block

This block compares all distance values and selects the minimum.

Outputs of this stage:

* best distance
* best centroid index

---

## 3.5 Output Mapping Block

This block maps the winning centroid back into output RGB.

It also preserves:

* frame timing
* line timing
* pixel coordinates

---

# 4. Detailed Signal Behavior

## 4.1 `pixel_in_rgb`

Streaming input pixel record.

Used for:

* pixel color extraction
* frame/line synchronization
* coordinate forwarding

## 4.2 `centroid_lut_select`

Centroid targeting input used during centroid programming.

## 4.3 `centroid_lut_in`

24-bit RGB input value for centroid writes.

## 4.4 `k_ind_w`

Centroid write index.

## 4.5 `k_ind_r`

Centroid read index.

## 4.6 `centroid_lut_out`

Selected centroid readback bus.

## 4.7 `pixel_out_rgb`

Clustered output pixel record.

---

# 5. Timing Behavior

## Clocking

The module is synchronous to `clk`.

## Reset

When `rst_n = '0'`:

* centroid memory is reset or cleared
* output pixel registers are cleared
* internal selection state is reset

## Latency

Latency depends on implementation style.

Typical stages:

1. pixel register/input alignment
2. centroid comparison
3. minimum selection
4. output registration

Typical range:

* a few cycles in simple designs
* more in highly pipelined versions

---

# 6. Mathematical Model

Let the input pixel be:

```text
P = (R,G,B)
```

Let centroid `i` be:

```text
C(i) = (Ri,Gi,Bi)
```

Distance to centroid `i`:

```text
D(i) = |R - Ri| + |G - Gi| + |B - Bi|
```

Winning centroid:

```text
j = argmin(D(i))
```

Output pixel:

```text
P_out = C(j)
```

This is a centroid-based color quantization/classification model.

---

# 7. Example Operation

## Given input pixel

```text
P = (100, 120, 140)
```

## Centroids

```text
C0 = (90, 110, 150)
C1 = (200, 210, 220)
C2 = (105, 122, 138)
```

## Distances

```text
D0 = |100-90| + |120-110| + |140-150| = 30
D1 = |100-200| + |120-210| + |140-220| = 270
D2 = |100-105| + |120-122| + |140-138| = 9
```

## Selected centroid

```text
best_cluster = C2
```

## Output

```text
pixel_out_rgb = (105, 122, 138)
```

The output pixel becomes the nearest centroid color.

---

# 8. Use Cases

## 8.1 Color Quantization

Reduce a full-color image to K representative colors.

## 8.2 Image Segmentation

Assign pixels to regions or classes based on nearest centroid.

## 8.3 Object/Region Detection

Use tuned centroids for specific color-based targets.

## 8.4 Adaptive Color Classification

Update centroid values over time for changing scene conditions.

---

# 9. Design Intent

`rgb_kmeans_cluster_engine` is intended to provide a hardware-efficient clustering engine for real-time image streams.

It is designed for:

* FPGA streaming architectures
* low-latency pixel processing
* scalable centroid comparison
* modular centroid programming and observation

The design avoids expensive software-style iteration over full frames and instead performs pixel classification inline with the video stream.

---

# 10. Advantages

* real-time streaming operation
* deterministic behavior
* scalable to multiple centroids
* suitable for FPGA pipelining
* easy integration with video-processing chains
* supports programmable centroid LUTs

---

# 11. Limitations

* clustering quality depends on centroid choice
* Manhattan distance is efficient but approximate relative to Euclidean distance
* very large K may require more resources or deeper pipelines
* centroid update/training may be external to this module

---

# 12. Resource Considerations

The module may consume:

* LUTs for absolute difference and compare logic
* registers for pipeline stages
* optional BRAM/register arrays for centroid storage
* comparator tree logic for minimum selection

Resource cost scales with:

* number of centroids
* channel width
* degree of parallelism
* pipeline depth

---

# 13. Relationship to `rgb_cluster_core`

`rgb_cluster_core` is the primitive comparison block.
`rgb_kmeans_cluster_engine` is the system-level clustering engine built around that function.

### Relationship summary

* `rgb_cluster_core` → one pixel vs one centroid
* `rgb_kmeans_cluster_engine` → one pixel vs all centroids + select winner

---

# 14. Recommended Cleaner Naming

| Current Name                | Recommended Name        |
| --------------------------- | ----------------------- |
| `rgb_kmeans_cluster_engine` | `rgb_centroid_selector` |
| `rgb_kmeans_cluster_engine` | `rgb_cluster_engine`    |
| `rgb_kmeans_cluster_engine` | `rgb_kmeans_quantizer`  |

Best choice:

```vhdl
rgb_cluster_engine
```

because the current design is primarily performing centroid-based assignment/output mapping, which is the operational heart of the clustering flow.

---

# 15. Document-Ready Functional Description

`rgb_kmeans_cluster_engine` is the top-level RGB clustering module responsible for assigning each incoming pixel to the nearest centroid color. It stores and manages centroid values in a lookup table, computes the color distance between the input pixel and all active centroids, selects the centroid with the minimum distance, and outputs the selected centroid color as the clustered pixel. The module also provides centroid programming and readback interfaces for runtime configuration, monitoring, and verification.

---

# 16. Short Engineering Definition

`rgb_kmeans_cluster_engine` is a synchronous FPGA module that performs multi-centroid RGB pixel classification and clustered color output generation.

---

# 17. Summary

`rgb_kmeans_cluster_engine`:

* stores centroid RGB values
* accepts streaming input pixels
* compares each pixel to all centroids
* selects the nearest centroid
* outputs the centroid-mapped pixel
* supports centroid write/read control

If you want, I can next write the **functional specification for `square_root` in the same full format** so all three modules match.
