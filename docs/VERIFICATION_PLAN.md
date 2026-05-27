# Verification Plan — RGB K-Means Cluster Engine

**Designer Name:** Sakinder Ali  
**Module:** `rgb_kmeans_cluster_engine`

---

## 1. Purpose

This verification plan defines the tests required to validate the RGB K-Means Cluster Engine. The goal is to confirm that RGB clustering, centroid access, metadata alignment, reset behavior, and pipeline timing operate correctly.

---

## 2. Verification Objectives

The verification environment should prove that:

1. Each input pixel is assigned to the nearest centroid.
2. Distance calculations match the reference model.
3. The minimum-distance selector chooses the correct centroid index.
4. The output RGB value equals the winning centroid color.
5. Stream metadata remains aligned with the processed pixel.
6. Reset clears pipeline and output state correctly.
7. Centroid write and readback paths behave correctly.
8. Boundary and tie cases are deterministic.

---

## 3. Reference Model

The testbench should include a software-style reference model:

```text
for each centroid i:
    D(i) = abs(R - Ri) + abs(G - Gi) + abs(B - Bi)

expected_id  = index_of_min(D)
expected_rgb = centroid[expected_id]
```

The expected output should be compared against `pixel_out_rgb` after the documented pipeline latency.

---

## 4. Core Test Cases

| Test | Description | Expected Result |
|---|---|---|
| Reset test | Assert and release `rst_n`. | Output valid clears and pipeline restarts cleanly. |
| Exact centroid match | Input pixel equals one centroid. | Distance is zero and matching centroid is selected. |
| Known nearest centroid | Use fixed RGB input and known centroids. | Expected centroid is selected. |
| Minimum at index 0 | Closest centroid is first entry. | `best_cluster_id = 0`. |
| Minimum at last index | Closest centroid is final entry. | Final index selected. |
| Tie case | Two centroids have equal distance. | Lowest index wins. |
| Continuous stream | Send valid pixels every clock. | One output per clock after pipeline fill. |
| Invalid bubble | Insert invalid cycles. | Invalid bubbles propagate through output. |
| Frame markers | Apply `sof`, `eol`, `eof`. | Markers align with corresponding clustered pixels. |
| Coordinate ramp | Increment `xcnt` and `ycnt`. | Output coordinates match delayed input coordinates. |
| Centroid write/readback | Write known centroid values. | Readback returns same values. |
| Boundary RGB values | Test 0 and 255 channel values. | No overflow or incorrect signed behavior. |

---

## 5. Pipeline Latency Check

The testbench should measure latency using a known input pulse:

```text
input valid pixel at cycle T
expected output at cycle T + L_total
```

The observed output cycle must match the configured pipeline latency.

---

## 6. Metadata Alignment Check

For every valid output pixel:

```text
output_metadata == delayed_input_metadata
```

Fields to check:

- valid
- sof
- eol
- eof
- xcnt
- ycnt

---

## 7. Randomized Testing

Random testing should generate:

- random RGB pixels
- random centroid values
- random valid gaps
- random frame/line boundary placement

The reference model must compute expected outputs for every valid input transaction.

---

## 8. Assertions

Recommended assertions:

```text
assert output_valid only after reset release and pipeline fill
assert metadata delay equals datapath latency
assert selected index is inside valid centroid range
assert read index is inside valid centroid range
assert write index is inside valid centroid range
assert output RGB equals selected centroid RGB
```

---

## 9. Coverage Goals

Coverage should include:

- all centroid indices selected at least once
- all RGB boundary values tested
- tie condition tested
- reset during idle and active stream
- continuous and gapped streams
- all frame marker combinations
- centroid programming and readback paths

---

## 10. Summary

The verification plan validates the RGB K-Means Cluster Engine at the algorithmic, interface, timing, and stream-control levels. Correct verification requires both output RGB checking and metadata alignment checking after the documented pipeline latency.
