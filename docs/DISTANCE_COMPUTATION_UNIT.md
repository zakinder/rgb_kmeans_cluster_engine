# Distance Computation Unit — RGB Distance Engine

**Designer Name:** Sakinder Ali  
**Module Context:** `rgb_kmeans_cluster_engine`

---

## 1. Purpose

The Distance Computation Unit calculates the numerical separation between an input RGB pixel and each stored centroid. The resulting distance values are passed to the minimum-distance selector, which determines the winning centroid.

---

## 2. Input Values

Input pixel:

```text
P = (R, G, B)
```

Centroid value:

```text
C(i) = (Ri, Gi, Bi)
```

---

## 3. Preferred Metric: Manhattan Distance

The recommended distance metric is:

```text
D(i) = |R - Ri| + |G - Gi| + |B - Bi|
```

This metric is efficient for FPGA implementation because it uses:

- subtractors
- absolute-value logic
- adders
- registers

It does not require multipliers or square-root computation.

---

## 4. Hardware Breakdown

For each centroid:

```text
red_delta   = abs(pixel_red   - centroid_red)
green_delta = abs(pixel_green - centroid_green)
blue_delta  = abs(pixel_blue  - centroid_blue)

distance = red_delta + green_delta + blue_delta
```

---

## 5. Parallel Distance Computation

For maximum throughput, the design can instantiate one distance engine per centroid:

```text
P -> Distance Engine 0 -> D0
P -> Distance Engine 1 -> D1
P -> Distance Engine 2 -> D2
...
P -> Distance Engine K-1 -> D(K-1)
```

This supports one-pixel-per-clock throughput but uses more FPGA logic.

---

## 6. Time-Multiplexed Distance Computation

For lower area usage, a smaller number of distance engines may be reused across centroid entries.

Advantages:

- lower LUT/register usage
- reduced comparator fan-in

Disadvantages:

- lower throughput
- additional control state
- more complex timing alignment

---

## 7. Distance Width

For 8-bit RGB channels:

```text
max_delta_per_channel = 255
max_distance = 255 + 255 + 255 = 765
```

Therefore, the Manhattan distance requires at least 10 bits:

```text
ceil(log2(766)) = 10 bits
```

A practical implementation may use 10, 11, 12, or wider internal signals for safety and synthesis clarity.

---

## 8. Optional Euclidean Distance

A Euclidean-style metric may be used if higher mathematical accuracy is required:

```text
D(i) = sqrt((R - Ri)^2 + (G - Gi)^2 + (B - Bi)^2)
```

However, this requires additional hardware:

- multipliers or DSP blocks
- wider accumulators
- optional square-root unit
- deeper pipeline stages

For real-time FPGA clustering, Manhattan distance is usually the better first implementation.

---

## 9. Pipeline Considerations

The distance engine may be pipelined as:

| Stage | Function |
|---:|---|
| 0 | Register pixel and centroid values. |
| 1 | Compute channel differences. |
| 2 | Convert to absolute values. |
| 3 | Add channel deltas. |
| 4 | Register final distance. |

Pipeline depth should be documented and matched in the metadata path.

---

## 10. Verification Requirements

The distance unit should be verified using:

- exact-match case where distance is zero
- maximum-distance case
- single-channel difference cases
- mixed RGB difference cases
- random pixel/centroid comparisons against a software reference model
- signed/unsigned subtraction edge cases

---

## 11. Summary

The Distance Computation Unit converts RGB color difference into a numeric distance value. It is the arithmetic core of the clustering engine and directly affects resource usage, clock frequency, and classification behavior.
