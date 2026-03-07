## Functional Specification: `centroid_lut_select`

### Signal Name

`centroid_lut_select`

### Module Context

Used in: `rgb_kmeans_cluster_engine`

### Purpose

`centroid_lut_select` selects **which centroid entry** in the centroid lookup table (LUT) is being addressed for update or access.

It acts as the **centroid index selector** for the clustering engine.

---

## Functional Role

The clustering engine stores multiple centroid RGB values, one for each cluster.
`centroid_lut_select` identifies **one centroid slot** among those stored entries.

Typical use:

* choose which centroid to **write**
* choose which centroid to **configure**
* choose which centroid is currently targeted by control logic

---

## Direction

**Input**

```vhdl
centroid_lut_select : in natural
```

In the portable version it is more safely constrained as:

```vhdl
centroid_lut_select : in natural range 0 to cluster_count-1
```

---

## Functional Behavior

### 1. Centroid Write Selection

When new centroid RGB data is presented on `centroid_lut_in`, `centroid_lut_select` identifies the destination LUT entry.

Example:

* `centroid_lut_select = 0` → update centroid 0
* `centroid_lut_select = 1` → update centroid 1
* `centroid_lut_select = 4` → update centroid 4

---

### 2. Configuration Indexing

During centroid initialization or runtime centroid updates, this signal allows external control logic to configure one centroid at a time.

This is useful for:

* loading initial cluster centers
* adaptive centroid update
* software-controlled centroid programming

---

### 3. Controlled Interaction with `k_ind_w`

In your current portable architecture, centroid write occurs only when:

```vhdl
if k_ind_w = centroid_lut_select then
```

So `centroid_lut_select` works together with `k_ind_w` as a write-address qualification mechanism.

This means:

* `centroid_lut_select` chooses the target centroid
* `k_ind_w` confirms the active write index

---

## Related Signals

### `centroid_lut_in`

Carries the RGB value to be written into the selected centroid entry.

Typical format:

```vhdl
centroid_lut_in(23 downto 16) -> Red
centroid_lut_in(15 downto 8)  -> Green
centroid_lut_in(7 downto 0)   -> Blue
```

### `k_ind_w`

Write-side centroid index control.

### `k_ind_r`

Read-side centroid index control.

### `centroid_lut_out`

Returns the centroid value from the selected read path, typically using `k_ind_r`.

---

## Valid Range

If cluster count is `N`, valid values are:

```vhdl
0 to N-1
```

For example, with 5 clusters:

```vhdl
0 to 4
```

Any value outside this range should be prevented by type constraint or control logic.

---

## Timing Behavior

### Clock Domain

`centroid_lut_select` is sampled on the **rising edge of `clk`** when write logic is active.

### Reset Behavior

During `rst_n = '0'`, centroid memory is cleared, and `centroid_lut_select` has no functional effect until normal operation resumes.

---

## Operational Use Cases

### Use Case 1: Initial Centroid Loading

A controller writes centroid values one by one:

* set `centroid_lut_select = 0`, load centroid 0
* set `centroid_lut_select = 1`, load centroid 1
* continue until all centroids are loaded

### Use Case 2: Runtime Centroid Update

A training or adaptation block updates a specific centroid based on new image statistics.

### Use Case 3: Cluster Reconfiguration

System software changes centroid definitions for a new color segmentation profile.

---

## Design Intent

`centroid_lut_select` provides a simple and deterministic way to access a specific centroid in a multi-centroid memory structure without broadcasting updates to all entries.

This improves:

* configurability
* modularity
* scalability for larger `K`

---

## Recommended Stronger Definition

Instead of:

```vhdl
centroid_lut_select : in natural;
```

use:

```vhdl
centroid_lut_select : in natural range 0 to cluster_count-1;
```

This gives:

* safer synthesis behavior
* clearer interface intent
* prevention of invalid centroid index values

---

## Example Functional Description for Document

You can place this directly in your design document:

`centroid_lut_select` is the centroid address selection input of the K-means clustering engine. It identifies which centroid LUT entry is targeted during centroid configuration or update operations. The signal is used in conjunction with centroid write data (`centroid_lut_in`) and write index control (`k_ind_w`) to load RGB centroid values into the selected cluster slot. Its valid range is from `0` to `cluster_count-1`.

---

## Short Engineering Definition

`centroid_lut_select` = **centroid LUT address select**

---

## Recommended Rename

For even better clarity, you may rename it to:

* `centroid_index_sel`
* `centroid_addr`
* `centroid_write_select`

Best choice:

```vhdl
centroid_index_sel
```

because it clearly conveys index-based centroid selection.

I can also write the same level of functional specification for `centroid_lut_in`, `centroid_lut_out`, `k_ind_w`, and `k_ind_r`.
