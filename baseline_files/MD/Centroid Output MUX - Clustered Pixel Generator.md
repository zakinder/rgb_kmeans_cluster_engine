## Functional Specification: **Centroid Output MUX / Clustered Pixel Generator**

### Module Context

Used inside:

* `rgb_kmeans_cluster_engine`

Consumes outputs from:

* Comparator Tree / Minimum Distance Selector
* Centroid LUT

### Purpose

The **Centroid Output MUX / Clustered Pixel Generator** produces the final clustered output pixel.

It uses the selected winning centroid index and maps that centroid’s RGB value onto the output pixel stream, while preserving the input pixel’s control and coordinate metadata.

This block is the final color-mapping stage of the clustering pipeline.

---

# 1. Functional Objective

Given:

* the winning centroid index
* the centroid LUT contents
* the current pixel control metadata

the block generates:

```text
pixel_out_rgb = clustered output pixel
```

where:

* control signals are forwarded
* RGB values are replaced by the selected centroid color

---

# 2. Inputs

### 1. Winning Cluster Index

```text
best_cluster
```

Produced by the Comparator Tree / Minimum Distance Selector.

This identifies which centroid is nearest to the input pixel.

---

### 2. Centroid LUT Data

The stored centroid RGB values:

```text
C0, C1, C2, ..., CK-1
```

The block selects one of these entries based on `best_cluster`.

---

### 3. Input Pixel Metadata

Usually from `pixel_in_rgb`:

* `valid`
* `sof`
* `eol`
* `eof`
* `xcnt`
* `ycnt`

These fields are preserved and forwarded to the output.

---

# 3. Output

### `pixel_out_rgb`

Clustered output pixel record.

Contains:

* forwarded control fields
* forwarded coordinates
* RGB channels replaced with centroid color

---

# 4. Functional Behavior

## Step 1 — Receive Winning Cluster

The block receives the centroid index selected by the minimum-distance logic:

```text
best_cluster = j
```

---

## Step 2 — Select Centroid RGB

The output MUX selects the corresponding centroid entry:

```text
selected_centroid = centroid_lut(best_cluster)
```

---

## Step 3 — Forward Control Metadata

The block copies the non-color fields from input to output:

```text
pixel_out_rgb.valid = pixel_in_rgb.valid
pixel_out_rgb.sof   = pixel_in_rgb.sof
pixel_out_rgb.eol   = pixel_in_rgb.eol
pixel_out_rgb.eof   = pixel_in_rgb.eof
pixel_out_rgb.xcnt  = pixel_in_rgb.xcnt
pixel_out_rgb.ycnt  = pixel_in_rgb.ycnt
```

---

## Step 4 — Replace RGB Channels

The RGB color of the output pixel is set to the selected centroid RGB:

```text
pixel_out_rgb.red   = centroid_lut(best_cluster).red
pixel_out_rgb.green = centroid_lut(best_cluster).green
pixel_out_rgb.blue  = centroid_lut(best_cluster).blue
```

---

# 5. Mathematical Meaning

If the clustering decision is:

```text
best_cluster = j
```

then the output pixel becomes:

```text
P_out = Cj
```

Where:

* `P_out` is the clustered output pixel
* `Cj` is the centroid corresponding to index `j`

This is the color-quantization step of the algorithm.

---

# 6. Example Operation

## Input Pixel

```text
pixel_in_rgb = (valid=1, xcnt=25, ycnt=10, RGB=(100,120,140))
```

## Centroids

```text
C0 = (90,110,150)
C1 = (200,210,220)
C2 = (105,122,138)
```

## Winning Index

```text
best_cluster = 2
```

## Output Pixel

```text
pixel_out_rgb.valid = 1
pixel_out_rgb.xcnt  = 25
pixel_out_rgb.ycnt  = 10
pixel_out_rgb.red   = 105
pixel_out_rgb.green = 122
pixel_out_rgb.blue  = 138
```

The pixel keeps its location and timing, but its color is replaced by the centroid color.

---

# 7. Functional Mapping Table

| Input / Control         | Output Behavior                    |
| ----------------------- | ---------------------------------- |
| `pixel_in_rgb.valid`    | forwarded to `pixel_out_rgb.valid` |
| `pixel_in_rgb.sof`      | forwarded to `pixel_out_rgb.sof`   |
| `pixel_in_rgb.eol`      | forwarded to `pixel_out_rgb.eol`   |
| `pixel_in_rgb.eof`      | forwarded to `pixel_out_rgb.eof`   |
| `pixel_in_rgb.xcnt`     | forwarded to `pixel_out_rgb.xcnt`  |
| `pixel_in_rgb.ycnt`     | forwarded to `pixel_out_rgb.ycnt`  |
| `best_cluster`          | selects centroid entry             |
| selected centroid red   | drives `pixel_out_rgb.red`         |
| selected centroid green | drives `pixel_out_rgb.green`       |
| selected centroid blue  | drives `pixel_out_rgb.blue`        |

---

# 8. Multiplexer Behavior

The block behaves like an RGB multiplexer indexed by `best_cluster`.

Conceptually:

```text
case best_cluster is
    when 0 => output_rgb = C0
    when 1 => output_rgb = C1
    when 2 => output_rgb = C2
    ...
    when K-1 => output_rgb = CK-1
end case
```

This may be implemented as:

* direct LUT indexing
* case statement
* array selection
* registered MUX output

---

# 9. Timing Behavior

## Combinational Version

The centroid color is selected directly from the LUT using the winning index.

### Advantages

* minimal latency

### Disadvantages

* wider combinational path

---

## Registered Version

The selected centroid RGB is captured in output registers on `clk`.

Example:

```vhdl
if rising_edge(clk) then
    pixel_out_rgb.red   <= selected_centroid.red;
    pixel_out_rgb.green <= selected_centroid.green;
    pixel_out_rgb.blue  <= selected_centroid.blue;
end if;
```

### Advantages

* better timing closure
* stable output alignment

### Disadvantages

* adds pipeline latency

---

# 10. Pipeline Alignment

If the clustering engine is pipelined, the following must remain aligned for the same pixel:

* `best_cluster`
* centroid RGB selected from LUT
* `valid`
* `sof`
* `eol`
* `eof`
* `xcnt`
* `ycnt`

All metadata and selected RGB must emerge in the same output cycle.

---

# 11. Role in the Clustering Pipeline

The Centroid Output MUX / Clustered Pixel Generator is the final stage after cluster decision.

Pipeline view:

```text
Pixel Input
    │
    ▼
Distance Computation Units
    │
    ▼
Comparator Tree / Minimum Selector
    │
    ▼
Winning Cluster Index
    │
    ▼
Centroid Output MUX / Clustered Pixel Generator
    │
    ▼
pixel_out_rgb
```

---

# 12. Design Intent

This block is designed to:

* convert the abstract clustering decision into a real output pixel
* preserve raster-stream timing
* map each pixel to its nearest centroid color
* support real-time image quantization and segmentation

It is the block that makes the clustering result visible in the output image.

---

# 13. Advantages

* simple hardware structure
* deterministic color mapping
* easy to pipeline
* preserves frame/line/pixel metadata
* directly supports real-time clustered image output

---

# 14. Limitations

* output color is restricted to stored centroid values
* incorrect centroid programming directly affects output image quality
* if pipeline alignment is wrong, metadata and color may mismatch

---

# 15. Design Constraints

### Valid Index Range

The winning centroid index must satisfy:

```text
0 ≤ best_cluster < K
```

### LUT Availability

Selected centroid data must be valid and stable when sampled.

### Metadata Alignment

Control fields must be delayed or forwarded consistently with the selected RGB.

---

# 16. Optional Variants

## Variant A — Output RGB Only

Only RGB channels are generated; control metadata handled elsewhere.

## Variant B — Full Pixel Record Output

Entire `channel` record is generated in the same block.

## Variant C — Output RGB + Cluster ID

In addition to clustered RGB, the design may also output:

```text
cluster_id = best_cluster
```

This is useful for segmentation maps and debug visibility.

---

# 17. Document-Ready Functional Description

The Centroid Output MUX / Clustered Pixel Generator receives the centroid index selected by the minimum-distance logic and uses that index to select the corresponding centroid RGB value from the centroid LUT. It generates the final clustered output pixel by replacing the input pixel’s RGB channels with the selected centroid color while preserving the input control and coordinate fields. This block forms the final color-mapping stage of the clustering engine.

---

# 18. Short Engineering Definition

The Centroid Output MUX / Clustered Pixel Generator maps the winning centroid index to the final clustered output pixel color.

---

# 19. Summary

The Centroid Output MUX / Clustered Pixel Generator:

* receives the winning centroid index
* selects the corresponding centroid RGB value
* forwards pixel timing/control metadata
* outputs the final clustered pixel stream

The next logical section is **Functional Specification: Pixel Stream Control and Metadata Handling**.
