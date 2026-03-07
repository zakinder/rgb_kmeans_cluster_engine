## Functional Specification: Clustering Algorithm

### Function Name

**Clustering Algorithm**

### Purpose

The clustering algorithm assigns each incoming RGB pixel to the **nearest centroid** from a predefined set of cluster centers.

Its purpose is to:

* classify pixels into one of **K color groups**
* reduce color variation
* produce a centroid-mapped output image
* support segmentation and color quantization in hardware

---

## Functional Objective

For every valid input pixel, the algorithm:

1. reads the input RGB value
2. compares it against all centroid RGB values
3. computes a distance metric for each centroid
4. selects the centroid with the minimum distance
5. outputs the selected centroid color
6. optionally records the winning cluster index

---

## Inputs

### 1. Input Pixel

The current RGB pixel:

```text
P = (R, G, B)
```

### 2. Centroid Set

A set of `K` centroid RGB values:

```text
C0 = (R0, G0, B0)
C1 = (R1, G1, B1)
...
CK-1 = (RK-1, GK-1, BK-1)
```

### 3. Control Signals

Depending on implementation:

* pixel valid flag
* frame and line markers
* centroid LUT programming interface

---

## Outputs

### 1. Clustered Pixel

The RGB value of the nearest centroid:

```text
P_out = Cbest
```

### 2. Optional Cluster Index

The index of the winning centroid:

```text
best_cluster = j
```

### 3. Optional Distance Value

Minimum computed distance:

```text
Dmin
```

---

# 1. Functional Behavior

## Step 1: Receive Pixel

The algorithm accepts one input pixel from the streaming image source.

```text
P = (R,G,B)
```

---

## Step 2: Access Centroids

The algorithm reads all active centroid values from the centroid LUT.

```text
Ci = (Ri,Gi,Bi), for i = 0 to K-1
```

---

## Step 3: Compute Distance to Each Centroid

For each centroid, the algorithm computes a color-distance metric.

### Common FPGA-friendly metric: Manhattan Distance

```text
D(i) = |R - Ri| + |G - Gi| + |B - Bi|
```

Where:

* `R,G,B` are input pixel channels
* `Ri,Gi,Bi` are centroid channels for cluster `i`

This produces one scalar distance per centroid.

---

## Step 4: Compare Distances

All computed distances are compared.

The centroid with the smallest distance is selected:

```text
best_cluster = argmin D(i)
```

---

## Step 5: Generate Clustered Output

The selected centroid color becomes the output pixel color:

```text
P_out = C(best_cluster)
```

So the original pixel is replaced by the nearest representative cluster color.

---

## Step 6: Forward Control Metadata

If the pixel stream includes:

* valid
* start of frame
* end of line
* end of frame
* x/y coordinates

these fields are forwarded unchanged to the output stream.

---

# 2. Mathematical Definition

Given:

```text
P = (R, G, B)
Ci = (Ri, Gi, Bi)
```

Distance to centroid `i`:

```text
D(i) = |R - Ri| + |G - Gi| + |B - Bi|
```

Selected centroid index:

```text
j = argmin(D(i))
```

Output pixel:

```text
P_out = Cj
```

---

# 3. Example

## Input Pixel

```text
P = (100, 120, 140)
```

## Centroids

```text
C0 = (90, 110, 150)
C1 = (200, 210, 220)
C2 = (105, 122, 138)
```

## Distance Computation

### To `C0`

```text
D0 = |100-90| + |120-110| + |140-150|
   = 10 + 10 + 10
   = 30
```

### To `C1`

```text
D1 = |100-200| + |120-210| + |140-220|
   = 100 + 90 + 80
   = 270
```

### To `C2`

```text
D2 = |100-105| + |120-122| + |140-138|
   = 5 + 2 + 2
   = 9
```

## Selection

```text
best_cluster = 2
```

## Output Pixel

```text
P_out = (105, 122, 138)
```

---

# 4. Functional Inputs and Outputs in Hardware Terms

## Inputs

* `pixel_in_rgb`
* centroid LUT contents
* optional centroid selection/programming signals

## Outputs

* `pixel_out_rgb`
* optional centroid index
* optional minimum threshold value

---

# 5. Algorithm Type

## Static Clustering

If centroids are fixed, the algorithm performs **nearest-centroid classification** using preloaded values.

## K-Means-Style Inference

If centroids came from offline K-means training, the hardware performs **K-means inference**, not training.

## Adaptive Clustering

If centroids are updated at runtime, the same algorithm can support a dynamic clustering mode.

---

# 6. Distance Metric Options

## Implemented / Typical

### Manhattan Distance

```text
|R-Ri| + |G-Gi| + |B-Bi|
```

Advantages:

* simple hardware
* no multipliers
* low latency
* low resource cost

---

## Optional Alternative

### Euclidean Distance

```text
sqrt((R-Ri)^2 + (G-Gi)^2 + (B-Bi)^2)
```

Advantages:

* geometrically more accurate

Disadvantages:

* higher resource usage
* requires multiplication and possibly square root

In your design flow, Manhattan distance is the likely primary metric.

---

# 7. Operational Modes

## Mode 1: Color Quantization

Map each pixel to one of K representative colors.

## Mode 2: Segmentation

Treat each centroid as a color class and classify pixels into regions.

## Mode 3: Object/Feature Extraction

Use tuned centroids to isolate desired color targets.

---

# 8. Timing Behavior

## Streaming Operation

The algorithm processes pixels in sequence as they arrive.

## Throughput

Typically designed for:

```text
1 pixel per clock cycle
```

in a pipelined implementation.

## Latency

Depends on:

* number of comparison stages
* pipeline registers
* comparator tree depth

Typical latency:

* a few cycles for comparison and selection

---

# 9. Internal Functional Blocks

The clustering algorithm can be decomposed into these logical blocks:

### 1. Pixel Input Register

Captures incoming pixel.

### 2. Centroid LUT

Stores centroid RGB values.

### 3. Distance Computation Units

Compute one distance per centroid.

### 4. Minimum Comparator Tree

Finds smallest distance.

### 5. Centroid Selection MUX

Maps winning centroid to output pixel.

### 6. Output Register

Drives clustered output stream.

---

# 10. Functional Constraints

## Valid Pixel Requirement

Only valid pixels should be processed.

## Centroid Availability

Centroids must be loaded before active clustering begins.

## Index Range

Cluster index must remain within:

```text
0 to K-1
```

## Data Width Consistency

Pixel and centroid channel widths must match the configured channel width.

---

# 11. Design Intent

The clustering algorithm is designed to provide:

* deterministic real-time clustering
* hardware-efficient nearest-centroid classification
* scalable K-cluster support
* easy FPGA pipelining

It is optimized for image-processing pipelines where each pixel must be classified without stalling the stream.

---

# 12. Advantages

* simple and deterministic
* easy to parallelize
* suitable for FPGA implementation
* supports real-time streaming video
* enables segmentation and quantization

---

# 13. Limitations

* clustering quality depends on centroid choice
* fixed centroids do not adapt unless updated externally
* Manhattan distance is approximate compared to Euclidean distance
* large K increases logic and comparator cost

---

# 14. Document-Ready Functional Description

The clustering algorithm assigns each incoming RGB pixel to the nearest centroid in a predefined centroid set. For each pixel, the algorithm computes the color distance to every centroid, selects the centroid with the minimum distance, and outputs that centroid color as the clustered pixel result. In FPGA implementations, the algorithm is typically realized using parallel distance computation units, a minimum-distance comparator stage, and a centroid output selection stage, enabling deterministic real-time clustering of streaming image data.

---

# 15. Short Engineering Definition

The clustering algorithm is a nearest-centroid RGB classification process that maps each input pixel to the closest stored centroid color.

---

# 16. Summary

The clustering algorithm:

* reads one input pixel
* compares it against K centroids
* computes K distances
* selects the minimum-distance centroid
* outputs the centroid-mapped pixel

If you want, I can also write **Functional Specifications: Centroid LUT Design** in the same format.
