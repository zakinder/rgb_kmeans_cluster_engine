## Functional Specifications

### 1. `centroid_lut_in`

#### Signal Name

`centroid_lut_in`

#### Direction

Input

```vhdl
centroid_lut_in : in std_logic_vector(23 downto 0)
```

#### Purpose

Carries the **RGB centroid value** that will be written into the centroid LUT.

#### Functional Role

This signal provides the centroid color data for one cluster entry.

Typical bit mapping:

```vhdl
centroid_lut_in(23 downto 16)  -- Red
centroid_lut_in(15 downto 8)   -- Green
centroid_lut_in(7 downto 0)    -- Blue
```

#### Behavior

When write conditions are satisfied, the selected LUT entry is loaded with this RGB value.

Example:

```vhdl
lut_mem(centroid_lut_select).red   <= unsigned(centroid_lut_in(23 downto 16));
lut_mem(centroid_lut_select).green <= unsigned(centroid_lut_in(15 downto 8));
lut_mem(centroid_lut_select).blue  <= unsigned(centroid_lut_in(7 downto 0));
```

#### Use Cases

* Initial centroid loading
* Runtime centroid update
* Reprogramming cluster color definitions

#### Design Intent

Provides a compact 24-bit interface for programming one centroid at a time.

#### Recommended Rename

`centroid_rgb_in`

---

### 2. `centroid_lut_out`

#### Signal Name

`centroid_lut_out`

#### Direction

Output

```vhdl
centroid_lut_out : out std_logic_vector(31 downto 0)
```

#### Purpose

Returns the RGB value stored in a selected centroid LUT entry.

#### Functional Role

Provides readback access to centroid memory for:

* debug
* status monitoring
* software readback
* verification

#### Behavior

In the portable version:

```vhdl
centroid_lut_out <= x"00" &
                    std_logic_vector(lut_mem(k_ind_r).red) &
                    std_logic_vector(lut_mem(k_ind_r).green) &
                    std_logic_vector(lut_mem(k_ind_r).blue);
```

Bit mapping:

```vhdl
centroid_lut_out(31 downto 24) -- reserved / zero padding
centroid_lut_out(23 downto 16) -- Red
centroid_lut_out(15 downto 8)  -- Green
centroid_lut_out(7 downto 0)   -- Blue
```

#### Use Cases

* Read centroid values after initialization
* Confirm correct centroid programming
* Observe adaptive centroid updates

#### Design Intent

Gives external logic visibility into LUT contents without directly exposing internal memory.

#### Recommended Rename

`centroid_rgb_out`

---

### 3. `k_ind_w`

#### Signal Name

`k_ind_w`

#### Direction

Input

```vhdl
k_ind_w : in natural
```

Portable constrained form:

```vhdl
k_ind_w : in natural range 0 to cluster_count-1
```

#### Purpose

Write-side centroid index control.

#### Functional Role

Identifies which centroid index is active for write operations.

In the current architecture, write occurs when:

```vhdl
if k_ind_w = centroid_lut_select then
```

So `k_ind_w` acts as a write qualifier or write-address confirmation signal.

#### Behavior

* If `k_ind_w` matches `centroid_lut_select`, centroid write is enabled
* If not, no LUT write occurs

#### Example

* `k_ind_w = 2`
* `centroid_lut_select = 2`
* `centroid_lut_in = x"804020"`

Result: centroid 2 gets updated

#### Use Cases

* controlled centroid programming
* external FSM write sequencing
* synchronized LUT update control

#### Design Intent

Separates write control from general selection logic.

#### Recommended Rename

`centroid_write_index`

---

### 4. `k_ind_r`

#### Signal Name

`k_ind_r`

#### Direction

Input

```vhdl
k_ind_r : in natural
```

Portable constrained form:

```vhdl
k_ind_r : in natural range 0 to cluster_count-1
```

#### Purpose

Read-side centroid index control.

#### Functional Role

Selects which centroid entry is returned on `centroid_lut_out`.

#### Behavior

Used as the read address into centroid LUT memory:

```vhdl
lut_mem(k_ind_r)
```

#### Example

If:

* `k_ind_r = 3`

Then:

* centroid 3 RGB value is placed on `centroid_lut_out`

#### Use Cases

* debugging centroid contents
* verification readback
* software status polling
* runtime inspection

#### Design Intent

Provides direct indexed access to stored centroid data.

#### Recommended Rename

`centroid_read_index`

---

## Relationship Between These Signals

These four signals work together as the centroid memory interface.

### Write Path

* `centroid_lut_select` chooses target centroid
* `k_ind_w` qualifies the write index
* `centroid_lut_in` supplies RGB centroid data

### Read Path

* `k_ind_r` selects centroid entry
* `centroid_lut_out` returns stored RGB value

---

## Simplified Functional Table

| Signal                | Direction | Function                                                |
| --------------------- | --------- | ------------------------------------------------------- |
| `centroid_lut_select` | Input     | Select centroid entry for configuration/write targeting |
| `centroid_lut_in`     | Input     | Provides RGB centroid data to write                     |
| `k_ind_w`             | Input     | Write index / write enable qualifier                    |
| `k_ind_r`             | Input     | Read index / centroid read address                      |
| `centroid_lut_out`    | Output    | Returns selected centroid RGB value                     |

---

## Recommended Cleaner Naming Set

| Current Name          | Recommended Name       |
| --------------------- | ---------------------- |
| `centroid_lut_select` | `centroid_index_sel`   |
| `centroid_lut_in`     | `centroid_rgb_in`      |
| `centroid_lut_out`    | `centroid_rgb_out`     |
| `k_ind_w`             | `centroid_write_index` |
| `k_ind_r`             | `centroid_read_index`  |

---

## Document-Ready Specification Text

### `centroid_lut_in`

`centroid_lut_in` is the 24-bit RGB input bus used to program centroid values in the K-means clustering engine. It carries one centroid color in packed RGB format, where bits `[23:16]` represent red, `[15:8]` represent green, and `[7:0]` represent blue.

### `centroid_lut_out`

`centroid_lut_out` is the centroid LUT readback bus. It outputs the stored centroid value selected by the read index input. The output is formatted as a 32-bit word with RGB data in the lower 24 bits.

### `k_ind_w`

`k_ind_w` is the centroid write index control signal. It identifies the centroid entry to be updated and is used with `centroid_lut_select` to qualify write operations into centroid memory.

### `k_ind_r`

`k_ind_r` is the centroid read index control signal. It selects which centroid entry is returned on the centroid LUT output bus for monitoring, debug, or verification.

---

## Engineering Note

The current write condition:

```vhdl
if k_ind_w = centroid_lut_select then
```

is valid, but somewhat redundant if both signals represent the same address space. A cleaner interface is often:

* one write enable
* one write address
* one read address
* one write data
* one read data

Example:

```vhdl
centroid_wr_en
centroid_wr_addr
centroid_rd_addr
centroid_rgb_in
centroid_rgb_out
```

That is cleaner for maintenance and documentation.

I can next write the **complete functional specifications for `pixel_in_rgb` and `pixel_out_rgb`**, including every field in the `channel` record.
