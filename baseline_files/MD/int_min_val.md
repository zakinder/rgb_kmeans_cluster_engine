## Functional Specification: **`int_min_val`**

### Signal Name

`int_min_val`

### Signal Type

Typically:

```vhdl
signal int_min_val : integer;
```

### Module Context

Used inside:

* `rgb_kmeans_cluster_engine`
* Comparator Tree / Minimum Distance Selector

### Purpose

`int_min_val` stores the **current minimum distance value** while comparing multiple centroid distances.

It acts as a **temporary register** that keeps track of the smallest distance encountered during the comparison process.

This value represents the **closest centroid distance** found so far.

---

# 1. Functional Objective

During centroid comparison, multiple distance values are generated:

```text
D0, D1, D2, ..., DK-1
```

The goal is to determine:

```text
Dmin = min(D0, D1, D2, ..., DK-1)
```

`int_min_val` holds the **intermediate or final minimum value** during this search.

---

# 2. Role in Clustering Algorithm

The clustering algorithm must determine which centroid is closest to the input pixel.

To do this:

1. Initialize the minimum distance
2. Compare each candidate distance
3. Update the minimum when a smaller distance is found
4. Store the final minimum

`int_min_val` is the variable used to hold this minimum distance.

---

# 3. Functional Behavior

## Step 1 — Initialization

At the start of comparison:

```text
int_min_val = D0
```

The first distance becomes the initial reference.

---

## Step 2 — Iterative Comparison

For each new centroid distance `Di`:

```text
if Di < int_min_val then
    int_min_val = Di
end if
```

This ensures that `int_min_val` always holds the smallest distance seen so far.

---

## Step 3 — Final Result

After all centroid distances have been checked:

```text
int_min_val = minimum distance
```

This value corresponds to the closest centroid.

---

# 4. Mathematical Definition

Let:

```text
D(i) = distance between pixel and centroid i
```

Then:

```text
int_min_val = min(D(i))   for i = 0..K-1
```

---

# 5. Example Operation

Assume distance values:

```text
D0 = 30
D1 = 270
D2 = 9
D3 = 44
D4 = 18
```

Comparison sequence:

| Step       | Distance | Current `int_min_val` |
| ---------- | -------- | --------------------- |
| Initialize | D0=30    | 30                    |
| Compare D1 | 270      | 30                    |
| Compare D2 | 9        | 9                     |
| Compare D3 | 44       | 9                     |
| Compare D4 | 18       | 9                     |

Final result:

```text
int_min_val = 9
```

---

# 6. Hardware Representation

`int_min_val` is implemented as a **register** that stores the minimum value.

Example conceptual hardware:

```text
Distance Input -----
                    | comparator |
int_min_val --------|            |---- new_min
```

The comparator checks whether a new candidate distance is smaller.

If true, the register updates.

---

# 7. Typical VHDL Behavior

Conceptual logic:

```vhdl
if candidate_distance < int_min_val then
    int_min_val <= candidate_distance;
end if;
```

This is executed for each centroid comparison.

---

# 8. Reset Behavior

When reset is asserted:

```text
int_min_val = 0
```

or sometimes:

```text
int_min_val = MAX_DISTANCE
```

Using the maximum possible distance ensures the first comparison always replaces it.

Example maximum Manhattan distance:

```text
255 + 255 + 255 = 765
```

---

# 9. Data Range

For 8-bit RGB Manhattan distance:

```text
0 ≤ int_min_val ≤ 765
```

Thus integer storage is sufficient.

---

# 10. Relationship to Other Signals

| Signal          | Relationship                                           |
| --------------- | ------------------------------------------------------ |
| `threshold`     | candidate distance values                              |
| `best_cluster`  | index of centroid producing `int_min_val`              |
| comparator tree | logic updating `int_min_val`                           |
| centroid LUT    | source of centroid values used in distance computation |

---

# 11. Timing Behavior

### Synchronous Update

`int_min_val` is typically updated on the rising edge of the clock:

```vhdl
if rising_edge(clk) then
    int_min_val <= new_min_val;
end if;
```

This ensures stable pipeline operation.

---

# 12. Pipeline Usage

In pipelined comparator trees, `int_min_val` may exist at multiple stages:

```text
stage1_min
stage2_min
stage3_min
```

Each stage reduces candidate distances until the final minimum is produced.

---

# 13. Design Intent

The purpose of `int_min_val` is to:

* track the smallest centroid distance
* support deterministic nearest-centroid selection
* simplify comparator logic
* provide a stable reference for cluster decision

---

# 14. Advantages

* simple implementation
* minimal hardware resources
* deterministic behavior
* easy to pipeline
* efficient FPGA mapping

---

# 15. Limitations

* requires sequential comparisons if not implemented as a tree
* must be synchronized with centroid index tracking
* incorrect initialization can cause incorrect cluster selection

---

# 16. Recommended Naming

More descriptive alternatives:

| Current Name  | Alternative            |
| ------------- | ---------------------- |
| `int_min_val` | `min_distance`         |
| `int_min_val` | `best_distance`        |
| `int_min_val` | `cluster_distance_min` |

Recommended:

```text
min_distance
```

because it directly reflects the signal's function.

---

# 17. Document-Ready Functional Description

`int_min_val` is an internal signal used during centroid distance comparison to store the smallest distance value encountered while evaluating candidate centroid distances. It is updated whenever a newly computed distance is smaller than the current stored value. After all centroid distances have been compared, `int_min_val` represents the minimum pixel-to-centroid distance and is used to determine the closest centroid for cluster assignment.

---

# 18. Short Engineering Definition

`int_min_val` stores the current minimum distance during centroid comparison.

---

# 19. Summary

`int_min_val`:

* stores the smallest centroid distance
* updates whenever a smaller distance is found
* supports nearest-centroid selection
* is part of the minimum distance comparison logic
* determines the winning cluster

---

If you want, I can also generate **Functional Specifications: `int_min_id` (cluster index tracker)**, which usually works together with `int_min_val` in clustering engines.
