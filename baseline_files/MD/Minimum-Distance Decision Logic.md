## Functional Specification: **Minimum-Distance Decision Logic**

### Module Context

Used inside:

* `rgb_kmeans_cluster_engine`
* Comparator Tree / Minimum Distance Selector

### Related Signals

* `threshold`
* `int_min_val`
* `int_min_id`

### Purpose

The **Minimum-Distance Decision Logic** determines whether a newly computed centroid distance is better than the current best distance.

It is the decision mechanism that updates:

* the current minimum distance value
* the corresponding centroid index

This logic is the core of nearest-centroid selection.

---

# 1. Functional Objective

For each candidate centroid distance:

```text
threshold(i)
```

the logic compares it against the currently stored best distance:

```text
int_min_val
```

If the new candidate is smaller, the logic updates:

* `int_min_val`
* `int_min_id`

Otherwise, the current minimum is preserved.

---

# 2. Input Signals

## `threshold`

The current candidate pixel-to-centroid distance.

This value comes from the distance computation unit for centroid `i`.

## `int_min_val`

The current smallest distance found so far.

## `int_min_id`

The centroid index associated with `int_min_val`.

## `candidate_index`

The centroid index corresponding to the current `threshold`.

This may be an explicit signal or loop index.

---

# 3. Output Signals

## Updated `int_min_val`

Holds the smaller of:

* current minimum distance
* new candidate distance

## Updated `int_min_id`

Holds the centroid index corresponding to the selected minimum distance.

---

# 4. Core Functional Rule

For each candidate centroid:

```text
if threshold < int_min_val then
    int_min_val = threshold
    int_min_id  = candidate_index
else
    int_min_val = int_min_val
    int_min_id  = int_min_id
end if
```

This is the essential nearest-centroid decision rule.

---

# 5. Functional Meaning of Each Signal

## `threshold`

Represents the distance between the current input pixel and one centroid.

## `int_min_val`

Represents the best distance found so far.

## `int_min_id`

Represents the centroid index that produced the best distance found so far.

Together they define the current clustering winner.

---

# 6. Decision Flow

## Step 1 — Initialize Best Candidate

At the beginning of the comparison sequence:

```text
int_min_val = threshold(0)
int_min_id  = 0
```

or equivalently initialize to a maximum value and replace on first valid comparison.

---

## Step 2 — Compare New Candidate

For centroid `i`:

```text
threshold = distance(pixel, centroid_i)
```

Compare:

```text
threshold < int_min_val
```

---

## Step 3 — Update if Better

If true:

```text
int_min_val = threshold
int_min_id  = i
```

If false:

* keep existing minimum
* keep existing centroid index

---

## Step 4 — Final Result

After all centroid distances are tested:

```text
int_min_val = minimum distance
int_min_id  = winning centroid index
```

---

# 7. Mathematical Definition

Let:

```text
D(i) = distance between input pixel and centroid i
```

Then the decision logic computes:

```text
int_min_val = min(D(i))
int_min_id  = argmin(D(i))
```

for:

```text
i = 0 to K-1
```

---

# 8. Example Operation

Assume candidate distances arrive in sequence:

```text
D0 = 30
D1 = 270
D2 = 9
D3 = 44
D4 = 18
```

### Initialization

```text
int_min_val = 30
int_min_id  = 0
```

### Compare D1

```text
270 < 30 ? no
```

State remains:

```text
int_min_val = 30
int_min_id  = 0
```

### Compare D2

```text
9 < 30 ? yes
```

Update:

```text
int_min_val = 9
int_min_id  = 2
```

### Compare D3

```text
44 < 9 ? no
```

### Compare D4

```text
18 < 9 ? no
```

Final result:

```text
int_min_val = 9
int_min_id  = 2
```

---

# 9. Tie-Breaking Rule

If:

```text
threshold = int_min_val
```

the logic must define whether to update or keep the existing result.

## Recommended Rule

Use strict comparison:

```text
if threshold < int_min_val
```

This keeps the first minimum encountered.

### Benefit

Deterministic cluster selection.

### Example

If:

```text
D0 = 20
D1 = 20
D2 = 35
```

Then:

```text
int_min_id = 0
```

because the first minimum is preserved.

---

# 10. Hardware Interpretation

The decision logic is implemented using:

* one comparator
* one value register path
* one index register path

Conceptually:

```text
threshold -----------\
                      comparator ---> update_enable
int_min_val --------/
```

If `update_enable = 1`:

* replace minimum distance
* replace centroid index

If `update_enable = 0`:

* hold current values

---

# 11. Datapath Behavior

The logic behaves like a paired compare-and-select unit:

Inputs:

* `(threshold, candidate_index)`
* `(int_min_val, int_min_id)`

Outputs:

* next minimum value
* next winning index

Conceptually:

```text
select smaller pair
```

This means value and index must always move together.

---

# 12. Synchronous Behavior

In a clocked FPGA implementation, updates usually occur on the rising edge:

```vhdl
if rising_edge(clk) then
    if threshold < int_min_val then
        int_min_val <= threshold;
        int_min_id  <= candidate_index;
    end if;
end if;
```

This ensures stable pipeline operation.

---

# 13. Pipeline Behavior

In pipelined architectures, the decision logic may be repeated across multiple stages.

Examples:

* sequential loop comparison
* comparator tree
* staged reduction pipeline

At each stage:

* minimum value is reduced
* associated index is preserved

---

# 14. Relationship Between `threshold` and `int_min_val`

## `threshold`

Current candidate distance.

## `int_min_val`

Best distance accumulated so far.

### Comparison Meaning

```text
threshold < int_min_val
```

means:

> “The newly tested centroid is closer than the previously best centroid.”

If true, the winner changes.

---

# 15. Relationship Between `threshold` and `int_min_id`

`threshold` alone is not enough.
Whenever `threshold` becomes the new minimum, the corresponding centroid index must also replace `int_min_id`.

This is critical because:

* `int_min_val` tells how good the match is
* `int_min_id` tells which centroid won

---

# 16. Reset and Initialization Behavior

On reset, common initialization choices are:

## Option A

```text
int_min_val = 0
int_min_id  = 0
```

## Option B

```text
int_min_val = MAX_DISTANCE
int_min_id  = 0
```

Recommended for comparison logic:

```text
int_min_val = MAX_DISTANCE
```

because the first valid threshold will always replace it.

For 8-bit RGB Manhattan distance:

```text
MAX_DISTANCE = 765
```

or slightly larger guard value if preferred.

---

# 17. Design Intent

The Minimum-Distance Decision Logic is designed to provide:

* deterministic nearest-centroid selection
* low-cost FPGA implementation
* synchronized value/index tracking
* compatibility with sequential or tree-based comparison architectures

It is the exact decision point where one centroid becomes better than another.

---

# 18. Advantages

* simple compare-and-update behavior
* small hardware footprint
* deterministic
* easy to pipeline
* directly supports LUT-based output mapping

---

# 19. Limitations

* must be carefully synchronized with centroid indices
* incorrect initialization can break selection
* tie behavior must be explicitly defined
* large K may need tree-based reduction for timing

---

# 20. Recommended Naming

| Current Name  | Better Name              |
| ------------- | ------------------------ |
| `threshold`   | `candidate_distance`     |
| `int_min_val` | `min_distance`           |
| `int_min_id`  | `winning_centroid_index` |

This makes the decision logic much clearer:

```text
if candidate_distance < min_distance then
    min_distance = candidate_distance
    winning_centroid_index = candidate_index
end if;
```

---

# 21. Document-Ready Functional Description

The Minimum-Distance Decision Logic compares each newly computed centroid distance against the current minimum stored distance. When a candidate distance is smaller than the current minimum, the logic updates both the stored minimum value and the associated centroid index. After all centroid distances have been evaluated, the logic outputs the minimum pixel-to-centroid distance and the index of the winning centroid, thereby determining the final cluster assignment for the current pixel.

---

# 22. Short Engineering Definition

The Minimum-Distance Decision Logic updates the best distance and winning centroid index whenever a smaller candidate distance is found.

---

# 23. Summary

This logic:

* receives a candidate `threshold`
* compares it against `int_min_val`
* updates `int_min_val` if the candidate is smaller
* updates `int_min_id` to keep the winning centroid aligned
* produces the final nearest-centroid decision

The next logical section is **Functional Specification: Cluster ID Output / Winning Centroid Index Output**.
