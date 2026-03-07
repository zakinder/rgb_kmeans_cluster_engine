## Functional Specification: **Pixel Stream Control and Metadata Handling**

### Module Context

Used across:

* `rgb_cluster_core`
* `rgb_kmeans_cluster_engine`
* output pixel generation path

### Purpose

The **Pixel Stream Control and Metadata Handling** logic preserves the structural integrity of the video stream while pixel colors are being processed by the clustering pipeline.

Its job is to ensure that:

* valid pixel timing is preserved
* frame boundaries remain correct
* line boundaries remain correct
* pixel coordinates remain aligned
* clustered RGB output corresponds to the correct input pixel

This logic is essential for a streaming FPGA image-processing system.

---

# 1. Functional Objective

For every input pixel record, the control-handling logic must preserve and correctly propagate:

* `valid`
* `sof`
* `eol`
* `eof`
* `xcnt`
* `ycnt`

while allowing the RGB payload to be transformed by the clustering pipeline.

In short:

```text
control/metadata = preserved
RGB payload      = processed
```

---

# 2. Channel Record Context

Typical pixel record:

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

This record contains two categories of information:

## A. Control / Metadata Fields

* `valid`
* `sof`
* `eol`
* `eof`
* `xcnt`
* `ycnt`

## B. Pixel Payload Fields

* `red`
* `green`
* `blue`

The clustering engine modifies the payload, not the stream structure.

---

# 3. Control Signal Definitions

## `valid`

Indicates whether the current pixel record is active and meaningful.

### Functional meaning

* `'1'` → current pixel is valid and should be processed
* `'0'` → current cycle carries no valid pixel data

### Design requirement

All processing results must remain aligned with the corresponding `valid` state.

---

## `sof`

Start of frame.

### Functional meaning

Identifies the first valid pixel of a frame.

### Design requirement

Must propagate through the pipeline aligned with the same pixel that began the frame.

---

## `eol`

End of line.

### Functional meaning

Identifies the last pixel in the current line.

### Design requirement

Must remain aligned with the final pixel of that row after clustering.

---

## `eof`

End of frame.

### Functional meaning

Identifies the final pixel of the frame.

### Design requirement

Must propagate correctly to the clustered output stream.

---

## `xcnt`

Horizontal pixel coordinate.

### Functional meaning

Tracks pixel column position.

### Design requirement

Must remain associated with the same pixel after processing.

---

## `ycnt`

Vertical pixel coordinate.

### Functional meaning

Tracks pixel row position.

### Design requirement

Must remain associated with the same pixel after processing.

---

# 4. Functional Behavior

## Step 1 — Receive Input Pixel Record

The pipeline receives one input pixel record:

```text
pixel_in_rgb
```

containing both metadata and RGB values.

---

## Step 2 — Process RGB Payload

The clustering logic operates only on the color channels:

```text
red
green
blue
```

These channels are used for:

* distance computation
* centroid comparison
* cluster selection
* output color generation

---

## Step 3 — Forward Metadata

The control and coordinate fields are forwarded unchanged:

```text
pixel_out_rgb.valid = pixel_in_rgb.valid
pixel_out_rgb.sof   = pixel_in_rgb.sof
pixel_out_rgb.eol   = pixel_in_rgb.eol
pixel_out_rgb.eof   = pixel_in_rgb.eof
pixel_out_rgb.xcnt  = pixel_in_rgb.xcnt
pixel_out_rgb.ycnt  = pixel_in_rgb.ycnt
```

---

## Step 4 — Align Metadata with Processed RGB

If the RGB datapath introduces latency, then the metadata must be delayed by the same number of cycles.

This is one of the most important functional requirements.

---

# 5. Metadata Alignment Requirement

If RGB processing takes `N` pipeline stages, then metadata must also be delayed by `N` stages.

### Required behavior

For a pixel entering at cycle `t`:

* input metadata at cycle `t`
* processed RGB available at cycle `t + N`

Therefore:

* output metadata for that same pixel must also appear at cycle `t + N`

---

## Example

Assume:

* clustering datapath latency = 3 cycles

Then:

* pixel color result appears 3 clocks later
* `valid`, `sof`, `eol`, `eof`, `xcnt`, `ycnt` must also appear 3 clocks later

---

# 6. Pipeline Delay Model

## Input Cycle

```text
cycle 0:
pixel_in_rgb = pixel A
```

## Internal Processing

```text
cycle 1: distance stage
cycle 2: minimum select stage
cycle 3: centroid output stage
```

## Output Cycle

```text
cycle 3:
pixel_out_rgb = clustered version of pixel A
```

Metadata must track the same path.

---

# 7. Control Path Implementation

The control path is typically implemented using pipeline registers.

### Example conceptual structure

```text
valid_pipe(0) <= pixel_in_rgb.valid
valid_pipe(1) <= valid_pipe(0)
valid_pipe(2) <= valid_pipe(1)
...
```

Similarly for:

* `sof`
* `eol`
* `eof`
* `xcnt`
* `ycnt`

At the final stage:

```text
pixel_out_rgb.valid <= valid_pipe(N)
pixel_out_rgb.sof   <= sof_pipe(N)
pixel_out_rgb.eol   <= eol_pipe(N)
pixel_out_rgb.eof   <= eof_pipe(N)
pixel_out_rgb.xcnt  <= xcnt_pipe(N)
pixel_out_rgb.ycnt  <= ycnt_pipe(N)
```

---

# 8. Functional Rules

## Rule 1 — Preserve Stream Structure

Clustering must not alter:

* frame length
* line length
* pixel order

---

## Rule 2 — Preserve Pixel Coordinates

`xcnt` and `ycnt` must still point to the same spatial pixel after RGB transformation.

---

## Rule 3 — Preserve Control Event Timing

`sof`, `eol`, and `eof` must remain attached to the correct pixels.

---

## Rule 4 — Preserve Validity

An invalid input cycle must not become a valid output pixel unless explicitly designed otherwise.

---

## Rule 5 — Maintain Cycle Alignment

Metadata and clustered RGB must always refer to the same pixel record.

---

# 9. Example Operation

## Input Pixel Record

```text
valid = 1
sof   = 0
eol   = 0
eof   = 0
xcnt  = 25
ycnt  = 10
RGB   = (100,120,140)
```

## After Clustering

Suppose selected centroid is:

```text
(105,122,138)
```

## Output Pixel Record

```text
valid = 1
sof   = 0
eol   = 0
eof   = 0
xcnt  = 25
ycnt  = 10
RGB   = (105,122,138)
```

Only the color changed. The metadata stayed aligned.

---

# 10. Start/End Boundary Handling

## Start of Frame (`sof`)

Must mark the first clustered pixel of the frame.

## End of Line (`eol`)

Must mark the final clustered pixel of each row.

## End of Frame (`eof`)

Must mark the final clustered pixel of the frame.

If any of these markers shift relative to RGB output, downstream modules may misinterpret the image.

---

# 11. Valid Signal Handling

## Valid Input Pixel

When:

```text
valid = 1
```

the pixel participates in clustering.

## Invalid Cycle

When:

```text
valid = 0
```

the design should typically:

* suppress meaningful RGB output, or
* propagate invalid metadata consistently

Recommended behavior:

* preserve invalid cycle spacing through the pipeline

---

# 12. Coordinate Handling

## `xcnt`

Tracks horizontal position.

## `ycnt`

Tracks vertical position.

These coordinates are especially important for:

* debug
* spatial masking
* region-of-interest logic
* downstream overlays
* verification

They must remain paired with the correct clustered pixel.

---

# 13. Error Conditions if Misaligned

If metadata is not aligned with RGB output, the following issues may occur:

* frame boundary errors
* line boundary corruption
* pixel coordinate mismatch
* shifted image artifacts
* invalid debug traces
* broken downstream processing

This makes metadata handling a critical part of the design, not just an auxiliary feature.

---

# 14. Design Intent

The control and metadata path is designed to ensure that RGB clustering behaves as a **transparent transformation** on the pixel color stream, without disturbing the raster structure of the video.

The system should behave like this:

```text
same pixel timing
same pixel position
new clustered color
```

---

# 15. Advantages

* preserves stream integrity
* supports downstream video modules
* enables debug and traceability
* keeps clustering pipeline deterministic
* simplifies system integration

---

# 16. Limitations

* every added RGB pipeline stage requires matching metadata delay
* misalignment bugs can be hard to debug
* coordinate widths and counter ranges must be chosen carefully

---

# 17. Recommended Implementation Style

Use explicit pipeline registers for all metadata fields whenever RGB datapath latency is greater than zero.

Best practice:

* keep RGB path latency documented
* keep control path latency identical
* verify alignment in simulation with frame markers

---

# 18. Verification Requirements

The design should verify that:

* `sof` emerges with the first clustered pixel
* `eol` emerges with the final clustered pixel of each line
* `eof` emerges with the last clustered pixel of the frame
* `xcnt/ycnt` at output match the transformed pixel location
* `valid` alignment is preserved across pipeline stages

---

# 19. Document-Ready Functional Description

The Pixel Stream Control and Metadata Handling logic preserves the structural information of the input video stream while the RGB payload is processed by the clustering engine. It forwards and, when necessary, pipelines the valid flag, frame and line boundary markers, and pixel coordinates so that they remain cycle-aligned with the clustered output RGB data. This ensures that the output stream preserves the original raster timing and spatial context of the input image.

---

# 20. Short Engineering Definition

Pixel Stream Control and Metadata Handling preserves video timing, coordinates, and validity alignment across the clustering pipeline.

---

# 21. Summary

This logic:

* preserves `valid`, `sof`, `eol`, `eof`, `xcnt`, `ycnt`
* delays metadata to match RGB pipeline latency
* keeps output stream structurally identical to input stream
* ensures clustered RGB belongs to the correct pixel

The next logical section is **Functional Specification: Pipeline Timing and Latency**.
