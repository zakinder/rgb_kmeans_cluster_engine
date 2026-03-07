## Functional Specification: `k_rgb_lut`

### Signal / Object Name

`k_rgb_lut`

### Type

Typically an array of RGB centroid values.

From your design style, it is used as a **lookup table of K centroid colors** for clustering operations.

A representative form is:

```vhdl
type rgb_k_range is array(natural range <>) of k_range;
signal k_rgb_lut : rgb_k_range(0 to K-1);
```

or equivalently as a constant/table of RGB entries.

---

## Purpose

`k_rgb_lut` stores the set of **reference RGB centroid values** used by the clustering engine to classify or quantize incoming pixels.

Each LUT entry corresponds to **one cluster center**.

---

## Functional Role

`k_rgb_lut` is the centroid memory used for pixel-to-cluster comparison.

For each input pixel:

1. The pixel RGB value is compared against LUT entries
2. A distance metric is computed for each entry
3. The closest LUT entry is selected
4. The output pixel is mapped to that selected centroid color

So `k_rgb_lut` is the **core color reference table** of the K-means engine.

---

## Conceptual Meaning

If the clustering engine is configured for `K = 5`, then `k_rgb_lut` contains 5 RGB centroid values:

```text
k_rgb_lut(0) = centroid 0
k_rgb_lut(1) = centroid 1
k_rgb_lut(2) = centroid 2
k_rgb_lut(3) = centroid 3
k_rgb_lut(4) = centroid 4
```

Each entry defines one candidate cluster color.

---

## Data Content

Each LUT element typically stores:

* red component
* green component
* blue component

Example conceptual entry:

```vhdl
k_rgb_lut(i) = (R_i, G_i, B_i)
```

If `k_range` is a record or tuple-like type, then each LUT entry contains one RGB centroid triplet.

---

## Functional Behavior

### 1. Centroid Storage

`k_rgb_lut` holds the current active cluster centroids used by the design.

These may be:

* statically initialized
* loaded from predefined constants
* selected from multiple LUT banks
* updated at runtime

---

### 2. Reference Table for Distance Computation

For each incoming pixel `(R,G,B)`, the engine computes distance to each LUT entry:

```text
D(i) = |R - k_rgb_lut(i).red|
     + |G - k_rgb_lut(i).green|
     + |B - k_rgb_lut(i).blue|
```

or another equivalent distance function used in your architecture.

---

### 3. Cluster Selection Source

The minimum-distance LUT entry determines the selected cluster:

```text
best_cluster = argmin D(i)
```

The selected LUT entry provides the replacement/output RGB value.

---

### 4. Output Quantization / Color Mapping

Once a centroid is chosen, its RGB value may be sent to output:

```text
pixel_out_rgb := k_rgb_lut(best_cluster)
```

This produces clustered or quantized color output.

---

## Typical Usage Scenarios

### Use Case 1: Fixed Color Segmentation

The LUT contains manually chosen centroid colors, for example:

* black
* gray
* skin-tone range
* brown
* white

Used for deterministic color segmentation.

---

### Use Case 2: Pretrained K-Means Centroids

The LUT stores centroid values obtained from offline training or prior image analysis.

Used for hardware deployment of trained color clusters.

---

### Use Case 3: Runtime Reconfiguration

Different LUT banks or entries are loaded for different image modes:

* daylight profile
* indoor profile
* road/lane profile
* object tracking profile

---

## Design Intent

`k_rgb_lut` provides a compact, deterministic, and high-speed memory structure for centroid lookup in a streaming FPGA architecture.

It allows:

* parallel comparison
* low-latency classification
* easy reconfiguration
* structured mapping from pixel space to cluster space

---

## Relation to Other Signals

| Related Object        | Relationship                                              |
| --------------------- | --------------------------------------------------------- |
| `pixel_in_rgb`        | input pixel is compared against LUT entries               |
| `threshold`           | distance result may be computed relative to one LUT entry |
| `centroid_lut_select` | may select which centroid/LUT entry is being addressed    |
| `k_ind_w`             | may control which LUT entry is updated                    |
| `k_ind_r`             | may control which LUT entry is read                       |
| `pixel_out_rgb`       | selected LUT entry may drive output RGB                   |

---

## Expected Structure

### Example with record-like entry

```vhdl
type int_rgb is record
    red : integer;
    gre : integer;
    blu : integer;
end record;

type rgb_k_range is array(natural range <>) of int_rgb;
signal k_rgb_lut : rgb_k_range(0 to K-1);
```

### Example with constant LUT

```vhdl
constant k_rgb_lut : rgb_k_range(0 to 4) := (
    (255, 240, 230),
    (240, 220, 210),
    (180, 140, 160),
    (150, 100,  80),
    (130, 120, 100)
);
```

---

## Access Behavior

### Read Access

During clustering, entries are read by index:

```vhdl
k_rgb_lut(i)
```

This access is used inside:

* comparison loops
* parallel cluster blocks
* output selection logic

### Write / Update Access

If implemented as a signal or RAM-like structure, entries may be updated by control logic.

If implemented as a constant, values are fixed at synthesis time.

---

## Timing Behavior

### Combinational Use

If the LUT is a constant or directly indexed signal array, reads are typically combinational.

### Sequential Use

If values are registered or stored in synchronous memory, access may occur on the clock edge.

The exact timing depends on implementation style.

---

## Range / Capacity

If the clustering engine supports `K` centroids, then:

```vhdl
k_rgb_lut(0 to K-1)
```

Example:

* `K = 5` → entries 0 to 4
* `K = 30` → entries 0 to 29

---

## Engineering Interpretation

`k_rgb_lut` is the **color centroid bank** of the clustering design.

It is effectively the hardware equivalent of the centroid matrix in a software K-means algorithm.

Software analogy:

```python
centroids = [
    [R0, G0, B0],
    [R1, G1, B1],
    ...
]
```

Hardware analogy:

```vhdl
k_rgb_lut(i)
```

---

## Document-Ready Functional Description

`k_rgb_lut` is the centroid RGB lookup table used by the clustering architecture. It stores the set of reference RGB values representing the active cluster centers. During operation, each input pixel is compared against the entries in `k_rgb_lut`, and the LUT entry with the minimum color distance is selected as the best matching cluster. The selected centroid may then be used to determine the output color or cluster assignment.

---

## Short Engineering Definition

`k_rgb_lut` = **RGB centroid lookup table**

---

## Recommended Clearer Names

| Current Name | Recommended Name       |
| ------------ | ---------------------- |
| `k_rgb_lut`  | `centroid_rgb_lut`     |
| `k_rgb_lut`  | `cluster_centroid_lut` |
| `k_rgb_lut`  | `centroid_table`       |

Best choice:

```vhdl
centroid_rgb_lut
```

because it directly states:

* centroid
* RGB
* LUT

---

## Optional Stronger Type Style

For readability, this is cleaner:

```vhdl
type rgb_centroid_t is record
    red   : integer;
    green : integer;
    blue  : integer;
end record;

type centroid_lut_t is array (natural range <>) of rgb_centroid_t;
signal centroid_rgb_lut : centroid_lut_t(0 to K-1);
```

This improves:

* readability
* documentation quality
* maintenance

---

## Summary

`k_rgb_lut` is the internal RGB centroid table used by the clustering engine to classify incoming pixels into one of K color clusters. It serves as the reference color bank for distance computation, cluster decision, and output color mapping.

I can next write the **functional specifications for `threshold`, `k_rgb`, and `k_ind_w/k_ind_r` together as one centroid-interface section**.
