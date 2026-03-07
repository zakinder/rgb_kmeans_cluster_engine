## Centroid Interface Functional Specifications

This section defines the functional behavior of:

* `threshold`
* `k_rgb`
* `k_ind_w`
* `k_ind_r`

These signals form the core **centroid comparison and LUT access interface** used by the clustering architecture.

---

# 1. `threshold`

## Signal Name

`threshold`

## Direction

Output

```vhdl
threshold : out integer
```

## Purpose

`threshold` carries the **distance result** between the current input pixel and the selected centroid RGB value.

It is the numeric measure used to determine how closely the input pixel matches a centroid.

---

## Functional Role

For a given pixel and centroid, `threshold` represents the color separation metric.

In your clustering flow, this value is used to:

* compare candidate centroids
* identify the best matching cluster
* drive cluster selection logic

---

## Typical Computation

In your design style, `threshold` is commonly based on **Manhattan distance**:

```text
threshold = |R - Rc| + |G - Gc| + |B - Bc|
```

Where:

* `R, G, B` are input pixel color values
* `Rc, Gc, Bc` are centroid color values from `k_rgb`

---

## Behavior

* smaller `threshold` → closer centroid match
* larger `threshold` → poorer centroid match

The centroid with the **minimum threshold** is typically selected as the winning cluster.

---

## Example

If:

```text
pixel = (100, 120, 140)
k_rgb = (90, 110, 150)
```

Then:

```text
threshold = |100-90| + |120-110| + |140-150|
          = 10 + 10 + 10
          = 30
```

---

## Timing Behavior

`threshold` is usually produced:

* combinationally inside comparison logic, or
* synchronously in a registered pipeline stage

In `rgb_cluster_core`, it is typically updated on the rising clock edge.

---

## Design Intent

`threshold` provides a simple, FPGA-efficient metric for color similarity.

It is preferred in streaming designs because:

* absolute difference is hardware-friendly
* no multiplication is required
* low-latency implementation is possible

---

## Recommended Rename

* `color_distance`
* `centroid_distance`
* `cluster_distance`

Best choice:

```vhdl
color_distance
```

---

# 2. `k_rgb`

## Signal Name

`k_rgb`

## Direction

Input

```vhdl
k_rgb : in int_rgb
```

## Purpose

`k_rgb` carries the **currently selected centroid RGB value** being compared against the incoming pixel.

It is a single centroid color input to the cluster comparison block.

---

## Functional Role

`k_rgb` is the active reference centroid for the local comparison stage.

The module uses it to compute the threshold between:

* the input pixel color
* one candidate centroid color

---

## Type Meaning

Typical record format:

```vhdl
type int_rgb is record
    red : integer;
    gre : integer;
    blu : integer;
end record;
```

So `k_rgb` contains:

* `k_rgb.red`
* `k_rgb.gre`
* `k_rgb.blu`

These are the RGB components of one centroid.

---

## Behavior

For each input pixel:

* `pixel_in_rgb.red` is compared with `k_rgb.red`
* `pixel_in_rgb.green` is compared with `k_rgb.gre`
* `pixel_in_rgb.blue` is compared with `k_rgb.blu`

This produces the corresponding `threshold`.

---

## Example

If:

```text
k_rgb = (180, 140, 90)
```

then this centroid becomes the current comparison target.

---

## Design Intent

`k_rgb` allows the design to isolate one centroid comparison at a time, which is useful for:

* modular design
* replicated cluster comparison blocks
* scalable K-centroid architectures

---

## Relationship to `k_rgb_lut`

`k_rgb` is often derived from one entry of `k_rgb_lut`.

Conceptually:

```vhdl
k_rgb <= k_rgb_lut(i);
```

So:

* `k_rgb_lut` = full centroid table
* `k_rgb` = one selected centroid entry

---

## Recommended Rename

* `centroid_rgb`
* `active_centroid_rgb`
* `current_centroid`

Best choice:

```vhdl
active_centroid_rgb
```

---

# 3. `k_ind_w`

## Signal Name

`k_ind_w`

## Direction

Input

```vhdl
k_ind_w : in natural
```

or better:

```vhdl
k_ind_w : in natural range 0 to cluster_count-1
```

## Purpose

`k_ind_w` is the **centroid write index**.

It identifies which centroid entry is targeted for a write or update operation.

---

## Functional Role

This signal selects the LUT entry to be modified during centroid programming.

It is used with:

* `centroid_lut_select`
* `centroid_lut_in`

to control centroid memory update behavior.

---

## Typical Write Condition

Your portable architecture uses:

```vhdl
if k_ind_w = centroid_lut_select then
```

This means write occurs only when the write index matches the selected centroid address.

---

## Example

If:

* `k_ind_w = 2`
* `centroid_lut_select = 2`
* `centroid_lut_in = x"804020"`

then centroid 2 is updated.

---

## Design Intent

`k_ind_w` exists to give explicit write-side addressing control for centroid memory.

This helps support:

* initialization sequences
* runtime centroid update
* external control FSM programming

---

## Recommended Rename

* `centroid_write_index`
* `centroid_wr_addr`
* `centroid_write_sel`

Best choice:

```vhdl
centroid_write_index
```

---

# 4. `k_ind_r`

## Signal Name

`k_ind_r`

## Direction

Input

```vhdl
k_ind_r : in natural
```

or better:

```vhdl
k_ind_r : in natural range 0 to cluster_count-1
```

## Purpose

`k_ind_r` is the **centroid read index**.

It identifies which centroid entry is read back from centroid memory.

---

## Functional Role

This signal selects the centroid LUT entry whose contents are presented on the readback output.

Typical use:

```vhdl
centroid_lut_out <= ...
                    lut_mem(k_ind_r)
```

So `k_ind_r` acts as the read address into the centroid LUT.

---

## Example

If:

* `k_ind_r = 4`

then centroid entry 4 is returned on `centroid_lut_out`.

---

## Use Cases

* debug
* status monitoring
* software readback
* verification
* observing runtime centroid values

---

## Design Intent

`k_ind_r` provides independent read access to centroid storage without disturbing clustering operation.

---

## Recommended Rename

* `centroid_read_index`
* `centroid_rd_addr`
* `centroid_read_sel`

Best choice:

```vhdl
centroid_read_index
```

---

# 5. Signal Relationship

These signals work together in two paths.

## Comparison Path

* `k_rgb` provides one active centroid RGB value
* `threshold` reports the distance between pixel and centroid

## Memory Access Path

* `k_ind_w` selects which centroid entry to write
* `k_ind_r` selects which centroid entry to read

---

# 6. Functional Flow

## A. Centroid Comparison

1. Input pixel arrives
2. `k_rgb` provides a centroid
3. distance is computed
4. result is sent on `threshold`

## B. Centroid Write

1. controller chooses centroid entry using `k_ind_w`
2. centroid data is supplied
3. LUT entry is updated

## C. Centroid Read

1. controller selects centroid entry using `k_ind_r`
2. selected centroid value is returned on output bus

---

# 7. Simplified Interface Table

| Signal      | Direction | Function                                         |
| ----------- | --------- | ------------------------------------------------ |
| `k_rgb`     | Input     | Active centroid RGB value used for comparison    |
| `threshold` | Output    | Distance between input pixel and active centroid |
| `k_ind_w`   | Input     | Centroid write index                             |
| `k_ind_r`   | Input     | Centroid read index                              |

---

# 8. Document-Ready Text

### `threshold`

`threshold` is the color-distance output of the centroid comparison block. It represents the difference between the current input pixel and the selected centroid RGB value. Lower threshold values indicate a closer match between the pixel and the centroid.

### `k_rgb`

`k_rgb` is the active centroid RGB input to the cluster comparison module. It provides the reference red, green, and blue values against which the current input pixel is compared.

### `k_ind_w`

`k_ind_w` is the centroid write index input. It identifies which centroid LUT entry is targeted for update during centroid programming or reconfiguration operations.

### `k_ind_r`

`k_ind_r` is the centroid read index input. It selects which centroid LUT entry is returned during readback or status-monitoring operations.

---

# 9. Recommended Cleaner Naming Set

| Current Name | Recommended Name       |
| ------------ | ---------------------- |
| `threshold`  | `color_distance`       |
| `k_rgb`      | `active_centroid_rgb`  |
| `k_ind_w`    | `centroid_write_index` |
| `k_ind_r`    | `centroid_read_index`  |

---

# 10. Engineering Summary

* `k_rgb` = one centroid color under test
* `threshold` = distance from input pixel to that centroid
* `k_ind_w` = write address for centroid memory
* `k_ind_r` = read address for centroid memory

These signals define the core **centroid comparison and centroid memory access behavior** of the clustering architecture.

I can turn all of these signal specs into one **complete specification chapter** for your design document.
