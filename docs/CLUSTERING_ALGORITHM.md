# Clustering Algorithm — RGB K-Means Cluster Engine

**Designer Name:** Sakinder Ali  
**Module:** `rgb_kmeans_cluster_engine`

---

## 1. Algorithm Purpose

The clustering algorithm assigns every input RGB pixel to the closest RGB centroid. The selected centroid color becomes the output pixel color.

This produces a reduced-color representation of the input stream and supports segmentation, color-region detection, palette mapping, and real-time visual classification.

---

## 2. Input Model

For each pixel:

```text
P = (R, G, B)
```

Where:

- `R` is the red channel value.
- `G` is the green channel value.
- `B` is the blue channel value.

For 8-bit channels:

```text
0 <= R,G,B <= 255
```

---

## 3. Centroid Model

The design stores `K` centroid entries:

```text
C(0), C(1), ..., C(K-1)
```

Each centroid is an RGB tuple:

```text
C(i) = (Ri, Gi, Bi)
```

---

## 4. Distance Metric

The preferred hardware metric is Manhattan RGB distance:

```text
D(i) = |R - Ri| + |G - Gi| + |B - Bi|
```

This metric is hardware-efficient because it avoids multiplication and square-root operations.

---

## 5. Cluster Selection

The selected cluster is the centroid with the smallest distance:

```text
best_cluster = argmin D(i)
```

The output color is:

```text
P_out = C(best_cluster)
```

---

## 6. Algorithm Flow

```text
for each valid input pixel:
    read R, G, B

    for each centroid i:
        red_delta   = abs(R - Ri)
        green_delta = abs(G - Gi)
        blue_delta  = abs(B - Bi)
        distance[i] = red_delta + green_delta + blue_delta

    best_cluster = index_of_min(distance)
    output_rgb = centroid[best_cluster]
```

---

## 7. Tie-Breaking Rule

If two or more centroids produce the same minimum distance, the recommended deterministic rule is:

```text
select the lowest centroid index
```

This prevents unstable output behavior when a pixel lies equally between two centroid colors.

---

## 8. Example

Input pixel:

```text
P = (100, 120, 140)
```

Centroids:

```text
C0 = (90, 110, 150)
C1 = (200, 210, 220)
C2 = (105, 122, 138)
```

Distances:

```text
D0 = |100-90|  + |120-110| + |140-150| = 30
D1 = |100-200| + |120-210| + |140-220| = 270
D2 = |100-105| + |120-122| + |140-138| = 9
```

Selected centroid:

```text
best_cluster = C2
```

Output:

```text
P_out = (105, 122, 138)
```

---

## 9. Hardware Mapping

| Algorithm Step | Hardware Block |
|---|---|
| RGB extraction | Input capture register |
| Centroid access | LUT/register/BRAM centroid table |
| Absolute channel differences | Subtractor + absolute-value logic |
| Distance sum | Adders |
| Minimum selection | Comparator tree |
| Output color selection | Centroid MUX |

---

## 10. Summary

The clustering algorithm converts each RGB input pixel into the nearest centroid color using deterministic, hardware-efficient distance comparison. It is suitable for FPGA streaming pipelines because it can be implemented with simple arithmetic, comparator logic, and pipeline registers.
