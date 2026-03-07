## Functional Specification: **Centroid LUT Design**

### Function Name

**Centroid Lookup Table (Centroid LUT)**

### Purpose

The **Centroid LUT** stores the RGB values of all cluster centroids used by the clustering algorithm.

It acts as a **centroid memory structure** that allows the clustering engine to:

* store cluster center RGB values
* update centroid values during configuration
* supply centroid values to the distance-computation blocks
* provide readback capability for monitoring and verification

The LUT is a critical component of the **`rgb_kmeans_cluster_engine`**.

---

# 1. Functional Objective

The Centroid LUT provides a storage mechanism for the centroid set:

```
C0 = (R0,G0,B0)
C1 = (R1,G1,B1)
...
CK-1 = (RK-1,GK-1,BK-1)
```

These values represent the **cluster centers** used by the clustering algorithm.

During pixel processing, each centroid value is used as a reference for color comparison.

---

# 2. Centroid LUT Structure

The LUT contains **K centroid entries**.

Each entry stores:

```
Red channel
Green channel
Blue channel
```

### Example Structure

| Index | Red  | Green | Blue |
| ----- | ---- | ----- | ---- |
| C0    | R0   | G0    | B0   |
| C1    | R1   | G1    | B1   |
| C2    | R2   | G2    | B2   |
| ...   | ...  | ...   | ...  |
| CK-1  | RK-1 | GK-1  | BK-1 |

---

# 3. Hardware Representation

Each centroid entry is typically stored as a **24-bit RGB value**.

```
[23:16]  Red
[15:8]   Green
[7:0]    Blue
```

Example:

```
centroid_lut_in = RRRRRRRR GGGGGGGG BBBBBBBB
```

---

# 4. Interface Signals

### Inputs

#### `centroid_lut_select`

Centroid index used to select a specific LUT entry.

```
Range: 0 to K-1
```

Used during centroid programming.

---

#### `centroid_lut_in`

RGB value written into the selected centroid entry.

```
std_logic_vector(23 downto 0)
```

Packed RGB format.

---

#### `k_ind_w`

Centroid write index.

Used to identify which centroid entry should be updated.

---

#### `k_ind_r`

Centroid read index.

Used to select a centroid entry for readback.

---

### Outputs

#### `centroid_lut_out`

Returns the stored centroid RGB value for the selected index.

Example format:

```
[23:16] Red
[15:8]  Green
[7:0]   Blue
```

Upper bits may be padded to 32 bits depending on implementation.

---

# 5. Functional Behavior

## Step 1 — Centroid Initialization

At system startup, the LUT may be initialized with predefined centroid values.

Example:

```
C0 = (255,240,230)
C1 = (240,220,210)
C2 = (240,210,150)
...
```

These values may represent:

* trained color clusters
* segmentation classes
* quantization palette entries

---

## Step 2 — Centroid Programming

The centroid LUT can be updated dynamically.

Write operation occurs when:

```
k_ind_w = centroid_lut_select
```

Then the centroid entry is updated:

```
centroid[k_ind_w] ← centroid_lut_in
```

This allows external control logic or software to modify cluster centers.

---

## Step 3 — Centroid Readback

The LUT supports readback through:

```
k_ind_r
```

The selected centroid entry is returned through:

```
centroid_lut_out
```

Example:

```
centroid_lut_out = centroid[k_ind_r]
```

This enables:

* debugging
* runtime monitoring
* verification

---

## Step 4 — Centroid Supply to Clustering Engine

During pixel processing, the clustering engine reads centroid values from the LUT.

These values are provided to:

```
rgb_cluster_core
```

for distance computation.

---

# 6. Memory Implementation

The LUT may be implemented using:

### Register Array

```
type centroid_array is array (0 to K-1) of int_rgb;
signal centroid_lut : centroid_array;
```

Advantages:

* fast access
* simple design
* good for small K

---

### Block RAM

Used for larger centroid counts.

Advantages:

* scalable
* lower logic usage

---

# 7. Data Flow

The centroid LUT participates in two major datapaths.

### Configuration Path

```
Control Interface
      │
      ▼
centroid_lut_in
      │
      ▼
Centroid LUT
```

---

### Pixel Processing Path

```
Centroid LUT
      │
      ▼
rgb_cluster_core
      │
      ▼
Distance Computation
```

---

# 8. Example Operation

Assume the following centroid values:

```
C0 = (255,240,230)
C1 = (240,220,210)
C2 = (240,210,150)
C3 = (180,160,140)
C4 = (150,120,110)
```

Input pixel:

```
P = (160,120,100)
```

The clustering engine retrieves each centroid from the LUT and computes distance.

The centroid with minimum distance becomes the cluster output.

---

# 9. Design Constraints

### Index Range

```
0 ≤ centroid_index < K
```

Invalid indices must be prevented.

---

### RGB Value Range

For 8-bit channels:

```
0 ≤ R,G,B ≤ 255
```

---

### Write Synchronization

Centroid updates should occur only when the clustering pipeline is in a safe state.

---

# 10. Timing Behavior

### Write Operation

Occurs on the rising clock edge.

```
if rising_edge(clk) then
    if write_enable = '1' then
        centroid_lut(index) <= centroid_lut_in
    end if
end if
```

---

### Read Operation

Typically combinational or registered depending on implementation.

---

# 11. Design Intent

The Centroid LUT is designed to:

* provide fast centroid access
* support runtime configuration
* enable scalable clustering architectures
* maintain deterministic pixel throughput

It separates **centroid storage** from **distance computation**, making the design modular and easier to maintain.

---

# 12. Advantages

* simple memory structure
* scalable cluster count
* runtime centroid programmability
* efficient FPGA implementation
* supports both static and adaptive clustering

---

# 13. Limitations

* centroid count limited by hardware resources
* LUT updates must be synchronized with pixel pipeline
* clustering quality depends on centroid accuracy

---

# 14. Document-Ready Functional Description

The Centroid LUT stores the RGB values of the cluster centers used by the clustering algorithm. Each entry contains a 24-bit RGB value representing one centroid. The LUT supports write operations for centroid programming and read operations for centroid monitoring. During pixel processing, centroid values are retrieved from the LUT and supplied to the clustering comparison units to determine the nearest centroid for each pixel.

---

# 15. Short Engineering Definition

The Centroid LUT is a memory structure that stores RGB centroid values used by the clustering engine for pixel classification.

---

# 16. Summary

The Centroid LUT:

* stores **K RGB centroid values**
* supports **write and read access**
* feeds centroid data to the clustering engine
* enables **programmable color clustering**

---

If you'd like, I can also produce the next specification section:

**Functional Specifications: Distance Computation Unit (RGB Distance Engine)**

which describes the **exact arithmetic datapath used inside `rgb_cluster_core`** (very useful for FPGA design documentation).
