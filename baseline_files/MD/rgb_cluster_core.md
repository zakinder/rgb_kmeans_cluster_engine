## Functional Specification: `rgb_cluster_core`

### Module Name

`rgb_cluster_core`

### Purpose

`rgb_cluster_core` is the **pixel-to-centroid comparison block** of the clustering architecture.

Its main function is to compute the **color distance** between:

* the current input RGB pixel, and
* one candidate RGB centroid

The output of this block is a scalar threshold or distance value used by higher-level clustering logic to determine the best matching cluster.

---

## Functional Role in the System

`rgb_cluster_core` is a **single-cluster comparison engine**.

In a K-means or LUT-based clustering architecture, the full system typically compares one input pixel against multiple centroids. `rgb_cluster_core` performs the comparison against **one centroid at a time**.

This makes it suitable for:

* parallel replication across K clusters
* pipelined centroid comparison
* modular clustering architectures

---

## Primary Inputs and Outputs

### Inputs

* `clk`
  System clock.

* `rst_n`
  Active-low synchronous reset.

* `pixel_in_rgb : channel`
  Input RGB pixel record containing pixel control flags, coordinates, and RGB color values.

* `k_rgb : int_rgb`
  Active centroid RGB value used as the comparison reference.

### Output

* `threshold : integer`
  Distance metric between the input pixel and the active centroid.

---

## Interface Definition

```vhdl
entity rgb_cluster_core is
generic (
    data_width : integer := 8
);
port (
    clk          : in std_logic;
    rst_n        : in std_logic;
    pixel_in_rgb : in channel;
    k_rgb        : in int_rgb;
    threshold    : out integer
);
end;
```

---

## Functional Behavior

### 1. Input Pixel Reception

The module receives one RGB pixel through `pixel_in_rgb`.

Relevant pixel fields for comparison:

* `pixel_in_rgb.red`
* `pixel_in_rgb.green`
* `pixel_in_rgb.blue`

These values represent the current pixel color.

---

### 2. Active Centroid Reception

The module also receives one centroid RGB value through `k_rgb`.

Relevant centroid fields:

* `k_rgb.red`
* `k_rgb.gre`
* `k_rgb.blu`

This centroid acts as the comparison target.

---

### 3. Distance Calculation

The module computes the color difference between the pixel and centroid.

The intended metric is typically **Manhattan distance**:

```text
threshold = |R - Rc| + |G - Gc| + |B - Bc|
```

Where:

* `R, G, B` are the input pixel values
* `Rc, Gc, Bc` are the centroid values

This distance is output on `threshold`.

---

### 4. Registered Output

The threshold result is typically updated on the rising edge of `clk`.

This makes the block suitable for:

* synchronous FPGA pipelines
* stable timing closure
* deterministic latency

---

## Detailed Functional Description

### Pixel Channel Extraction

The module extracts the input pixel color channels and converts them into integer form if needed.

Conceptually:

```text
pixel_red   = pixel_in_rgb.red
pixel_green = pixel_in_rgb.green
pixel_blue  = pixel_in_rgb.blue
```

---

### Centroid Comparison

The module compares the input pixel against the active centroid:

```text
diff_red   = |pixel_red   - k_rgb.red|
diff_green = |pixel_green - k_rgb.gre|
diff_blue  = |pixel_blue  - k_rgb.blu|
```

---

### Threshold Generation

The final distance is:

```text
threshold = diff_red + diff_green + diff_blue
```

This single numeric value represents how close the pixel is to that centroid.

---

## Operational Interpretation

### Small Threshold

A smaller threshold means:

* the input pixel is close to the centroid color
* the centroid is a strong candidate cluster match

### Large Threshold

A larger threshold means:

* the pixel is far from the centroid color
* the centroid is a weaker candidate

---

## Typical System Usage

### Parallel Cluster Comparison

Multiple instances of `rgb_cluster_core` can be instantiated in parallel:

* instance 0 compares against centroid 0
* instance 1 compares against centroid 1
* instance 2 compares against centroid 2
* etc.

Then a higher-level comparator selects the minimum threshold.

---

### Sequential Cluster Comparison

A controller may reuse one `rgb_cluster_core` block by feeding different centroid values over time and storing the threshold results.

---

## Timing Behavior

### Clocking

The module is synchronous to `clk`.

### Reset

When `rst_n = '0'`:

* internal registered outputs are reset
* `threshold` is typically cleared to zero or a default value

### Latency

Typical latency:

* 1 clock cycle if threshold is registered directly
* possibly more if additional pipeline stages are used

---

## Data Types

### `pixel_in_rgb`

Usually a record type carrying:

* control fields: `valid`, `sof`, `eol`, `eof`
* coordinates: `xcnt`, `ycnt`
* RGB channels: `red`, `green`, `blue`

### `k_rgb`

Usually a record type:

```vhdl
type int_rgb is record
    red : integer;
    gre : integer;
    blu : integer;
end record;
```

### `threshold`

Integer distance output.

---

## Design Intent

`rgb_cluster_core` is intentionally simple and hardware-efficient.

It is designed to provide:

* fast color comparison
* low arithmetic complexity
* easy replication for K-cluster designs
* deterministic behavior in streaming pipelines

It avoids more expensive operations such as:

* multiplication
* square root
* floating-point arithmetic

when Manhattan distance is sufficient.

---

## Mathematical Model

Given:

```text
P = (R, G, B)
C = (Rc, Gc, Bc)
```

The module computes:

```text
D(P,C) = |R - Rc| + |G - Gc| + |B - Bc|
```

and outputs:

```text
threshold = D(P,C)
```

---

## Example

### Input Pixel

```text
pixel_in_rgb = (100, 120, 140)
```

### Centroid

```text
k_rgb = (90, 110, 150)
```

### Computation

```text
|100 - 90|  = 10
|120 - 110| = 10
|140 - 150| = 10
```

### Output

```text
threshold = 30
```

Interpretation:

* centroid is reasonably close to the pixel

---

## Relationship to Other Blocks

| Related Block / Signal      | Relationship                                                     |
| --------------------------- | ---------------------------------------------------------------- |
| `k_rgb_lut`                 | provides centroid values that may feed `k_rgb`                   |
| `rgb_kmeans_cluster_engine` | instantiates or coordinates multiple centroid comparisons        |
| `threshold`                 | output used for minimum-distance cluster selection               |
| `pixel_in_rgb`              | supplies source pixel color                                      |
| `pixel_out_rgb`             | later assigned from selected centroid after threshold comparison |

---

## Constraints and Assumptions

### Assumptions

* RGB channel widths are consistent with `data_width`
* centroid values are valid and within expected range
* input pixel values are valid when used for comparison

### Constraints

* if `data_width = 8`, pixel channels are expected in range `0..255`
* threshold must be large enough to represent the maximum possible channel sum

For 8-bit RGB and Manhattan distance:

```text
max threshold = 255 + 255 + 255 = 765
```

So integer output is sufficient.

---

## Advantages

* small hardware footprint
* easy to pipeline
* scalable to many centroids
* deterministic and stable
* suitable for real-time video clustering

---

## Limitations

* compares against one centroid per instance
* Manhattan distance is simpler than Euclidean distance, but may be less geometrically precise
* accuracy depends on centroid quality and chosen color space

---

## Recommended Clearer Naming

| Current Name       | Recommended Name             |
| ------------------ | ---------------------------- |
| `rgb_cluster_core` | `rgb_centroid_distance_core` |
| `rgb_cluster_core` | `rgb_cluster_compare_core`   |
| `rgb_cluster_core` | `rgb_distance_core`          |

Best option:

```vhdl
rgb_cluster_compare_core
```

because it states that the module compares a pixel to a centroid rather than performing the entire clustering decision alone.

---

## Document-Ready Functional Description

`rgb_cluster_core` is the fundamental RGB centroid comparison module within the clustering architecture. It receives an input RGB pixel and one active centroid RGB value, computes the color distance between them, and outputs the resulting threshold value. This threshold is used by higher-level clustering logic to determine which centroid most closely matches the input pixel. The module is intended for synchronous FPGA implementation and supports efficient replication in multi-centroid K-means architectures.

---

## Short Engineering Definition

`rgb_cluster_core` is a synchronous RGB pixel-to-centroid distance computation block.

---

## Summary

`rgb_cluster_core`:

* receives one pixel
* receives one centroid
* computes color distance
* outputs one threshold value
* serves as the comparison primitive for the larger clustering engine

I can do the same full functional specification for `rgb_kmeans_cluster_engine` next.
