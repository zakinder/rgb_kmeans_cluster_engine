# Centroid LUT Design — RGB K-Means Cluster Engine

**Designer Name:** Sakinder Ali  
**Module:** `rgb_kmeans_cluster_engine`

---

## 1. Purpose

The Centroid LUT stores RGB centroid values used by the clustering engine. Each centroid represents a target color class. During processing, every input pixel is compared against these centroid values, and the nearest centroid is selected as the clustered output color.

---

## 2. Centroid Entry Format

Each centroid entry contains three color components:

```text
centroid[i] = (red, green, blue)
```

For 8-bit RGB operation:

```text
red   : 8 bits
green : 8 bits
blue  : 8 bits
```

Packed representation:

```text
centroid_lut_in[23:16] = red
centroid_lut_in[15:8]  = green
centroid_lut_in[7:0]   = blue
```

---

## 3. LUT Responsibilities

The centroid LUT must:

1. Store the active centroid RGB values.
2. Provide centroid values to the distance-computation unit.
3. Support write access for centroid updates.
4. Support readback access for debug, validation, or software control.
5. Support profile or table selection where multiple centroid sets are available.

---

## 4. Logical Structure

```text
+---------------------------+
| Centroid LUT              |
|---------------------------|
| index 0  -> (R0, G0, B0)  |
| index 1  -> (R1, G1, B1)  |
| index 2  -> (R2, G2, B2)  |
| ...                       |
| index K-1 -> (RK, GK, BK) |
+---------------------------+
```

---

## 5. Write Interface

Centroid write operations use:

- `centroid_lut_in`
- `k_ind_w`
- `centroid_lut_select`

Recommended write behavior:

```text
centroid_table[k_ind_w] <= centroid_lut_in[23:0]
```

A production design should include an explicit write-enable signal to prevent unintended updates.

---

## 6. Readback Interface

Centroid readback operations use:

- `k_ind_r`
- `centroid_lut_out`

Recommended read behavior:

```text
centroid_lut_out[23:0] <= centroid_table[k_ind_r]
centroid_lut_out[31:24] <= 0
```

Readback is important for:

- validating programmed centroids
- debugging runtime behavior
- software-visible inspection
- verification testbench checking

---

## 7. Storage Implementation Options

| Implementation | Use Case |
|---|---|
| VHDL constants | Fixed palettes or static centroid profiles. |
| Register array | Small programmable centroid tables. |
| Distributed RAM | Medium centroid tables with FPGA LUTRAM. |
| Block RAM | Larger centroid banks or multiple profiles. |
| Shadow buffer | Safe runtime update without corrupting active stream classification. |

---

## 8. Profile Selection

`centroid_lut_select` can be used to choose among multiple centroid profiles.

Example:

```text
centroid_lut_select = 0 -> grayscale profile
centroid_lut_select = 1 -> skin-tone profile
centroid_lut_select = 2 -> warm-color profile
centroid_lut_select = 3 -> application-specific profile
```

This allows the same clustering engine to operate under different color-classification modes.

---

## 9. Runtime Update Safety

Direct centroid updates during active streaming can cause partial classification artifacts if some pixels use old centroid values and later pixels use partially updated values.

Recommended safe update method:

1. Write new centroid values into a shadow table.
2. Verify shadow table contents using readback.
3. Wait for a frame boundary.
4. Atomically switch the active centroid table.

This prevents mixed-profile artifacts inside a live frame.

---

## 10. Verification Requirements

Centroid LUT verification should confirm:

- reset/default centroid contents
- correct write by index
- correct readback by index
- invalid index protection
- profile-selection behavior
- stable centroid values during active classification
- shadow-buffer activation if implemented

---

## 11. Summary

The Centroid LUT is the color-reference memory of the RGB K-Means Cluster Engine. Its correctness directly determines classification accuracy, output color stability, and runtime configurability.
