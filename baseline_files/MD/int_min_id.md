## Functional Specification: **`int_min_id`**

### Signal Name

`int_min_id`

### Signal Type

Typically:

```vhdl
signal int_min_id : integer;
```

or more safely:

```vhdl
signal int_min_id : natural;
```

### Module Context

Used inside:

* `rgb_kmeans_cluster_engine`
* Comparator Tree / Minimum Distance Selector

### Purpose

`int_min_id` stores the **index of the centroid** associated with the current minimum distance.

It works together with:

* `int_min_val` → minimum distance value
* `int_min_id` → centroid index that produced that minimum

This signal identifies **which cluster won** the comparison.

---

# 1. Functional Objective

Given candidate centroid distances:

```text
D0, D1, D2, ..., DK-1
```

the system finds:

```text
Dmin = min(D0, D1, D2, ..., DK-1)
```

and must also determine:

```text
best_cluster = j such that D(j) = Dmin
```

`int_min_id` stores this `j`.

---

# 2. Role in Clustering Algorithm

The clustering engine does not only need the minimum distance value.
It also needs to know **which centroid produced that distance**.

That winning index is later used to:

* select the output centroid RGB value
* read the correct LUT entry
* optionally output cluster ID for debug/segmentation

`int_min_id` is the internal signal that tracks this winning centroid index.

---

# 3. Functional Behavior

## Step 1 — Initialization

At the start of comparison:

```text
int_min_val = D0
int_min_id  = 0
```

The first centroid becomes the initial best candidate.

---

## Step 2 — Compare Each Candidate

For each new centroid distance `Di` at index `i`:

```text
if Di < int_min_val then
    int_min_val = Di
    int_min_id  = i
end if
```

This ensures:

* `int_min_val` always holds the smallest distance seen so far
* `int_min_id` always holds the centroid index associated with that distance

---

## Step 3 — Final Result

After all centroid comparisons are complete:

```text
int_min_val = minimum distance
int_min_id  = winning centroid index
```

---

# 4. Mathematical Definition

Let:

```text
D(i) = distance between input pixel and centroid i
```

Then:

```text
int_min_val = min(D(i))
int_min_id  = argmin(D(i))
```

where:

```text
i = 0 .. K-1
```

---

# 5. Example Operation

Assume:

```text
D0 = 30
D1 = 270
D2 = 9
D3 = 44
D4 = 18
```

Comparison flow:

| Step       | Candidate | `int_min_val` | `int_min_id` |
| ---------- | --------: | ------------: | -----------: |
| init       |   D0 = 30 |            30 |            0 |
| compare D1 |       270 |            30 |            0 |
| compare D2 |         9 |             9 |            2 |
| compare D3 |        44 |             9 |            2 |
| compare D4 |        18 |             9 |            2 |

Final result:

```text
int_min_val = 9
int_min_id  = 2
```

This means centroid 2 is the closest centroid.

---

# 6. Tie-Breaking Behavior

If two centroids produce the same distance, the design must define deterministic behavior.

## Common Rule

Keep the **first minimum encountered**.

That means use:

```vhdl
if candidate_distance < int_min_val then
```

not:

```vhdl
if candidate_distance <= int_min_val then
```

### Result

If:

```text
D0 = 20
D1 = 20
D2 = 35
```

then:

```text
int_min_id = 0
```

because centroid 0 reached the minimum first.

---

# 7. Hardware Representation

`int_min_id` is typically stored in a register alongside `int_min_val`.

Conceptual comparator cell:

Inputs:

* current minimum distance and index
* candidate distance and candidate index

Output:

* updated minimum distance and index

Behavior:

```text
if candidate_dist < current_min_dist then
    next_min_dist = candidate_dist
    next_min_id   = candidate_idx
else
    next_min_dist = current_min_dist
    next_min_id   = current_min_id
end if
```

---

# 8. Typical VHDL Behavior

Conceptual logic:

```vhdl
if candidate_distance < int_min_val then
    int_min_val <= candidate_distance;
    int_min_id  <= candidate_index;
end if;
```

This keeps the value and index synchronized.

---

# 9. Reset Behavior

When reset is asserted, `int_min_id` is initialized to a safe default.

Typical reset:

```text
int_min_id = 0
```

This is safe because:

* it is in-range
* it gives deterministic startup behavior

However, reset alone does not define the final winner; the comparison logic must overwrite it during valid operation.

---

# 10. Range and Width

If there are `K` centroids, valid values are:

```text
0 ≤ int_min_id < K
```

### Example

For 5 centroids:

```text
0 ≤ int_min_id ≤ 4
```

A constrained type is better than plain integer:

```vhdl
signal int_min_id : natural range 0 to K-1;
```

This improves:

* readability
* synthesis safety
* documentation clarity

---

# 11. Relationship to Other Signals

| Signal          | Relationship                                          |
| --------------- | ----------------------------------------------------- |
| `int_min_val`   | minimum distance associated with this index           |
| `threshold`     | candidate distances being compared                    |
| `best_cluster`  | external/output form of `int_min_id`                  |
| centroid LUT    | `int_min_id` selects the winning centroid entry       |
| `pixel_out_rgb` | output color is derived from centroid at `int_min_id` |

---

# 12. Timing Behavior

### Synchronous Update

`int_min_id` is typically updated on the clock edge together with `int_min_val`.

Example:

```vhdl
if rising_edge(clk) then
    int_min_val <= next_min_val;
    int_min_id  <= next_min_id;
end if;
```

This ensures both signals stay aligned for the same pixel.

---

# 13. Pipeline Usage

In pipelined comparator trees, each stage propagates:

* minimum distance
* corresponding centroid index

So intermediate signals may exist such as:

```text
stage1_min_val, stage1_min_id
stage2_min_val, stage2_min_id
stage3_min_val, stage3_min_id
```

At the final stage:

```text
int_min_val = final minimum distance
int_min_id  = final winning centroid index
```

---

# 14. Design Intent

`int_min_id` exists to preserve the identity of the winning centroid while distances are being reduced.

Without it, the design could know the minimum distance but not which centroid produced it.

This signal enables:

* centroid output selection
* clustered RGB generation
* debug visibility
* cluster labeling

---

# 15. Advantages

* simple logic
* deterministic nearest-centroid tracking
* easy to pipeline with distance comparator stages
* directly usable for LUT addressing
* essential for final output selection

---

# 16. Limitations

* must always stay synchronized with `int_min_val`
* incorrect tie handling can change cluster assignment
* unconstrained integer typing may allow invalid values unless guarded

---

# 17. Recommended Naming

More descriptive alternatives:

| Current Name | Alternative              |
| ------------ | ------------------------ |
| `int_min_id` | `best_cluster_id`        |
| `int_min_id` | `min_distance_index`     |
| `int_min_id` | `winning_centroid_index` |

Recommended:

```text
winning_centroid_index
```

or, if shorter naming is preferred:

```text
best_cluster_id
```

---

# 18. Document-Ready Functional Description

`int_min_id` is an internal signal used during centroid comparison to store the index of the centroid associated with the current minimum distance. Whenever a candidate centroid distance is found to be smaller than the currently stored minimum distance, `int_min_id` is updated with that centroid’s index. After all centroid distances have been compared, `int_min_id` identifies the winning centroid used for clustered pixel generation.

---

# 19. Short Engineering Definition

`int_min_id` stores the index of the centroid with the current minimum distance.

---

# 20. Summary

`int_min_id`:

* tracks which centroid currently has the smallest distance
* updates when a smaller candidate distance is found
* works with `int_min_val`
* identifies the winning cluster
* drives final centroid selection for output mapping

The next logical signal to specify is often `threshold` vs `int_min_val` interaction, or a combined section called **Minimum-Distance Decision Logic**.
