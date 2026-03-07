## Functional Specification: **Comparator Tree / Minimum Distance Selector**

### Module Context

Used inside:

* `rgb_kmeans_cluster_engine`

Consumes outputs from:

* `rgb_cluster_core`
* Distance Computation Units

### Purpose

The **Comparator Tree / Minimum Distance Selector** determines **which centroid is closest** to the current input pixel.

It receives multiple distance values, one for each centroid, compares them, and selects:

* the **minimum distance**
* the corresponding **winning centroid index**
* optionally the **winning centroid RGB value**

This block is the decision stage of the clustering pipeline.

---

# 1. Functional Objective

Given a set of distance values:

```text
D0, D1, D2, ..., DK-1
```

the selector computes:

```text
Dmin = min(D0, D1, D2, ..., DK-1)
```

and returns:

```text
best_cluster = argmin(Di)
```

This identifies the nearest centroid.

---

# 2. Inputs

### Distance Inputs

A set of threshold or distance values from the distance computation units.

Example:

```text
threshold_0
threshold_1
threshold_2
...
threshold_K-1
```

Each value corresponds to one centroid.

---

### Optional Associated Inputs

The selector may also track:

* centroid index for each distance
* centroid RGB value for each distance
* valid flag for current pixel

---

# 3. Outputs

### Minimum Distance

```text
min_threshold
```

The smallest distance among all candidate centroids.

### Winning Cluster Index

```text
best_cluster
```

The index of the centroid with the minimum distance.

### Optional Winning Centroid RGB

```text
best_centroid_rgb
```

Used to drive `pixel_out_rgb`.

---

# 4. Functional Behavior

## Step 1 — Receive Candidate Distances

The block receives K candidate distance values:

```text
D(0), D(1), D(2), ..., D(K-1)
```

---

## Step 2 — Compare Distances

Each candidate is compared against the current minimum.

Conceptually:

```text
if D(i) < current_min then
    current_min  = D(i)
    current_idx  = i
end if
```

---

## Step 3 — Track Winning Index

Whenever a smaller distance is found, the associated centroid index is also updated.

```text
best_cluster = index_of_smallest_distance
```

---

## Step 4 — Produce Final Selection

After all comparisons complete:

* `min_threshold` contains the smallest distance
* `best_cluster` contains the winning centroid index

This index is then used to select the output centroid RGB.

---

# 5. Mathematical Definition

Given:

```text
D(i), for i = 0 to K-1
```

Compute:

```text
Dmin = min(D(i))
```

and

```text
best_cluster = j such that D(j) = Dmin
```

---

# 6. Example Operation

Assume:

```text
D0 = 30
D1 = 270
D2 = 9
D3 = 44
D4 = 18
```

Comparison result:

```text
Dmin = 9
best_cluster = 2
```

This means centroid 2 is the closest centroid.

---

# 7. Tie-Breaking Behavior

If two or more distances are equal, the design must define a deterministic tie rule.

## Common Tie Rule

Select the **lowest centroid index**.

Example:

```text
D0 = 20
D1 = 20
D2 = 35
```

Then:

```text
best_cluster = 0
```

because index 0 appears first.

---

## Recommended Rule

Use strict less-than:

```vhdl
if D_new < D_best then
```

This preserves the first minimum encountered.

---

# 8. Hardware Architectures

## Option A — Sequential Minimum Search

Distances are compared one after another.

### Behavior

```text
min_val = D0
min_idx = 0

compare D1
compare D2
compare D3
...
```

### Advantages

* simple logic
* fewer comparators

### Disadvantages

* longer latency for large K

---

## Option B — Comparator Tree

Distances are compared in parallel stages.

Example for 4 centroids:

### Stage 1

```text
compare D0 vs D1 → winner A
compare D2 vs D3 → winner B
```

### Stage 2

```text
compare winner A vs winner B → final winner
```

### Advantages

* faster
* scalable for pipelined FPGA implementation

### Disadvantages

* more parallel logic

---

# 9. Comparator Tree Example

For 8 centroids:

## Stage 1

```text
(D0 vs D1)
(D2 vs D3)
(D4 vs D5)
(D6 vs D7)
```

## Stage 2

```text
(w01 vs w23)
(w45 vs w67)
```

## Stage 3

```text
(final_left vs final_right)
```

This produces the final minimum distance and index.

---

# 10. Datapath Structure

Each comparator stage must propagate both:

* distance value
* centroid index

because selecting the minimum distance without its index is not sufficient.

### Comparator Cell Function

Inputs:

* `dist_a`, `idx_a`
* `dist_b`, `idx_b`

Output:

* smaller of the two distances
* corresponding index

Conceptually:

```text
if dist_a <= dist_b then
    dist_out = dist_a
    idx_out  = idx_a
else
    dist_out = dist_b
    idx_out  = idx_b
end if
```

---

# 11. Optional RGB Propagation

Instead of propagating only the winning index, the tree may also propagate:

* centroid RGB value
* full centroid record

Then the final stage directly produces the selected centroid color.

This reduces the need for a later LUT lookup, at the cost of wider comparator datapaths.

---

# 12. Timing Behavior

## Synchronous Design

Comparator tree outputs are often registered on the rising edge of `clk`.

### Example

```vhdl
if rising_edge(clk) then
    best_cluster  <= selected_idx;
    min_threshold <= selected_dist;
end if;
```

---

## Pipeline Stages

For high-speed designs, each comparator level may be registered.

Example:

* Stage 1 register
* Stage 2 register
* Final register

This improves timing closure for large centroid counts.

---

# 13. Throughput Behavior

In a pipelined implementation, the selector can support:

```text
1 pixel result per clock cycle
```

after the initial latency fills.

This is important for real-time video processing.

---

# 14. Resource Usage

For `K` centroids, the minimum selector typically requires:

* `K-1` comparator units
* index propagation logic
* optional pipeline registers

### Example

For 5 centroids:

* 4 logical comparisons minimum

### Example

For 8 centroids:

* 7 comparator cells

---

# 15. Design Constraints

### Valid Distance Inputs

All candidate distance values must be valid and aligned to the same pixel.

### Index Range

Winning index must remain within:

```text
0 to K-1
```

### Pipeline Alignment

If distances are pipelined, the corresponding centroid indices must be pipelined identically.

---

# 16. Role in the Clustering Pipeline

The comparator tree sits between:

* distance computation
* output centroid selection

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
Winning Centroid Index
    │
    ▼
Centroid Output MUX
    │
    ▼
Clustered Pixel Output
```

---

# 17. Design Intent

The Comparator Tree / Minimum Distance Selector is designed to:

* efficiently determine the closest centroid
* preserve deterministic behavior
* scale with centroid count
* support pipelined FPGA architectures

It converts multiple candidate distances into one clustering decision.

---

# 18. Advantages

* deterministic nearest-centroid selection
* scalable with K
* efficient FPGA mapping
* easy to pipeline
* supports one-pixel-per-cycle processing

---

# 19. Limitations

* resource usage grows with centroid count
* tree depth grows with K
* all distances must be available and aligned
* tie behavior must be explicitly defined

---

# 20. Document-Ready Functional Description

The Comparator Tree / Minimum Distance Selector receives the set of color-distance values computed for the current input pixel and all active centroids. It compares these candidate distances, determines the minimum value, and outputs the index of the centroid associated with that minimum distance. This block forms the decision stage of the clustering engine and enables deterministic nearest-centroid assignment for each pixel.

---

# 21. Short Engineering Definition

The Comparator Tree / Minimum Distance Selector chooses the centroid with the smallest computed pixel-to-centroid distance.

---

# 22. Summary

The Comparator Tree / Minimum Distance Selector:

* receives K distance values
* compares all candidate distances
* selects the minimum
* outputs the winning centroid index
* drives final centroid selection for clustered output

The next logical section is **Functional Specification: Centroid Output MUX / Clustered Pixel Generator**.
