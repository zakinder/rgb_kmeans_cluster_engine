# Pixel Stream Control and Metadata Handling

**Designer Name:** Sakinder Ali  
**Module Context:** `rgb_kmeans_cluster_engine`

---

## 1. Purpose

The pixel stream metadata path preserves video timing and pixel-position information while the RGB datapath performs centroid classification. The output metadata must remain aligned with the clustered RGB value that corresponds to the original input pixel.

---

## 2. Metadata Fields

The `channel` record is expected to carry RGB values and stream-control fields such as:

| Field | Purpose |
|---|---|
| `valid` | Indicates that the current pixel sample is meaningful. |
| `sof` | Marks the first valid pixel of a frame. |
| `eol` | Marks the final valid pixel of a line. |
| `eof` | Marks the final valid pixel of a frame. |
| `xcnt` | Horizontal pixel coordinate. |
| `ycnt` | Vertical pixel coordinate. |
| `red` | Red color component. |
| `green` | Green color component. |
| `blue` | Blue color component. |

---

## 3. Metadata Alignment Requirement

The clustering datapath introduces latency. Therefore, metadata must be delayed by the exact same number of clock cycles as the RGB result.

```text
metadata_delay = datapath_latency
```

For an input pixel sampled at cycle `t0`:

```text
input RGB      @ t0
input metadata @ t0
output RGB     @ t0 + L_total
output metadata@ t0 + L_total
```

---

## 4. Valid Signal Handling

The `valid` signal defines when the RGB fields are meaningful.

Rules:

1. If `pixel_in_rgb.valid = 1`, the output valid must assert after the documented latency.
2. If an invalid bubble enters the pipeline, the invalid bubble must propagate through the metadata path.
3. Output RGB should only be consumed when `pixel_out_rgb.valid = 1`.

---

## 5. Frame and Line Boundary Handling

Boundary markers must stay attached to the correct clustered pixel.

| Signal | Required Behavior |
|---|---|
| `sof` | Appears with the clustered first pixel of the frame. |
| `eol` | Appears with the clustered final pixel of the line. |
| `eof` | Appears with the clustered final pixel of the frame. |

Misalignment of these markers can corrupt downstream frame interpretation.

---

## 6. Coordinate Handling

Pixel coordinates must be delayed with the RGB result.

For an input pixel at:

```text
(xcnt, ycnt)
```

The clustered output pixel must carry the same coordinates after the pipeline delay:

```text
pixel_out_rgb.xcnt = delayed(pixel_in_rgb.xcnt)
pixel_out_rgb.ycnt = delayed(pixel_in_rgb.ycnt)
```

---

## 7. Metadata Pipeline Structure

A metadata delay line may be implemented as a sequence of registers:

```text
metadata_stage_0 <= input metadata
metadata_stage_1 <= metadata_stage_0
metadata_stage_2 <= metadata_stage_1
...
metadata_out     <= metadata_stage_N
```

Where:

```text
N = L_total
```

---

## 8. Reset Behavior

During reset:

- `valid` should be deasserted.
- boundary markers should be cleared.
- coordinate fields should be reset or held at known values.
- metadata pipeline registers should be flushed.

After reset release, metadata becomes meaningful only after the pipeline refills.

---

## 9. Verification Requirements

The metadata path should be verified with:

- single valid pixel pulse
- continuous valid stream
- invalid bubbles
- frame-start marker
- line-end marker
- frame-end marker
- coordinate ramp pattern
- reset during active stream

---

## 10. Summary

Pixel stream metadata handling is required for correct video-system behavior. The RGB classification result is only valid if the output control fields and coordinates describe the same pixel that was classified by the distance and centroid-selection datapath.
