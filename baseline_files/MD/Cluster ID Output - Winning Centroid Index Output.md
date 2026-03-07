## Functional Specification: **Cluster ID Output / Winning Centroid Index Output**

### Signal Name

`cluster_id`
(Internally often represented by `int_min_id`)

### Module Context

Used in:

* `rgb_kmeans_cluster_engine`
* output stage of clustering pipeline
* centroid output MUX

### Purpose

The **Cluster ID Output** represents the **index of the centroid selected as the closest match** to the input pixel.

This signal identifies which cluster the pixel belongs to.

It may be used for:

* centroid color selection
* segmentation map generation
* debug and verification
* downstream classification stages

---

# 1. Functional Objective

After comparing distances between the input pixel and all centroids, the clustering engine determines:

```text
best_cluster = argmin(D(i))
```

Where:

```
D(i) = distance(pixel, centroid_i)
```

The signal `cluster_id` outputs:

```
cluster_id = best_cluster
```

---

# 2. Relationship to Internal Signals

| Signal        | Function                                      |
| ------------- | --------------------------------------------- |
| `threshold`   | candidate centroid distance                   |
| `int_min_val` | minimum distance                              |
| `int_min_id`  | internal centroid index with minimum distance |
| `cluster_id`  | final output cluster index                    |

Therefore:

```text
cluster_id = int_min_id
```

---

# 3. Input Signals

### `int_min_id`

The centroid index determined by the minimum-distance logic.

Range:

```text
0 ≤ int_min_id < K
```

Where `K` is the number of centroids.

---

# 4. Output Signal

### `cluster_id`

Type typically:

```vhdl
signal cluster_id : natural range 0 to K-1;
```

or

```vhdl
signal cluster_id : std_logic_vector(ID_WIDTH-1 downto 0);
```

depending on system interface requirements.

---

# 5. Functional Behavior

## Step 1 — Receive Winning Centroid Index

The minimum-distance decision logic determines:

```
int_min_id
```

This identifies which centroid produced the minimum distance.

---

## Step 2 — Assign Output Cluster ID

The output signal becomes:

```text
cluster_id = int_min_id
```

---

## Step 3 — Forward to Output Stages

The cluster ID is used by:

1. **Centroid Output MUX**
2. **Cluster map output**
3. **debug monitoring**
4. **classification logic**

---

# 6. Mathematical Definition

Let:

```
D(i) = distance(pixel, centroid_i)
```

Then:

```
cluster_id = argmin(D(i))
```

Where:

```
i = 0 .. K-1
```

---

# 7. Example Operation

Assume centroid distances:

```
D0 = 30
D1 = 270
D2 = 9
D3 = 44
D4 = 18
```

Minimum:

```
Dmin = 9
```

Centroid index:

```
cluster_id = 2
```

Therefore pixel belongs to **cluster 2**.

---

# 8. Use in Output Pixel Generation

The cluster ID selects the centroid color:

```
pixel_out_rgb = centroid_lut(cluster_id)
```

Example:

```
cluster_id = 2
centroid_lut(2) = (105,122,138)
```

Output pixel becomes:

```
pixel_out_rgb = (105,122,138)
```

---

# 9. Optional Segmentation Output

Some systems output the cluster ID separately to produce a segmentation map.

Example output:

```
cluster_id_stream
```

Image representation:

| Pixel | Cluster |
| ----- | ------- |
| P0    | 2       |
| P1    | 0       |
| P2    | 3       |
| P3    | 2       |

This can be visualized as region segmentation.

---

# 10. Data Width

Cluster ID width depends on centroid count.

| Centroids | Bits Required |
| --------- | ------------- |
| 2         | 1             |
| 4         | 2             |
| 8         | 3             |
| 16        | 4             |
| 32        | 5             |

Example:

If:

```
K = 5
```

then:

```
cluster_id width = 3 bits
```

---

# 11. Timing Behavior

Cluster ID must be **cycle-aligned with the clustered pixel output**.

If pipeline latency is `L` cycles:

```
pixel_in_rgb @ t0
cluster_id   @ t0 + L
pixel_out_rgb @ t0 + L
```

Cluster ID and output RGB must refer to the **same pixel**.

---

# 12. Pipeline Alignment

Cluster ID must travel through the same pipeline stages as:

* output centroid RGB
* metadata signals

Typical pipeline:

```
Distance Engine
      │
Comparator Tree
      │
int_min_id
      │
Cluster ID Register
      │
Centroid Output MUX
```

---

# 13. Reset Behavior

On reset:

```
cluster_id = 0
```

This ensures a defined state before valid pixels arrive.

Reset does not affect final clustering results because the signal will be overwritten during processing.

---

# 14. Hardware Implementation

The cluster ID output is typically implemented as a **registered signal**.

Example conceptual behavior:

```vhdl
if rising_edge(clk) then
    cluster_id <= int_min_id;
end if;
```

This ensures stable timing for downstream logic.

---

# 15. Role in the Clustering Pipeline

Pipeline overview:

```
Pixel Input
     │
Distance Computation
     │
Minimum Distance Logic
     │
int_min_id
     │
Cluster ID Output
     │
Centroid Output MUX
     │
Clustered Pixel Output
```

Cluster ID is the **decision result** of the clustering engine.

---

# 16. Design Intent

The cluster ID output allows the clustering engine to:

* identify the nearest centroid
* map pixels to cluster colors
* expose classification information
* support segmentation and debug outputs

It provides the **symbolic label of the cluster assignment**.

---

# 17. Advantages

* simple implementation
* minimal hardware cost
* enables debug visibility
* supports segmentation map generation
* directly drives centroid color selection

---

# 18. Limitations

* cluster meaning depends entirely on centroid values
* cluster numbering has no inherent semantic meaning unless defined externally
* incorrect centroid programming leads to incorrect cluster IDs

---

# 19. Recommended Naming

Better descriptive names:

| Current      | Recommended              |
| ------------ | ------------------------ |
| `cluster_id` | `winning_centroid_index` |
| `cluster_id` | `cluster_index`          |
| `cluster_id` | `best_cluster_id`        |

Recommended engineering name:

```
cluster_index
```

---

# 20. Document-Ready Functional Description

The Cluster ID Output represents the centroid index selected by the minimum-distance decision logic as the closest centroid to the current input pixel. This signal identifies the cluster assignment of the pixel and is used by the centroid output multiplexer to generate the final clustered RGB output. The cluster ID is also available for optional segmentation or debugging purposes.

---

# 21. Short Engineering Definition

The Cluster ID Output identifies which centroid is closest to the input pixel.

---

# 22. Summary

The Cluster ID Output:

* carries the index of the winning centroid
* originates from `int_min_id`
* drives centroid color selection
* may also be exported as segmentation data
* must remain aligned with clustered pixel output

---

If you want, I can next generate the **complete Architecture Specification of the entire RGB K-Means Clustering Engine** (system-level block diagram description + module interactions).
