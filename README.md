# RGB K-Means Cluster Engine

**Designer Name:** Sakinder Ali  
**Repository:** `zakinder/rgb_kmeans_cluster_engine`  
**Domain:** FPGA / VHDL / Real-Time RGB Image Processing

---

## Overview

`rgb_kmeans_cluster_engine` is a VHDL-oriented FPGA design for real-time RGB pixel clustering. The engine receives a streaming RGB pixel, compares it against stored RGB centroid values, selects the nearest centroid, and outputs the corresponding clustered RGB color.

The design supports color quantization, image segmentation, color-region classification, and hardware-accelerated palette-style processing in deterministic video pipelines.

---

## Core Function

For each valid input pixel:

```text
P = (R, G, B)
```

The engine compares the pixel against centroid entries:

```text
C(i) = (Ri, Gi, Bi)
```

Using the hardware-efficient distance model:

```text
D(i) = |R - Ri| + |G - Gi| + |B - Bi|
```

The selected output is the nearest centroid:

```text
pixel_out_rgb = C(argmin D(i))
```

---

## Main Features

- Real-time RGB stream processing
- FPGA-friendly centroid-based clustering
- Programmable/readable centroid LUT interface
- Manhattan-distance RGB comparison
- Minimum-distance centroid selection
- Clustered RGB output generation
- Metadata alignment for valid/frame/line/coordinate fields
- Pipeline-oriented timing model
- Verification-ready design documentation
- External-controller runtime intelligence-layer management
- Diagnostic readback and configuration-integrity verification
- Shadow-buffered runtime profile activation
- Invention value-proposition and commercial applicability analysis
- Learner-friendly pixel journey explanation
- 35-cycle student-facing RGB-to-cluster-ID journey narrative

---

## Repository Documentation

| Document | Description |
|---|---|
| [DESIGN.md](DESIGN.md) | Main design document covering purpose, interface, architecture, timing, verification, limitations, and enhancements. |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Hardware architecture and block-level structure. |
| [docs/CLUSTERING_ALGORITHM.md](docs/CLUSTERING_ALGORITHM.md) | RGB centroid clustering algorithm and mathematical model. |
| [docs/CENTROID_LUT.md](docs/CENTROID_LUT.md) | Centroid storage, programming, readback, and profile-selection design. |
| [docs/DISTANCE_COMPUTATION_UNIT.md](docs/DISTANCE_COMPUTATION_UNIT.md) | RGB distance calculation logic and hardware mapping. |
| [docs/MINIMUM_DISTANCE_SELECTOR.md](docs/MINIMUM_DISTANCE_SELECTOR.md) | Comparator-tree and nearest-centroid selection logic. |
| [docs/PIXEL_STREAM_METADATA.md](docs/PIXEL_STREAM_METADATA.md) | Stream metadata, valid signal, frame markers, and coordinate alignment. |
| [docs/PIPELINE_TIMING.md](docs/PIPELINE_TIMING.md) | Pipeline latency, throughput, fill/drain behavior, and timing closure notes. |
| [docs/VERIFICATION_PLAN.md](docs/VERIFICATION_PLAN.md) | Test strategy, reference model, assertions, and coverage goals. |
| [docs/PIXEL_JOURNEY_NARRATIVE.md](docs/PIXEL_JOURNEY_NARRATIVE.md) | Learner-friendly story following one pixel through five stages from input RGB to assigned clustered color. |
| [docs/PIXEL_35_CYCLE_JOURNEY.md](docs/PIXEL_35_CYCLE_JOURNEY.md) | Encouraging student narrative following a pixel through a 35-cycle journey from RGB input, neutral space interception, distance measurement, comparator tree, cluster ID, and final output mapper. |
| [docs/EXTERNAL_CONTROLLER_INTELLIGENCE_LAYER_GUIDE.md](docs/EXTERNAL_CONTROLLER_INTELLIGENCE_LAYER_GUIDE.md) | Professional software/firmware guide for safe runtime updates, representative control registers, and diagnostic readback verification. |
| [docs/INVENTION_VALUE_PROPOSITION_ANALYSIS.md](docs/INVENTION_VALUE_PROPOSITION_ANALYSIS.md) | Substantive analysis of technical claims, novelty, mid-frame artifact prevention, and commercial applicability across industrial inspection, robotics vision, and other sectors. |

---

## Top-Level Interface

```vhdl
entity rgb_kmeans_cluster_engine is
    generic (
        i_data_width : integer := 8
    );
    port (
        clk                 : in  std_logic;
        rst_n               : in  std_logic;
        pixel_in_rgb        : in  channel;
        centroid_lut_select : in  natural;
        centroid_lut_in     : in  std_logic_vector(23 downto 0);
        centroid_lut_out    : out std_logic_vector(31 downto 0);
        k_ind_w             : in  natural;
        k_ind_r             : in  natural;
        pixel_out_rgb       : out channel
    );
end rgb_kmeans_cluster_engine;
```

---

## Functional Blocks

```text
Input RGB Stream
      |
      v
Input Capture / Metadata Register
      |
      v
Centroid LUT / Profile Bank
      |
      v
RGB Distance Computation
      |
      v
Minimum-Distance Selector
      |
      v
Centroid Output MUX
      |
      v
Clustered RGB Output Stream
```

---

## Use Cases

- RGB color quantization
- Real-time image segmentation
- Color-region classification
- Object/region pre-filtering
- FPGA video preprocessing
- Palette-based visual simplification
- Adaptive centroid-profile experiments
- Runtime centroid-profile control from firmware/software
- Industrial inspection recipe switching
- Robotics vision profile adaptation

---

## Design Notes

The design favors deterministic FPGA implementation. Manhattan distance is used as the primary distance metric because it maps efficiently to subtractors, absolute-value logic, adders, and comparator trees. The architecture can be extended with deeper pipelining, parameterized centroid count, shadow centroid LUTs, AXI-style interfaces, diagnostic readback, and formal verification assertions.
