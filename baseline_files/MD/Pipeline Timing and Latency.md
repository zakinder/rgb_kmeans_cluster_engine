## Functional Specification: **Pipeline Timing and Latency**

### Module Context

Applies across:

* `rgb_cluster_core`
* `rgb_kmeans_cluster_engine`
* `square_root`
* metadata/control pipeline

### Purpose

The **Pipeline Timing and Latency** specification defines how data moves through the clustering architecture over time.

It describes:

* when input data is sampled
* how many clock cycles each processing stage requires
* when output data becomes valid
* how control metadata must align with processed RGB data

This specification is essential for:

* timing closure
* interface correctness
* verification
* system integration

---

# 1. Functional Objective

The pipeline must ensure that:

* each input pixel is processed deterministically
* output latency is fixed and known
* throughput targets are met
* metadata remains aligned with pixel results
* all modules interact cycle-by-cycle in a predictable way

---

# 2. Definition of Terms

## Latency

The number of clock cycles between:

* sampling a valid input, and
* producing the corresponding valid output

### Example

If a pixel enters at cycle 10 and its output appears at cycle 14:

```text
latency = 4 cycles
```

---

## Throughput

The rate at which the design can accept new inputs and produce outputs.

Typical streaming target:

```text
1 pixel per clock cycle
```

after the pipeline is filled.

---

## Pipeline Stage

A stage of logic separated by registers.

Each stage typically performs one part of the algorithm, such as:

* input register
* distance computation
* minimum selection
* centroid output mapping

---

# 3. High-Level Pipeline Structure

A typical clustering pipeline may be organized as:

```text
Stage 0 : Input capture
Stage 1 : RGB / centroid distance computation
Stage 2 : distance accumulation
Stage 3 : comparator tree / min selection
Stage 4 : centroid output MUX
Stage 5 : output register
```

Optional stages may be added depending on:

* centroid count
* clock target
* FPGA family
* whether `square_root` is used

---

# 4. Functional Timing Model

For an input pixel arriving at cycle `t0`:

```text
pixel_in_rgb @ t0
```

the corresponding clustered output appears at:

```text
pixel_out_rgb @ t0 + N
```

where `N` is the total pipeline latency.

---

## Generic Latency Relationship

```text
output_latency = sum(stage_latencies)
```

If every stage is one cycle:

```text
N = number_of_pipeline_stages
```

---

# 5. Example Pipeline Timing

Assume a 5-stage clustering pipeline.

## Cycle-by-cycle behavior

| Cycle | Activity                      |
| ----- | ----------------------------- |
| `t0`  | input pixel captured          |
| `t1`  | distance computation starts   |
| `t2`  | channel distance accumulation |
| `t3`  | minimum distance selection    |
| `t4`  | centroid color selected       |
| `t5`  | clustered pixel output valid  |

So:

```text
latency = 5 cycles
```

---

# 6. Throughput Behavior

Once the pipeline is full, a new pixel may enter every clock.

Example:

| Cycle | Input   | Output            |
| ----- | ------- | ----------------- |
| `t0`  | pixel 0 | —                 |
| `t1`  | pixel 1 | —                 |
| `t2`  | pixel 2 | —                 |
| `t3`  | pixel 3 | —                 |
| `t4`  | pixel 4 | —                 |
| `t5`  | pixel 5 | clustered pixel 0 |
| `t6`  | pixel 6 | clustered pixel 1 |
| `t7`  | pixel 7 | clustered pixel 2 |

This is the standard streaming pipeline model:

* **latency** = multiple cycles
* **throughput** = one result per cycle

---

# 7. Timing Requirements by Block

## 7.1 `rgb_cluster_core`

Typical timing role:

* receives pixel and centroid
* computes threshold

### Possible latency

* 1 cycle if registered output
* more if internal arithmetic is pipelined

### Output

```text
threshold valid after L_cluster_core cycles
```

---

## 7.2 Comparator Tree / Minimum Selector

Typical timing role:

* compares K threshold values
* selects best cluster index

### Possible latency

* 1 cycle for small K
* multiple cycles for pipelined comparator tree

### Output

```text
best_cluster valid after L_compare cycles
```

---

## 7.3 Centroid Output MUX

Typical timing role:

* selects centroid RGB by winning index
* forwards aligned metadata

### Possible latency

* combinational selection + output register
* usually 1 cycle in high-speed designs

### Output

```text
pixel_out_rgb valid after L_mux cycles
```

---

## 7.4 `square_root`

If used in Euclidean-distance mode:

### Possible latency

Depends on implementation:

* iterative
* pipelined
* combinational

### Output

```text
root_out valid after L_sqrt cycles
```

This latency must be included in total datapath timing.

---

# 8. Total Pipeline Latency

The total latency of the clustering engine is:

```text
L_total = L_input + L_distance + L_compare + L_mux + L_output
```

If square-root magnitude is included:

```text
L_total = L_input + L_distance + L_sqrt + L_compare + L_mux + L_output
```

---

# 9. Metadata Alignment Requirement

All metadata must be delayed by exactly the same number of cycles as the RGB datapath.

Required fields:

* `valid`
* `sof`
* `eol`
* `eof`
* `xcnt`
* `ycnt`

If datapath latency is `L_total`, then:

```text
metadata_delay = L_total
```

---

## Alignment Rule

For any pixel entering at cycle `t0`:

```text
input metadata @ t0
clustered RGB     @ t0 + L_total
output metadata   @ t0 + L_total
```

This is mandatory for correct stream behavior.

---

# 10. Valid Signal Timing

The `valid` signal defines when output data is meaningful.

## Rule

If input pixel is valid at cycle `t0`, then output pixel must be valid at:

```text
t0 + L_total
```

## Invalid Cycles

If input `valid = 0`, then output `valid` must remain aligned with the invalid bubble.

This preserves idle-cycle spacing through the pipeline.

---

# 11. Boundary Marker Timing

## `sof`

Must align with the first valid clustered pixel of the frame.

## `eol`

Must align with the final clustered pixel of each line.

## `eof`

Must align with the last valid clustered pixel of the frame.

Any shift in these signals will corrupt downstream frame interpretation.

---

# 12. Coordinate Timing

## `xcnt` and `ycnt`

These coordinates must be delayed by the same number of stages as the pixel RGB path.

For the pixel entering at `(xcnt, ycnt)`:

```text
output clustered pixel at same coordinates
```

after `L_total` cycles.

---

# 13. Example Timing Table

Assume:

* total latency = 4 cycles

Input pixel A arrives at cycle 10:

| Cycle | Input Pixel | Output Pixel |
| ----- | ----------- | ------------ |
| 10    | A enters    | —            |
| 11    | B enters    | —            |
| 12    | C enters    | —            |
| 13    | D enters    | —            |
| 14    | E enters    | A exits      |
| 15    | F enters    | B exits      |
| 16    | G enters    | C exits      |

Metadata for pixel A must also appear at cycle 14.

---

# 14. Pipeline Fill and Drain Behavior

## Fill Phase

At startup, the pipeline needs `L_total` cycles before the first valid output appears.

## Steady State

After filling, the pipeline can sustain one output per cycle.

## Drain Phase

When input stops, the pipeline continues producing remaining outputs for `L_total` cycles.

---

# 15. Reset Behavior

When `rst_n = '0'`:

* pipeline registers are cleared
* output valid is deasserted
* internal state resets to known values

After reset release:

* pipeline must refill
* output becomes valid only after full latency elapses

---

# 16. Timing Closure Considerations

Pipeline staging is used to:

* reduce combinational path length
* improve maximum clock frequency
* keep centroid comparison scalable
* support larger K values

Recommended practice:

* register comparator tree levels
* register output MUX stage
* document exact stage count

---

# 17. Functional Constraints

## Constraint 1

All compared distances must correspond to the same pixel cycle.

## Constraint 2

Winning centroid index must remain aligned with centroid RGB selection.

## Constraint 3

Metadata delay must exactly match RGB processing delay.

## Constraint 4

Any change in pipeline depth requires a matching update to metadata path delay.

---

# 18. Verification Requirements

The design should verify:

* first valid output occurs after the expected latency
* one output per clock is sustained in steady state
* `sof/eol/eof` emerge with the correct clustered pixels
* `xcnt/ycnt` remain aligned with clustered output
* reset clears pipeline correctly
* latency remains constant for all pixels

---

# 19. Recommended Test Scenarios

## Test 1 — Single Pixel Pulse

Send one valid pixel and measure cycle difference to output.

## Test 2 — Continuous Stream

Send consecutive valid pixels and verify one output per cycle after fill.

## Test 3 — Frame Boundary Markers

Inject `sof`, `eol`, `eof` and verify correct output alignment.

## Test 4 — Reset Mid-Stream

Assert reset and verify pipeline flush/reset behavior.

## Test 5 — Bubble Propagation

Insert invalid cycles and verify bubble preservation.

---

# 20. Document-Ready Functional Description

The Pipeline Timing and Latency specification defines the cycle-by-cycle behavior of the clustering datapath. It establishes the number of clock cycles required for an input pixel to propagate through the processing stages and produce a clustered output pixel. The specification also requires all control and coordinate metadata to be delayed by the same number of cycles as the RGB datapath so that output validity, frame boundaries, line boundaries, and pixel coordinates remain correctly aligned with the processed pixel data.

---

# 21. Short Engineering Definition

Pipeline Timing and Latency defines when clustered pixel results appear and how metadata remains cycle-aligned through the processing pipeline.

---

# 22. Summary

This specification defines:

* total datapath latency
* steady-state throughput
* metadata alignment rules
* reset/fill/drain behavior
* verification requirements for cycle correctness

The next logical section is **Functional Specification: Reset and Initialization Behavior**.
