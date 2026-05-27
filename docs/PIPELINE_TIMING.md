# Pipeline Timing and Latency

**Designer Name:** Sakinder Ali  
**Module Context:** `rgb_kmeans_cluster_engine`

---

## 1. Purpose

The pipeline timing specification defines how RGB pixel data and stream metadata move through the clustering engine over time. It establishes latency, throughput, alignment rules, reset behavior, and verification expectations.

---

## 2. Timing Definitions

### Latency

Latency is the number of clock cycles between a valid input pixel and its corresponding valid output pixel.

```text
latency = output_cycle - input_cycle
```

### Throughput

Throughput is the rate at which the design can accept and produce pixels.

Target steady-state throughput:

```text
1 pixel per clock
```

---

## 3. Typical Pipeline Stages

| Stage | Function |
|---:|---|
| 0 | Input capture. |
| 1 | RGB/centroid difference calculation. |
| 2 | Distance accumulation. |
| 3 | Minimum-distance selection. |
| 4 | Centroid output selection. |
| 5 | Output register. |

The exact stage count may change depending on centroid count, comparator depth, distance metric, and target clock frequency.

---

## 4. Total Latency

The total latency is:

```text
L_total = L_input + L_distance + L_compare + L_mux + L_output
```

If square-root or Euclidean-distance hardware is used:

```text
L_total = L_input + L_distance + L_sqrt + L_compare + L_mux + L_output
```

---

## 5. Example Timing

Assume a five-cycle pipeline:

| Cycle | Activity |
|---|---|
| `t0` | Input pixel captured. |
| `t1` | Distance computation begins. |
| `t2` | Distance accumulation. |
| `t3` | Minimum selection. |
| `t4` | Output centroid selected. |
| `t5` | Clustered pixel output valid. |

Therefore:

```text
latency = 5 cycles
```

---

## 6. Pipeline Fill and Drain

### Fill Phase

After reset or startup, the pipeline requires `L_total` cycles before the first valid output appears.

### Steady State

After the pipeline is full, the engine should produce one output per cycle if the input stream remains valid and the design is fully parallel.

### Drain Phase

When input valid deasserts, the pipeline continues to emit delayed valid outputs until all in-flight pixels have exited.

---

## 7. Metadata Alignment

All metadata must be delayed by exactly `L_total` cycles.

Required aligned fields include:

- `valid`
- `sof`
- `eol`
- `eof`
- `xcnt`
- `ycnt`

Alignment rule:

```text
output_metadata(t0 + L_total) = input_metadata(t0)
```

---

## 8. Timing Closure Considerations

To improve timing closure:

1. Register distance outputs.
2. Use a balanced comparator tree.
3. Register comparator-tree levels for large `K`.
4. Register the output centroid MUX.
5. Avoid very wide combinational fan-in.
6. Document exact stage latency after synthesis changes.

---

## 9. Verification Requirements

Pipeline verification must confirm:

- first output appears after expected latency
- steady-state output rate is correct
- metadata remains aligned with RGB output
- invalid bubbles propagate correctly
- reset flushes valid state
- latency remains constant for all pixels

---

## 10. Summary

Pipeline timing defines the cycle-level behavior of the RGB K-Means Cluster Engine. Correct latency accounting is required for valid video output, frame-boundary preservation, coordinate alignment, and reliable downstream integration.
