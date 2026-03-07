## Functional Specifications: `pixel_in_rgb` and `pixel_out_rgb`

### Signal Type

Both signals use the `channel` record.

```vhdl
type channel is record
    valid : std_logic;
    sof   : std_logic;
    eol   : std_logic;
    eof   : std_logic;
    xcnt  : natural;
    ycnt  : natural;
    red   : std_logic_vector(7 downto 0);
    green : std_logic_vector(7 downto 0);
    blue  : std_logic_vector(7 downto 0);
end record;
```

---

# 1. `pixel_in_rgb`

## Signal Name

`pixel_in_rgb`

## Direction

Input

## Purpose

Carries the **incoming RGB pixel stream** into the clustering engine.

It includes:

* pixel control flags
* pixel coordinates
* pixel color channels

This is the main streaming video input to the module.

---

## Functional Role

`pixel_in_rgb` represents one pixel and its associated frame/line control information for each clock cycle.

It is used by the engine to:

* receive the current pixel
* compute distance to centroids
* determine the closest cluster
* preserve image timing and position information

---

## Field-Level Specification

### `valid`

#### Type

`std_logic`

#### Purpose

Indicates whether the current pixel data is valid.

#### Behavior

* `'1'` → pixel data is active and should be processed
* `'0'` → no valid pixel data on this cycle

#### Design Intent

Prevents invalid or idle cycles from being treated as image pixels.

---

### `sof`

#### Type

`std_logic`

#### Meaning

**Start of frame**

#### Purpose

Marks the first pixel of a new image frame.

#### Behavior

* asserted at the beginning of a frame
* propagated through the pipeline to maintain frame alignment

#### Design Intent

Used for frame synchronization and downstream image control.

---

### `eol`

#### Type

`std_logic`

#### Meaning

**End of line**

#### Purpose

Indicates that the current pixel is the last pixel of a video line.

#### Behavior

* asserted on the final pixel of each row
* helps downstream modules identify row boundaries

#### Design Intent

Supports raster scan timing and line-based processing.

---

### `eof`

#### Type

`std_logic`

#### Meaning

**End of frame**

#### Purpose

Indicates that the current pixel is the final pixel of the frame.

#### Behavior

* asserted on the last pixel of the image
* used for frame completion detection

#### Design Intent

Useful for counters, DMA control, frame buffering, and validation.

---

### `xcnt`

#### Type

`natural`

#### Purpose

Horizontal pixel coordinate.

#### Behavior

Represents the x-position of the current pixel in the frame.

Example:

* leftmost pixel → `xcnt = 0`
* next pixel → `xcnt = 1`

#### Design Intent

Allows spatial awareness in the processing pipeline.

---

### `ycnt`

#### Type

`natural`

#### Purpose

Vertical pixel coordinate.

#### Behavior

Represents the y-position of the current pixel in the frame.

Example:

* first row → `ycnt = 0`
* second row → `ycnt = 1`

#### Design Intent

Supports spatially aware processing and debug traceability.

---

### `red`

#### Type

`std_logic_vector(7 downto 0)`

#### Purpose

Red channel intensity of the current input pixel.

#### Range

`0` to `255`

#### Design Intent

One of the three color components used in centroid distance computation.

---

### `green`

#### Type

`std_logic_vector(7 downto 0)`

#### Purpose

Green channel intensity of the current input pixel.

#### Range

`0` to `255`

#### Design Intent

Used in RGB distance comparison.

---

### `blue`

#### Type

`std_logic_vector(7 downto 0)`

#### Purpose

Blue channel intensity of the current input pixel.

#### Range

`0` to `255`

#### Design Intent

Used in RGB distance comparison.

---

## Functional Summary

`pixel_in_rgb` provides the full input pixel context:

* whether the pixel is valid
* where it is in the frame
* whether it marks start/end boundaries
* what its RGB value is

---

# 2. `pixel_out_rgb`

## Signal Name

`pixel_out_rgb`

## Direction

Output

## Purpose

Carries the **processed output pixel stream** from the clustering engine.

The output pixel typically contains:

* propagated timing/control fields from the input
* RGB value replaced by the selected centroid color

---

## Functional Role

`pixel_out_rgb` is the clustered version of `pixel_in_rgb`.

The engine:

1. reads the incoming pixel color
2. compares it against all centroid entries
3. selects the nearest centroid
4. outputs that centroid RGB value on `pixel_out_rgb`

Control and coordinate fields are preserved.

---

## Output Field Behavior

### `valid`

Propagated from `pixel_in_rgb.valid`.

#### Purpose

Indicates whether the output pixel is valid.

#### Behavior

* `'1'` → output pixel is meaningful
* `'0'` → output is not active

---

### `sof`

Propagated from input.

#### Purpose

Marks the first pixel of a frame at the output of the clustering engine.

#### Design Intent

Maintains synchronization across the image-processing pipeline.

---

### `eol`

Propagated from input.

#### Purpose

Marks the last pixel of a line at the module output.

#### Design Intent

Preserves line timing alignment.

---

### `eof`

Propagated from input.

#### Purpose

Marks the final pixel of the frame at output.

#### Design Intent

Preserves frame boundary timing.

---

### `xcnt`

Propagated from input.

#### Purpose

Maintains horizontal location of the processed pixel.

#### Design Intent

Allows downstream modules to know where the clustered pixel belongs in the image.

---

### `ycnt`

Propagated from input.

#### Purpose

Maintains vertical location of the processed pixel.

#### Design Intent

Preserves spatial information.

---

### `red`

#### Purpose

Red channel of the selected centroid.

#### Behavior

Set to the red component of the nearest cluster centroid.

---

### `green`

#### Purpose

Green channel of the selected centroid.

#### Behavior

Set to the green component of the nearest cluster centroid.

---

### `blue`

#### Purpose

Blue channel of the selected centroid.

#### Behavior

Set to the blue component of the nearest cluster centroid.

---

## Functional Transformation

### Input Pixel

```text
pixel_in_rgb = (R,G,B)
```

### Processing

Compute distance from input pixel to each centroid:

```text
D(i) = |R - Ri| + |G - Gi| + |B - Bi|
```

Select centroid with minimum distance:

```text
best_cluster = argmin(D(i))
```

### Output Pixel

```text
pixel_out_rgb.red   = centroid(best_cluster).red
pixel_out_rgb.green = centroid(best_cluster).green
pixel_out_rgb.blue  = centroid(best_cluster).blue
```

All timing and position fields are forwarded.

---

# 3. Input/Output Relationship

| Field   | `pixel_in_rgb`       | `pixel_out_rgb`         |
| ------- | -------------------- | ----------------------- |
| `valid` | input control        | propagated              |
| `sof`   | input control        | propagated              |
| `eol`   | input control        | propagated              |
| `eof`   | input control        | propagated              |
| `xcnt`  | input coordinate     | propagated              |
| `ycnt`  | input coordinate     | propagated              |
| `red`   | original pixel red   | selected centroid red   |
| `green` | original pixel green | selected centroid green |
| `blue`  | original pixel blue  | selected centroid blue  |

---

# 4. Design Intent

## `pixel_in_rgb`

Represents the raw streaming video pixel entering the clustering engine.

## `pixel_out_rgb`

Represents the clustered video pixel leaving the engine, with its color quantized to the nearest centroid.

This preserves:

* frame timing
* line timing
* pixel position

while transforming:

* pixel color

---

# 5. Document-Ready Functional Text

### `pixel_in_rgb`

`pixel_in_rgb` is the input video pixel record for the K-means clustering engine. It contains the incoming RGB pixel value along with streaming control signals such as valid, start-of-frame, end-of-line, end-of-frame, and pixel coordinates. The signal provides the complete context required for pixel-by-pixel clustering in a raster video stream.

### `pixel_out_rgb`

`pixel_out_rgb` is the output video pixel record from the K-means clustering engine. It preserves the input control and coordinate fields while replacing the original pixel RGB value with the RGB value of the nearest centroid. This produces a clustered or quantized output image suitable for segmentation and color reduction applications.

---

# 6. Recommended Clearer Names

| Current Name    | Recommended Name      |
| --------------- | --------------------- |
| `pixel_in_rgb`  | `input_pixel`         |
| `pixel_out_rgb` | `clustered_pixel_out` |

Best engineering naming:

* `input_pixel`
* `clustered_pixel_out`

because they describe function more directly.

---

# 7. Short Engineering Definitions

### `pixel_in_rgb`

Input streaming RGB pixel with control and coordinate metadata.

### `pixel_out_rgb`

Output streaming RGB pixel after centroid-based clustering, with control and coordinate metadata preserved.

I can next turn all of these signal specifications into a **single clean requirements/specification section** for your design document.
