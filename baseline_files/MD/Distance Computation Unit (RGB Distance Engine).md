## Functional Specification: **Distance Computation Unit (RGB Distance Engine)**

### Module Context

Used inside:

* `rgb_cluster_core`
* `rgb_kmeans_cluster_engine`

### Purpose

The **Distance Computation Unit** calculates the color difference between an **input pixel** and a **centroid RGB value**.

The computed distance represents how similar the pixel color is to the centroid color.

This distance is used by the clustering algorithm to determine the **nearest centroid**.

---

# 1. Functional Objective

For a given pixel:

```
P = (R,G,B)
```

and centroid:

```
C = (Rc,Gc,Bc)
```

the unit computes a scalar distance value:

```
D = f(P,C)
```

where `f()` is the chosen distance metric.

---

# 2. Supported Distance Metric

The design uses **Manhattan Distance** because it is efficient in FPGA hardware.

### Manhattan Distance

```
D = |R - Rc| + |G - Gc| + |B - Bc|
```

Where:

| Variable | Meaning                 |
| -------- | ----------------------- |
| R,G,B    | Input pixel channels    |
| Rc,Gc,Bc | Centroid channels       |
| D        | Computed color distance |

---

# 3. Inputs

### Pixel Input

```
pixel_in_rgb.red
pixel_in_rgb.green
pixel_in_rgb.blue
```

Represents the RGB values of the current pixel.

---

### Centroid Input

```
k_rgb.red
k_rgb.gre
k_rgb.blu
```

Represents the centroid RGB color currently under comparison.

---

# 4. Output

### `threshold`

```
threshold : integer
```

Represents the computed color distance between the pixel and centroid.

Smaller values indicate a closer color match.

---

# 5. Functional Behavior

## Step 1 — Extract RGB Channels

```
R = pixel_in_rgb.red
G = pixel_in_rgb.green
B = pixel_in_rgb.blue
```

```
Rc = k_rgb.red
Gc = k_rgb.gre
Bc = k_rgb.blu
```

---

## Step 2 — Compute Channel Differences

```
diff_r = |R - Rc|
diff_g = |G - Gc|
diff_b = |B - Bc|
```

Absolute difference ensures positive values.

---

## Step 3 — Accumulate Distance

```
threshold = diff_r + diff_g + diff_b
```

This produces a single scalar distance value.

---

# 6. Hardware Datapath

The datapath is composed of simple arithmetic blocks:

```
           R ---------
                      | abs(R-Rc) |
Rc --------- SUB ---->|           |
                      |           |
           G ---------             |
                      | abs(G-Gc) |---- ADD ----
Gc --------- SUB ---->|           |             |
                      |           |             |
           B ---------             |             |---- ADD ---- threshold
                      | abs(B-Bc) |             |
Bc --------- SUB ---->|           |-------------
```

Components used:

| Component      | Purpose                                |
| -------------- | -------------------------------------- |
| Subtractors    | Compute channel differences            |
| Absolute units | Convert signed difference to magnitude |
| Adders         | Accumulate channel differences         |

---

# 7. Example Operation

### Input Pixel

```
P = (120, 150, 100)
```

### Centroid

```
C = (100, 140, 110)
```

### Channel Differences

```
diff_r = |120 - 100| = 20
diff_g = |150 - 140| = 10
diff_b = |100 - 110| = 10
```

### Distance

```
threshold = 20 + 10 + 10
threshold = 40
```

---

# 8. Distance Interpretation

| Threshold Value | Meaning                           |
| --------------- | --------------------------------- |
| Small value     | Pixel is very similar to centroid |
| Medium value    | Moderate similarity               |
| Large value     | Pixel far from centroid           |

The clustering engine chooses the **minimum threshold** among all centroids.

---

# 9. Maximum Distance Range

For 8-bit RGB channels:

```
0 ≤ R,G,B ≤ 255
```

Maximum difference per channel:

```
255
```

Maximum total Manhattan distance:

```
Dmax = 255 + 255 + 255
Dmax = 765
```

Therefore:

```
threshold range = 0 → 765
```

---

# 10. Timing Behavior

### Synchronous Operation

Distance computation occurs inside a clocked process.

```
if rising_edge(clk) then
   threshold <= diff_r + diff_g + diff_b;
end if;
```

---

### Pipeline Option

For high clock frequencies the computation may be pipelined:

Stage 1

```
diff_r
diff_g
diff_b
```

Stage 2

```
sum_rg
```

Stage 3

```
threshold
```

---

# 11. Resource Usage

The distance computation unit uses only simple arithmetic components.

| Resource           | Quantity |
| ------------------ | -------- |
| subtractors        | 3        |
| absolute operators | 3        |
| adders             | 2        |

This makes it extremely **FPGA efficient**.

---

# 12. Advantages

• very low logic complexity
• no multipliers required
• deterministic latency
• easy to pipeline
• suitable for real-time video pipelines

---

# 13. Limitations

• Manhattan distance is an approximation of true Euclidean distance
• color difference weighting is uniform across channels
• accuracy depends on centroid quality

---

# 14. Alternative Distance Metric (Optional)

Some systems use **Euclidean distance**:

```
D = sqrt((R-Rc)^2 + (G-Gc)^2 + (B-Bc)^2)
```

Advantages:

• more geometrically accurate

Disadvantages:

• requires multipliers
• requires square root
• higher FPGA resource usage

Your design likely uses Manhattan distance to keep the hardware lightweight.

---

# 15. Role in Clustering Pipeline

The distance computation unit performs the **core mathematical operation** used by the clustering algorithm.

Pipeline flow:

```
Pixel Input
     │
     ▼
Distance Computation Unit
     │
     ▼
Threshold Output
     │
     ▼
Minimum Distance Selector
     │
     ▼
Cluster Assignment
```

---

# 16. Document-Ready Description

The Distance Computation Unit calculates the color difference between the current input pixel and a centroid RGB value. It computes the Manhattan distance between the two RGB vectors and outputs the resulting threshold value. This threshold is used by the clustering engine to determine the nearest centroid for pixel classification.

---

# 17. Short Engineering Definition

The Distance Computation Unit computes the Manhattan RGB distance between a pixel and a centroid.

---

# 18. Summary

The distance computation unit:

• receives pixel RGB values
• receives centroid RGB values
• computes channel differences
• accumulates the differences
• outputs a scalar distance value used for cluster selection

---

If you'd like, I can next generate the **Comparator Tree / Minimum Distance Selector specification**, which is the **next block after the distance engine in the clustering pipeline**.
