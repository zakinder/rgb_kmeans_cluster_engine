## Functional Specification: `threshold_lms`

### Signal Name

`threshold_lms`

### Direction

Most likely **output** or **internal signal**, depending on where it is declared in your design.

Typical forms:

```vhdl
signal threshold_lms : integer;
```

or

```vhdl
threshold_lms : out integer
```

---

## Purpose

`threshold_lms` represents the **distance or threshold result computed in the LMS color domain**.

It is used to measure how closely an input pixel matches a reference value after converting or interpreting the color in **LMS space**.

---

## Meaning of LMS

In image and color processing, **LMS** usually refers to three components associated with cone-response style channels:

* `L` = long wavelength response
* `M` = medium wavelength response
* `S` = short wavelength response

In FPGA/image-processing design, LMS is often used as an alternative color space for:

* color separation
* perceptual comparison
* improved segmentation
* biologically inspired color analysis

---

## Functional Role

`threshold_lms` is the similarity or distance metric computed between:

* the current pixel represented in LMS space
* a reference LMS centroid, LUT entry, or comparison target

It is the LMS-domain equivalent of an RGB-domain threshold such as:

```text
threshold = |R - Rc| + |G - Gc| + |B - Bc|
```

but performed using LMS values instead.

---

## Typical Behavior

### Conceptual LMS Distance

A common implementation would be:

```text
threshold_lms = |L - Lc| + |M - Mc| + |S - Sc|
```

Where:

* `L, M, S` are the input pixel LMS components
* `Lc, Mc, Sc` are the reference centroid LMS components

This produces one scalar threshold value.

---

## Purpose in the Architecture

`threshold_lms` is used to determine whether the current pixel is:

* close to a target LMS centroid
* within a specified LMS similarity range
* more similar to one LMS cluster than another

It can support:

* cluster comparison
* color segmentation
* classification
* centroid selection
* threshold-based mask generation

---

## Functional Interpretation

* **small `threshold_lms`** → strong LMS similarity
* **large `threshold_lms`** → weak LMS similarity

The smaller the threshold, the closer the pixel is to the LMS reference.

---

## Likely Use Cases

### 1. LMS-Based Clustering

If your design compares pixels in LMS space instead of RGB, `threshold_lms` is the distance metric used for cluster selection.

### 2. Perceptual Color Segmentation

LMS can better separate colors in ways closer to visual response.
`threshold_lms` can therefore be used to classify pixels based on perceptual color distance.

### 3. Multi-Color-Space Decision Logic

If your architecture computes thresholds in several spaces, such as:

* RGB
* HSV
* LMS

then `threshold_lms` is the LMS-branch result used by a later selection stage.

---

## Data Type

Most likely:

```vhdl
integer
```

Possible alternatives:

* `unsigned`
* `natural`
* fixed-point type

If absolute-difference arithmetic is used, `integer` is the most common simple form.

---

## Timing Behavior

`threshold_lms` may be generated:

### Combinationally

If LMS difference is computed directly from current signal values.

### Sequentially

If LMS values are pipelined and threshold generation occurs inside a clocked process.

In streaming FPGA pipelines, it is commonly registered for timing closure.

---

## Relation to Other Signals

| Related Signal             | Relationship                             |
| -------------------------- | ---------------------------------------- |
| `pixel_in_rgb`             | source pixel before conversion           |
| `lms_*` signals            | input LMS components used in computation |
| `k_rgb_lut` / centroid LUT | possible source of reference color       |
| `threshold`                | RGB-domain comparison metric             |
| `threshold_lms`            | LMS-domain comparison metric             |
| cluster select logic       | uses threshold to choose best class      |

---

## Typical Functional Flow

### Step 1: Convert Pixel to LMS

Input RGB pixel is transformed into LMS components.

### Step 2: Select Reference LMS Target

Reference centroid or LUT value is selected in LMS space.

### Step 3: Compute LMS Distance

Absolute channel-wise differences are summed or otherwise combined.

### Step 4: Produce `threshold_lms`

This value is passed to decision logic, comparator trees, or threshold windows.

---

## Example

Assume:

```text
Input LMS     = (120, 85, 40)
Reference LMS = (110, 80, 55)
```

Then:

```text
threshold_lms = |120-110| + |85-80| + |40-55|
              = 10 + 5 + 15
              = 30
```

Result:

* threshold = 30
* pixel is moderately close to the reference LMS color

---

## Design Intent

`threshold_lms` exists to support color comparison in an LMS-based domain rather than only in RGB.

Benefits may include:

* improved perceptual matching
* stronger separation for certain object classes
* alternative clustering metric
* more flexible color analysis pipeline

---

## Engineering Definition

`threshold_lms` = **LMS-domain color distance metric**

---

## Document-Ready Functional Description

`threshold_lms` is the LMS color-space distance output used by the clustering or segmentation logic. It represents the difference between the LMS components of the current input pixel and a reference LMS value, centroid, or threshold target. Lower values indicate a closer match in LMS space, while higher values indicate greater color separation.

---

## Recommended Clearer Names

| Current Name    | Recommended Name     |
| --------------- | -------------------- |
| `threshold_lms` | `lms_distance`       |
| `threshold_lms` | `lms_color_distance` |
| `threshold_lms` | `lms_match_error`    |

Best choice:

```vhdl
lms_color_distance
```

because it clearly states:

* LMS domain
* color-based comparison
* distance meaning

---

## If Used for Threshold Decision Instead of Distance

In some designs, `threshold_lms` may represent not the raw distance, but the **decision threshold limit** in LMS space.

In that case its meaning becomes:

* maximum allowed LMS distance for a valid match
* threshold constant used in comparison logic

Example:

```vhdl
if lms_distance <= threshold_lms then
    match <= '1';
else
    match <= '0';
end if;
```

So there are **two possible interpretations**:

### Interpretation A — Computed Result

`threshold_lms` = actual computed LMS distance

### Interpretation B — Reference Limit

`threshold_lms` = allowed LMS threshold constant/value

From the naming alone, both are possible. In your clustering style, the more likely meaning is **computed LMS distance result**, but if you share the declaration or code line, I can pin it down exactly.

---

## Short Specification

`threshold_lms` is the LMS-space threshold or distance value used to evaluate how closely an input pixel matches a reference color in the LMS domain.

I can also write the same level of specification for:

* `threshold_rgb`
* `threshold_hsv`
* `threshold_xyz`
* `threshold_ycbcr`

as one **multi-color-space threshold section**.
