## Architecture Specification: **RGB K-Means Clustering Engine**

### System Name

`rgb_kmeans_cluster_engine`

### Architecture Type

Streaming FPGA image-processing architecture for **nearest-centroid RGB clustering**

### Purpose

The architecture performs real-time pixel clustering by assigning each input RGB pixel to the nearest centroid from a stored centroid set.

It is designed for:

* color quantization
* image segmentation
* object/color-region extraction
* real-time FPGA video pipelines

---

# 1. Architectural Objective

The architecture must:

* accept a streaming RGB pixel input
* preserve video stream timing and metadata
* compare each pixel against `K` centroids
* select the closest centroid
* output the centroid-mapped pixel
* support centroid programming and readback
* operate deterministically with fixed pipeline latency

---

# 2. Top-Level Functional View

At the system level, the engine is composed of six main architectural regions:

1. **Input Pixel Stream Interface**
2. **Centroid LUT Memory**
3. **Distance Computation Array**
4. **Minimum Distance Selector**
5. **Centroid Output MUX / Clustered Pixel Generator**
6. **Metadata / Control Pipeline**

---

# 3. High-Level Block Diagram Description

```text
Input Pixel Stream
      │
      ▼
+---------------------------+
| Input / Metadata Capture  |
+---------------------------+
      │
      ├───────────────► Metadata Pipeline
      │
      ▼
+---------------------------+
| Centroid LUT Interface    |
| (read / write / select)   |
+---------------------------+
      │
      ▼
+---------------------------+
| Distance Computation Array|
|  D0 D1 D2 ... D(K-1)      |
+---------------------------+
      │
      ▼
+---------------------------+
| Minimum Distance Selector |
|  min_val / min_id         |
+---------------------------+
      │
      ▼
+---------------------------+
| Centroid Output MUX       |
| / Clustered Pixel Gen     |
+---------------------------+
      │
      ▼
Clustered Output Pixel Stream
```

---

# 4. Architectural Dataflow

For each input pixel, the architecture performs the following sequence:

### Stage A — Input Capture

The incoming pixel record is sampled:

* `valid`
* `sof`
* `eol`
* `eof`
* `xcnt`
* `ycnt`
* `red`
* `green`
* `blue`

### Stage B — Centroid Access

The engine reads all active centroid RGB entries from the centroid LUT.

### Stage C — Distance Computation

The input pixel is compared with each centroid using the distance engine.

### Stage D — Minimum Selection

All candidate distances are evaluated and the nearest centroid is selected.

### Stage E — Output Mapping

The winning centroid RGB value replaces the original pixel RGB.

### Stage F — Metadata Alignment

The original metadata is forwarded through a matching pipeline and aligned with the clustered RGB result.

---

# 5. Top-Level Architectural Blocks

## 5.1 Input Pixel Stream Interface

### Purpose

Receives the streaming pixel input and separates:

* payload data
* timing/control metadata

### Inputs

* `pixel_in_rgb`

### Functions

* capture pixel values
* capture stream markers
* provide synchronized input to downstream blocks

### Architectural Role

Acts as the entry point into the clustering pipeline.

---

## 5.2 Centroid LUT Memory

### Purpose

Stores the centroid RGB values used for clustering.

### Functions

* centroid write/programming
* centroid readback
* centroid supply to distance units

### Interface Signals

* `centroid_lut_select`
* `centroid_lut_in`
* `centroid_lut_out`
* `k_ind_w`
* `k_ind_r`

### Architectural Role

Provides the cluster reference database for the engine.

---

## 5.3 Distance Computation Array

### Purpose

Computes one distance value for each centroid.

### Internal Structure

Composed of either:

* replicated `rgb_cluster_core` blocks, or
* equivalent parallel arithmetic logic

### Operation

For each centroid `i`, compute:

```text
D(i) = |R - Ri| + |G - Gi| + |B - Bi|
```

### Architectural Role

Transforms the input pixel and centroid set into a set of candidate distance values.

---

## 5.4 Minimum Distance Selector

### Purpose

Selects the smallest candidate distance.

### Outputs

* `int_min_val`
* `int_min_id`

### Architectural Role

Implements the clustering decision.

This block determines:

* the nearest centroid
* the winning cluster index

---

## 5.5 Centroid Output MUX / Clustered Pixel Generator

### Purpose

Maps the winning centroid index to an RGB output value.

### Functions

* select centroid color using `int_min_id`
* replace input RGB with centroid RGB
* generate clustered output pixel record

### Architectural Role

Converts the clustering decision into a visible output pixel.

---

## 5.6 Metadata / Control Pipeline

### Purpose

Preserves timing and spatial context.

### Forwarded Fields

* `valid`
* `sof`
* `eol`
* `eof`
* `xcnt`
* `ycnt`

### Architectural Role

Ensures clustered output remains aligned with the original video stream structure.

---

# 6. Architectural Control Paths

The architecture contains two major categories of control:

## 6.1 Pixel Stream Control

Controls streaming behavior and pixel alignment:

* valid propagation
* frame markers
* line markers
* coordinate tracking

## 6.2 Centroid Configuration Control

Controls centroid storage:

* centroid address selection
* write index
* read index
* readback path

These two control domains interact but serve different purposes:

* one manages **stream timing**
* one manages **cluster definition**

---

# 7. Internal Architectural Interfaces

## 7.1 Pixel-to-Distance Interface

Connects:

* input pixel channels
* centroid RGB values
* distance units

### Data Passed

* pixel RGB
* centroid RGB
* comparison enable / valid alignment

---

## 7.2 Distance-to-Selector Interface

Connects:

* multiple distance outputs
* minimum distance logic

### Data Passed

* candidate thresholds
* associated centroid indices

---

## 7.3 Selector-to-Output Interface

Connects:

* winning centroid index
* centroid output mapping stage

### Data Passed

* `int_min_id`
* optionally `int_min_val`
* aligned metadata

---

# 8. Architectural Operation Modes

## Mode 1 — Static Centroid Mode

Centroids are preloaded and remain constant during pixel processing.

### Use Cases

* color quantization
* fixed segmentation profiles
* stable production pipelines

---

## Mode 2 — Reconfigurable Centroid Mode

Centroids may be rewritten at runtime through the LUT interface.

### Use Cases

* profile switching
* scene-dependent segmentation
* controlled cluster updates

---

## Mode 3 — Extended Euclidean Mode

If `square_root` is included, the architecture may support Euclidean magnitude computation instead of only Manhattan distance.

### Use Cases

* higher-accuracy centroid comparison
* research-oriented clustering variants

---

# 9. Pipeline Architecture

The engine is architected as a pipelined streaming datapath.

Typical pipeline stages:

| Stage | Function                                |
| ----- | --------------------------------------- |
| 0     | input capture                           |
| 1     | centroid fetch / RGB preparation        |
| 2     | absolute channel difference computation |
| 3     | distance accumulation                   |
| 4     | minimum selection                       |
| 5     | centroid output mapping                 |
| 6     | output register                         |

The exact depth depends on:

* target clock frequency
* centroid count
* FPGA family
* whether additional arithmetic is inserted

---

# 10. Throughput Architecture

The architecture is intended to support:

```text
1 pixel per clock cycle
```

after pipeline fill.

This is achieved by:

* parallel centroid comparison
* registered stage boundaries
* deterministic selector logic

---

# 11. Latency Architecture

Total engine latency is the sum of:

* input registration
* distance engine delay
* minimum-selection delay
* output mapping delay
* metadata delay

### Architectural Requirement

The latency must be fixed and documented so system integration remains deterministic.

---

# 12. Module Interaction Architecture

## `rgb_cluster_core`

Acts as the primitive comparison block.

### Role

One pixel vs one centroid.

---

## `rgb_kmeans_cluster_engine`

Acts as the system-level engine.

### Role

One pixel vs all centroids + winner selection + output generation.

---

## `square_root`

Acts as optional arithmetic support.

### Role

Used only if the distance architecture requires root magnitude computation.

---

# 13. Memory Architecture

The centroid LUT may be implemented as:

## Register-Based LUT

Best for small centroid counts.

### Benefits

* fast
* simple
* low control overhead

## BRAM-Based LUT

Best for large centroid sets.

### Benefits

* scalable
* lower LUT/register usage

The architectural choice depends on:

* `K`
* update frequency
* FPGA resources
* timing goals

---

# 14. Comparator Architecture

The minimum-distance block may use one of two architectures:

## Sequential Comparison Chain

Smaller area, potentially longer critical path or latency.

## Comparator Tree

Higher parallelism, better timing scalability.

### Recommended

Comparator tree for larger centroid counts or higher-performance targets.

---

# 15. Output Architecture

The output side of the engine produces:

* clustered RGB pixel stream
* optionally cluster ID
* optionally minimum distance value
* optionally centroid debug/readback information

This makes the engine suitable both for:

* production image transformation
* debug/verification visibility

---

# 16. Metadata Architecture

The architecture explicitly treats metadata as a first-class datapath.

Metadata signals are not incidental; they are part of the formal pipeline.

### Required aligned signals

* `valid`
* `sof`
* `eol`
* `eof`
* `xcnt`
* `ycnt`

### Architectural rule

Metadata path latency must exactly match RGB datapath latency.

---

# 17. Reset and Initialization Architecture

On reset:

* centroid state is cleared or placed in known condition
* output pipeline registers are cleared
* valid output is suppressed
* internal minimum-selection registers return to default state

At initialization:

* centroid LUT may be programmed
* pipeline fills before valid clustered output appears

This ensures controlled startup behavior.

---

# 18. Verification Architecture

The architecture supports verification at several levels:

## Block-Level

* `rgb_cluster_core`
* minimum selector
* centroid LUT interface
* output MUX

## Subsystem-Level

* clustering engine without full video system

## System-Level

* full frame stream with metadata and centroid programming

### Key architectural verification goals

* correct nearest-centroid selection
* correct metadata alignment
* fixed pipeline latency
* deterministic reset behavior

---

# 19. Scalability Architecture

The engine is scalable in:

## Number of centroids

Increase `K` by:

* widening LUT
* adding distance units
* enlarging comparator structure

## Color-space extensions

Can be extended from RGB to:

* HSV
* LMS
* YCbCr
* other feature spaces

## Output modes

Can support:

* clustered RGB
* cluster index map
* threshold map
* multi-channel debug output

---

# 20. Design Intent

The architecture is intentionally modular.

Each block has a narrow responsibility:

* centroid memory stores references
* distance units evaluate similarity
* selector chooses winner
* output stage maps decision to pixel result
* metadata path preserves stream structure

This separation improves:

* readability
* maintainability
* verification
* timing optimization
* portability

---

# 21. Architectural Advantages

* real-time streaming operation
* deterministic behavior
* modular structure
* FPGA-friendly arithmetic
* scalable centroid count
* configurable centroid memory
* metadata-safe image pipeline integration

---

# 22. Architectural Limitations

* resource usage grows with centroid count
* Manhattan distance is simpler but less exact than Euclidean
* metadata alignment must be carefully maintained
* clustering quality depends on centroid selection quality
* runtime training is not inherently included unless added separately

---

# 23. Recommended Architectural Naming

If you want clearer subsystem names, this architecture can be described as:

* **Input Stream Front End**
* **Centroid Memory Subsystem**
* **Distance Engine Array**
* **Winner Selection Network**
* **Clustered Pixel Output Subsystem**
* **Metadata Alignment Pipeline**

That naming works well in formal design documents.

---

# 24. Document-Ready Architectural Description

The RGB K-Means Clustering Engine is a streaming FPGA architecture that classifies each input RGB pixel according to the nearest centroid stored in a programmable centroid lookup table. The architecture consists of an input stream interface, centroid memory subsystem, parallel distance computation units, a minimum-distance selector, a centroid output multiplexer, and a metadata alignment pipeline. Together, these blocks enable deterministic real-time color clustering while preserving frame, line, and coordinate metadata across the processing pipeline.

---

# 25. Short Engineering Definition

The RGB K-Means Clustering Engine is a pipelined nearest-centroid RGB classification architecture for real-time FPGA image processing.

---

# 26. Summary

This architecture:

* receives streaming RGB pixels
* stores programmable centroid colors
* computes pixel-to-centroid distances
* selects the nearest centroid
* outputs centroid-mapped clustered pixels
* preserves stream control and coordinates
* supports deterministic pipelined FPGA implementation

Next best section would be either **RTL Design Specification** or **Block-by-Block Interface Specification Table**.
