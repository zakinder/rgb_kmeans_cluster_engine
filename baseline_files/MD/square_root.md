## Functional Specification: `square_root`

### Module Name

`square_root`

### Purpose

`square_root` computes the **integer square root** of an input value.

It is used in hardware datapaths where a square-root result is required for:

* distance magnitude calculation
* normalization
* geometric or image-processing operations
* Euclidean metric support

The module is intended for **synchronous FPGA implementation**.

---

## Functional Role in the System

`square_root` is a **mathematical processing block** that converts an input operand into its square-root result.

Given an unsigned input value:

```text
X
```

the module computes:

```text
Y = floor(sqrt(X))
```

where `Y` is the integer square root.

This means the output is the largest integer such that:

```text
Y^2 <= X
```

---

## Interface Summary

### Generic

* `data_width`
  Defines the width of the input operand.

### Inputs

* `clk`
  System clock.

* `rst_n`
  Active-low reset.

* `radicand_in`
  Input value whose square root is to be computed.

### Output

* `root_out`
  Integer square-root result.

---

## Representative Interface

```vhdl
entity square_root is
   generic (
      data_width : integer := 32
   );
   port (
      clk         : in  std_logic;
      rst_n       : in  std_logic;
      radicand_in : in  std_logic_vector(data_width-1 downto 0);
      root_out    : out std_logic_vector((data_width/2)-1 downto 0)
   );
end entity square_root;
```

---

# 1. High-Level Functional Behavior

The module:

1. receives an input value `radicand_in`
2. applies an integer square-root algorithm
3. produces the corresponding root on `root_out`
4. updates the result synchronously with the clock

The result width is half the input width because:

```text
sqrt(2^N) ≈ 2^(N/2)
```

So a `data_width`-bit input produces a `(data_width/2)`-bit root.

---

# 2. Mathematical Definition

For input:

```text
X = radicand_in
```

the module computes:

```text
root_out = floor(sqrt(X))
```

This is the integer square root, not a floating-point result.

---

## Example

If:

```text
X = 144
```

then:

```text
root_out = 12
```

If:

```text
X = 150
```

then:

```text
root_out = 12
```

because:

```text
12^2 = 144
13^2 = 169
```

and `12` is the largest integer whose square does not exceed `150`.

---

# 3. Functional Decomposition

## 3.1 Input Capture

The module accepts `radicand_in` as the value to be processed.

This input is interpreted as an unsigned binary number.

---

## 3.2 Square-Root Computation

The module performs an iterative square-root computation.

Typical hardware approaches include:

* restoring square-root algorithm
* non-restoring square-root algorithm
* bit-pair iterative method
* pipelined compare/subtract approach

From your refined design style, the implementation is consistent with a **bit-pair iterative square-root pipeline**.

---

## 3.3 Root Generation

At the end of the computation, the module produces the square-root value on `root_out`.

This value is an integer approximation with truncation toward zero.

---

# 4. Algorithmic Behavior

A common bitwise square-root hardware method works as follows:

1. take the radicand in groups of 2 bits
2. shift partial remainder
3. form trial divisor/candidate
4. compare trial against partial remainder
5. subtract if valid
6. shift root and insert next result bit
7. repeat until all bit pairs are processed

This produces the integer square root efficiently in hardware.

---

# 5. Signal-Level Behavior

## 5.1 `clk`

System clock for synchronous operation.

The square-root datapath updates on the rising edge of `clk`.

---

## 5.2 `rst_n`

Active-low reset.

When asserted low:

* internal pipeline/state registers are cleared
* output result is reset to zero or default state

---

## 5.3 `radicand_in`

Unsigned input operand.

Represents the value whose square root is required.

### Functional meaning

```text
radicand_in = X
```

---

## 5.4 `root_out`

Output square-root result.

Represents:

```text
root_out = floor(sqrt(radicand_in))
```

---

# 6. Timing Behavior

## Clocking

The design is synchronous to `clk`.

## Reset

When `rst_n = '0'`:

* internal computation state is reset
* output is cleared

## Latency

Latency depends on implementation style.

### Possible styles

* **fully combinational**: minimal cycle latency, larger logic depth
* **iterative sequential**: one or more cycles per bit pair
* **pipelined**: fixed multi-cycle latency, high throughput

Your refined version suggests a **pipeline-oriented implementation**, which is suitable for FPGA timing closure.

---

# 7. Throughput Behavior

Depending on the architecture, the module may support:

### Iterative Mode

* one input processed across multiple cycles
* lower resource use

### Pipelined Mode

* one new input accepted every clock
* output appears after fixed latency
* higher throughput

For FPGA image-processing systems, pipelined square-root blocks are preferred when root computation is in the critical streaming path.

---

# 8. Numerical Characteristics

## Input Type

Unsigned integer value.

## Output Type

Unsigned integer square root.

## Rounding Behavior

The module returns the **truncated integer result**:

```text
floor(sqrt(X))
```

It does not return:

* fractional root
* rounded floating-point value
* exact irrational result

---

## Maximum Output Width

For input width `N`, output width is typically:

```text
N / 2
```

Example:

* 32-bit input → 16-bit output
* 16-bit input → 8-bit output

---

# 9. Example Calculations

## Example 1

Input:

```text
radicand_in = 0
```

Output:

```text
root_out = 0
```

---

## Example 2

Input:

```text
radicand_in = 1
```

Output:

```text
root_out = 1
```

---

## Example 3

Input:

```text
radicand_in = 15
```

Output:

```text
root_out = 3
```

because:

```text
3^2 = 9
4^2 = 16
```

---

## Example 4

Input:

```text
radicand_in = 16
```

Output:

```text
root_out = 4
```

---

## Example 5

Input:

```text
radicand_in = 255
```

Output:

```text
root_out = 15
```

because:

```text
15^2 = 225
16^2 = 256
```

---

# 10. Role in Image / Clustering Systems

`square_root` is useful when the system uses **Euclidean distance** rather than Manhattan distance.

For example, if color distance is computed as:

```text
D = sqrt((R-Rc)^2 + (G-Gc)^2 + (B-Bc)^2)
```

then `square_root` may be used after summing squared differences.

This allows:

* more geometrically accurate distance measurement
* magnitude extraction from squared error terms
* normalization in image-processing pipelines

---

# 11. Relationship to Other Modules

| Module                      | Relationship                                                           |
| --------------------------- | ---------------------------------------------------------------------- |
| `rgb_cluster_core`          | may provide distance components or partial sums                        |
| `rgb_kmeans_cluster_engine` | may use square-root result for Euclidean-distance clustering           |
| image-processing datapath   | may use root value for filtering, feature extraction, or normalization |

---

# 12. Functional Constraints

## Assumptions

* input is non-negative
* input is treated as unsigned
* `data_width` is even, or output sizing is defined accordingly

## Output Constraint

`root_out` must be wide enough to hold the maximum square root of the input range.

For a `data_width = 32` input:

```text
max input = 2^32 - 1
max root  ≈ 65535
```

which fits in 16 bits.

---

# 13. Design Intent

The module is intended to provide:

* deterministic hardware square-root computation
* FPGA-friendly implementation
* synthesizable arithmetic
* reusable mathematical support block

It avoids:

* floating-point dependency
* vendor-specific IP requirement
* software-style iterative loops at system level

---

# 14. Advantages

* synthesizable in standard VHDL
* deterministic latency
* reusable for many datapaths
* suitable for FPGA pipelines
* portable across tools when using IEEE libraries

---

# 15. Limitations

* integer result only
* no fractional precision
* latency depends on pipeline/iteration depth
* Euclidean use is more resource-intensive than Manhattan-only comparison

---

# 16. Recommended Clearer Naming

| Current Name  | Recommended Name      |
| ------------- | --------------------- |
| `square_root` | `integer_square_root` |
| `square_root` | `sqrt_core`           |
| `square_root` | `sqrt_pipeline`       |

Best option:

```vhdl
integer_square_root
```

because it clearly communicates that the block computes the integer form of the square root.

---

# 17. Document-Ready Functional Description

`square_root` is a synchronous hardware module that computes the integer square root of an unsigned input operand. It receives the radicand value on `radicand_in`, processes the value using a synthesizable square-root algorithm, and returns the truncated square-root result on `root_out`. The module is parameterized by input width and is intended for FPGA datapaths requiring root magnitude computation, such as Euclidean distance evaluation and image-processing arithmetic.

---

# 18. Short Engineering Definition

`square_root` is a synchronous integer square-root computation block for FPGA arithmetic datapaths.

---

# 19. Summary

`square_root`:

* accepts an unsigned input value
* computes integer square root
* outputs truncated root result
* supports synchronous FPGA operation
* is suitable for distance and magnitude calculations

I can combine the full specifications for **`square_root`, `rgb_cluster_core`, and `rgb_kmeans_cluster_engine`** into one polished **design-specification chapter**.
