## RTL Design Specification

### 1. RTL Design Intent

The RTL is organized so each architectural function maps to a clear synthesizable hardware block:

* input stream register/control capture
* centroid storage
* distance computation
* minimum-distance reduction
* winning-centroid selection
* output pixel generation
* metadata alignment pipeline

The RTL should remain:

* synchronous to one clock
* resettable to a known state
* parameterizable for centroid count and channel width
* synthesizable using standard IEEE VHDL

---

### 2. RTL Block Decomposition

#### A. Input Register Stage

**Purpose:** capture incoming pixel stream and stabilize input timing.

**RTL responsibilities:**

* sample `pixel_in_rgb`
* register RGB fields if needed
* register metadata fields for downstream alignment

**Typical registers:**

* `pixel_red_reg`
* `pixel_green_reg`
* `pixel_blue_reg`
* `valid_pipe(0)`
* `sof_pipe(0)`
* `eol_pipe(0)`
* `eof_pipe(0)`
* `xcnt_pipe(0)`
* `ycnt_pipe(0)`

---

#### B. Centroid LUT Storage

**Purpose:** hold centroid RGB entries.

**RTL responsibilities:**

* store centroid values in array/register memory
* allow indexed write
* allow indexed readback
* provide centroid values to comparison logic

**Typical RTL form:**

```vhdl
type centroid_t is record
    red   : unsigned(7 downto 0);
    green : unsigned(7 downto 0);
    blue  : unsigned(7 downto 0);
end record;

type centroid_array_t is array (natural range <>) of centroid_t;
signal centroid_lut : centroid_array_t(0 to K-1);
```

**Write behavior:**

```vhdl
if rising_edge(clk) then
    if wr_en = '1' then
        centroid_lut(wr_idx) <= wr_data;
    end if;
end if;
```

---

#### C. Distance Computation RTL

**Purpose:** compute pixel-to-centroid distance.

**RTL responsibilities:**

* subtract pixel and centroid channels
* compute absolute value per channel
* sum channel differences
* optionally register result

**Typical logic:**

```vhdl
dist_r <= abs(pixel_r - centroid_r);
dist_g <= abs(pixel_g - centroid_g);
dist_b <= abs(pixel_b - centroid_b);
threshold <= dist_r + dist_g + dist_b;
```

**Implementation note:** in synthesizable VHDL, absolute difference is usually written with compare/subtract, not generic `abs` on vectors.

---

#### D. Minimum-Distance Decision RTL

**Purpose:** track smallest distance and corresponding centroid index.

**RTL responsibilities:**

* initialize minimum candidate
* compare each new threshold
* update `int_min_val`
* update `int_min_id`

**Typical logic:**

```vhdl
if candidate_distance < int_min_val then
    int_min_val <= candidate_distance;
    int_min_id  <= candidate_index;
end if;
```

---

#### E. Comparator Tree RTL

**Purpose:** reduce many candidate thresholds into one winning result.

**RTL styles:**

1. loop-based sequential compare
2. staged tree compare
3. generated array of compare-select cells

**Preferred for larger K:** tree or pipelined reduction.

---

#### F. Output MUX RTL

**Purpose:** map winning centroid index to output RGB.

**RTL responsibilities:**

* index LUT using `int_min_id`
* assign centroid RGB to output pixel
* preserve aligned metadata

**Typical logic:**

```vhdl
pixel_out_rgb.red   <= std_logic_vector(centroid_lut(int_min_id).red);
pixel_out_rgb.green <= std_logic_vector(centroid_lut(int_min_id).green);
pixel_out_rgb.blue  <= std_logic_vector(centroid_lut(int_min_id).blue);
```

---

#### G. Metadata Pipeline RTL

**Purpose:** keep control fields aligned with RGB result latency.

**RTL responsibilities:**

* shift metadata through same number of stages as datapath
* present aligned metadata at output

**Typical logic:**

```vhdl
valid_pipe(i+1) <= valid_pipe(i);
sof_pipe(i+1)   <= sof_pipe(i);
eol_pipe(i+1)   <= eol_pipe(i);
eof_pipe(i+1)   <= eof_pipe(i);
xcnt_pipe(i+1)  <= xcnt_pipe(i);
ycnt_pipe(i+1)  <= ycnt_pipe(i);
```

---

### 3. RTL Clocking Specification

All state-holding elements update on:

```vhdl
if rising_edge(clk) then
```

The RTL should avoid:

* gated clocks
* asynchronous internal data latches
* mixed-edge logic unless explicitly required

---

### 4. RTL Reset Specification

Reset signal: `rst_n`

**Behavior when asserted low:**

* clear pipeline registers
* clear output validity
* clear min selector state
* optionally clear centroid LUT or set defaults

**Typical reset pattern:**

```vhdl
if rising_edge(clk) then
    if rst_n = '0' then
        -- clear state
    else
        -- normal operation
    end if;
end if;
```

---

### 5. RTL Synthesis Rules

The RTL should use:

* `ieee.std_logic_1164`
* `ieee.numeric_std`

Avoid:

* vendor-only packages
* implicit arithmetic on `std_logic_vector`
* ambiguous integer/vector conversions

Preferred data types:

* `unsigned` for arithmetic channels
* constrained `natural` for indices
* records for structured pixel data

---

### 6. RTL Parameterization

Recommended generics:

```vhdl
generic (
    DATA_WIDTH    : positive := 8;
    CLUSTER_COUNT : positive := 5
);
```

Optional:

* pipeline depth
* coordinate width
* centroid memory style

---

### 7. RTL Verification Targets

The RTL shall demonstrate:

* correct threshold generation
* correct min value and min ID selection
* correct centroid output mapping
* exact metadata alignment
* fixed latency
* clean reset behavior

---

## Block-by-Block Interface Specification Table

| Block                     | Inputs                                                                         | Outputs                               | Function                                            |
| ------------------------- | ------------------------------------------------------------------------------ | ------------------------------------- | --------------------------------------------------- |
| Input Stream Interface    | `clk`, `rst_n`, `pixel_in_rgb`                                                 | registered pixel data, metadata pipes | Captures incoming pixel and stream metadata         |
| Centroid LUT              | `clk`, `rst_n`, `centroid_lut_select`, `centroid_lut_in`, `k_ind_w`, `k_ind_r` | centroid entries, `centroid_lut_out`  | Stores, updates, and reads centroid RGB values      |
| Distance Computation Unit | pixel RGB, centroid RGB                                                        | `threshold`                           | Computes pixel-to-centroid Manhattan distance       |
| Minimum-Distance Selector | candidate `threshold`, candidate index                                         | `int_min_val`, `int_min_id`           | Tracks smallest distance and winning centroid index |
| Comparator Tree           | array of threshold values                                                      | reduced min value/index               | Reduces K candidates to one winner                  |
| Cluster ID Output         | `int_min_id`                                                                   | `cluster_id`                          | Exposes winning centroid index                      |
| Centroid Output MUX       | `int_min_id`, centroid LUT, aligned metadata                                   | `pixel_out_rgb`                       | Maps winning centroid to output pixel color         |
| Metadata Pipeline         | input metadata, `clk`, `rst_n`                                                 | aligned output metadata               | Preserves stream timing and coordinates             |
| square_root               | `clk`, `rst_n`, `radicand_in`                                                  | `root_out`                            | Optional integer square-root arithmetic support     |

---

## Detailed Interface Table

### 1. Input Stream Interface

| Signal         | Dir | Type        | Description                              |
| -------------- | --- | ----------- | ---------------------------------------- |
| `clk`          | in  | `std_logic` | system clock                             |
| `rst_n`        | in  | `std_logic` | active-low reset                         |
| `pixel_in_rgb` | in  | `channel`   | input pixel record with metadata and RGB |

**Outputs to internal datapath:**

* pixel color channels
* metadata pipeline stage 0

---

### 2. Centroid LUT Interface

| Signal                | Dir | Type                            | Description                             |
| --------------------- | --- | ------------------------------- | --------------------------------------- |
| `centroid_lut_select` | in  | `natural` / constrained range   | selected centroid entry for programming |
| `centroid_lut_in`     | in  | `std_logic_vector(23 downto 0)` | packed centroid RGB write data          |
| `k_ind_w`             | in  | `natural` / constrained range   | centroid write index                    |
| `k_ind_r`             | in  | `natural` / constrained range   | centroid read index                     |
| `centroid_lut_out`    | out | `std_logic_vector(31 downto 0)` | centroid readback bus                   |

---

### 3. Distance Computation Interface

| Signal                        | Dir | Type             | Description                  |
| ----------------------------- | --- | ---------------- | ---------------------------- |
| `pixel_in_rgb.red/green/blue` | in  | channel fields   | input pixel RGB channels     |
| `k_rgb.red/gre/blu`           | in  | `int_rgb` fields | active centroid RGB channels |
| `threshold`                   | out | `integer`        | computed Manhattan distance  |

---

### 4. Minimum Selector Interface

| Signal            | Dir          | Type                   | Description                  |
| ----------------- | ------------ | ---------------------- | ---------------------------- |
| `threshold`       | in           | `integer`              | candidate distance           |
| `candidate_index` | in           | `natural`              | centroid index for candidate |
| `int_min_val`     | out/internal | `integer`              | current minimum distance     |
| `int_min_id`      | out/internal | `natural` or `integer` | index of current minimum     |

---

### 5. Cluster ID Interface

| Signal       | Dir | Type                | Description                   |
| ------------ | --- | ------------------- | ----------------------------- |
| `int_min_id` | in  | internal index      | selected centroid index       |
| `cluster_id` | out | `natural` or vector | winning centroid index output |

---

### 6. Output Pixel Interface

| Signal             | Dir | Type         | Description                   |
| ------------------ | --- | ------------ | ----------------------------- |
| `int_min_id`       | in  | index        | selects winning centroid      |
| centroid LUT entry | in  | RGB record   | centroid color to output      |
| aligned metadata   | in  | pipe signals | valid/frame/line/coord info   |
| `pixel_out_rgb`    | out | `channel`    | clustered output pixel record |

---

### 7. square_root Interface

| Signal        | Dir | Type                                          | Description                |
| ------------- | --- | --------------------------------------------- | -------------------------- |
| `clk`         | in  | `std_logic`                                   | system clock               |
| `rst_n`       | in  | `std_logic`                                   | active-low reset           |
| `radicand_in` | in  | `std_logic_vector(data_width-1 downto 0)`     | input operand              |
| `root_out`    | out | `std_logic_vector((data_width/2)-1 downto 0)` | integer square-root result |

---

## Recommended RTL Naming Cleanup

| Current               | Recommended              |
| --------------------- | ------------------------ |
| `threshold`           | `candidate_distance`     |
| `int_min_val`         | `min_distance`           |
| `int_min_id`          | `winning_centroid_index` |
| `k_rgb`               | `active_centroid_rgb`    |
| `k_ind_w`             | `centroid_write_index`   |
| `k_ind_r`             | `centroid_read_index`    |
| `centroid_lut_select` | `centroid_index_sel`     |

---

## Short integration summary

The RTL architecture is a synchronous pipelined nearest-centroid engine in which the input stream feeds a centroid comparison array, the comparison results feed minimum-selection logic, and the winning index drives the output centroid mapper while metadata is delayed in parallel to maintain cycle alignment.

I can turn this into a formatted `.docx` design chapter file.
