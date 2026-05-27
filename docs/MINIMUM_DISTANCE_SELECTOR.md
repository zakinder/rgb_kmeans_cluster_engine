# Minimum-Distance Selector — Comparator Tree

**Designer Name:** Sakinder Ali  
**Module Context:** `rgb_kmeans_cluster_engine`

---

## 1. Purpose

The Minimum-Distance Selector receives distance values from the RGB distance engines and selects the centroid with the smallest distance. This selected centroid is the winning color class for the current input pixel.

---

## 2. Inputs and Outputs

### Inputs

```text
distance[0]
distance[1]
distance[2]
...
distance[K-1]
```

### Outputs

```text
best_distance
best_cluster_id
```

The `best_cluster_id` is used by the output MUX to select the clustered RGB value.

---

## 3. Selection Rule

The selector implements:

```text
best_cluster_id = argmin(distance[i])
best_distance   = min(distance[i])
```

---

## 4. Tie-Breaking

For deterministic hardware behavior, equal distances should resolve to the lowest centroid index:

```text
if distance[a] = distance[b] and a < b:
    select a
```

This avoids frame-to-frame instability when a pixel lies equally between two centroid colors.

---

## 5. Comparator Chain Implementation

A simple implementation compares distances sequentially in logic:

```text
best_distance = distance[0]
best_id = 0

for i in 1 to K-1:
    if distance[i] < best_distance:
        best_distance = distance[i]
        best_id = i
```

This is simple but may create a long combinational path for large centroid counts.

---

## 6. Comparator Tree Implementation

A balanced comparator tree reduces logic depth:

```text
Level 0: compare pairs
Level 1: compare winners
Level 2: compare winners
...
Final: best distance and ID
```

Benefits:

- shorter combinational path
- better timing closure
- scalable to larger `K`
- easier pipelining between levels

---

## 7. Pipelined Comparator Tree

For high-speed designs, comparator-tree levels should be registered.

Example:

| Pipeline Level | Function |
|---:|---|
| 0 | Register incoming distances. |
| 1 | Pairwise comparisons. |
| 2 | Intermediate winner comparisons. |
| 3 | Final winner selection. |
| 4 | Register `best_cluster_id`. |

The metadata delay must be increased to match the comparator-tree latency.

---

## 8. Output Alignment

The selected `best_cluster_id` must remain aligned with:

- the input pixel that generated the distances
- the centroid RGB MUX stage
- the delayed metadata fields

Any mismatch will cause incorrect output colors or corrupted frame timing.

---

## 9. Verification Requirements

The selector should be verified using:

- minimum at index 0
- minimum at final index
- minimum in middle index
- all distances equal
- two-way tie
- randomized distance arrays
- maximum-value distances
- pipeline-latency alignment checks

---

## 10. Summary

The Minimum-Distance Selector is the decision block of the clustering engine. It converts the set of RGB distance measurements into a winning centroid index and must be deterministic, timing-safe, and aligned with the datapath pipeline.
