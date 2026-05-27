# Pixel 35-Cycle Journey — From RGB Input to Final Output Mapper

**Designer Name:** Sakinder Ali  
**Repository:** `zakinder/rgb_kmeans_cluster_engine`  
**Document Type:** Student-Friendly Pipeline Narrative  
**Audience:** FPGA learners, digital-design students, image-processing students, early hardware engineers

---

## 1. Purpose

This document follows one pixel as it travels through a 35-cycle RGB clustering pipeline. The goal is to help a student understand how raw color data becomes an organized cluster decision inside hardware.

Instead of seeing the system as a confusing set of registers, lookup tables, and comparator logic, imagine one pixel moving through a carefully organized processing hallway. Each stage helps the pixel answer one question:

> Which known color group do I belong to?

By the end of the journey, the pixel is no longer just raw RGB data. It has been transformed into a selected cluster ID and mapped to the final output color.

---

## 2. The Pixel at the Starting Line

A pixel enters the system carrying three values:

```text
Red   = R
Green = G
Blue  = B
```

Together, these form the input color:

```text
Input Pixel = (R, G, B)
```

At this moment, the pixel is still unorganized. The hardware has not yet decided what group it belongs to. It only knows that the pixel has arrived and that its color must be compared against known reference colors.

This is where the 35-cycle journey begins.

---

## 3. High-Level View of the 35-Cycle Journey

The journey can be understood as five major stages:

| Stage | Approximate Cycle Region | Student-Friendly Meaning |
|---:|---|---|
| 1 | Cycles 0-4 | The pixel is intercepted, captured, and stabilized. |
| 2 | Cycles 5-11 | The pixel enters a neutral comparison space. |
| 3 | Cycles 12-21 | The pixel is measured against known centroid colors. |
| 4 | Cycles 22-30 | The comparator tree selects the closest color group. |
| 5 | Cycles 31-35 | The final output mapper assigns the cluster ID and output color. |

The exact cycle partition can vary by implementation, but the teaching idea is the same: the pixel moves through capture, normalization, measurement, decision, and mapping.

---

# Stage 1 — Cycles 0-4: RGB Input Capture and Stream Interception

The pixel first enters through the RGB input stream.

The hardware captures:

```text
R, G, B
```

It may also capture helpful stream information such as valid flags, frame markers, line markers, or pixel coordinates.

## What This Stage Does

This stage gives the pixel a stable starting point. Hardware pipelines need clean, synchronized data. If the red value belongs to one clock cycle and the green value belongs to another, the system would compare the wrong color.

So the first stage says:

> Let us hold this pixel still for a moment so the rest of the pipeline can work with one complete color sample.

## Why This Stage Matters

This stage is essential because every later calculation depends on the input being consistent. A clustering decision is only meaningful if all three color channels belong to the same pixel.

## Student Analogy

Think of a student entering a classroom and writing their name on an attendance sheet. Before the class can help them, the system must know exactly who arrived.

For the pixel, its identity is:

```text
(R, G, B)
```

---

# Stage 2 — Cycles 5-11: Neutral Space Interception

After the pixel is captured, it enters what we can call the **neutral space interception** stage.

This is a helpful learning phrase. It means the pixel is placed into a fair comparison zone where it can be measured against all candidate color groups without bias.

The pixel is not yet assigned to any cluster. It is temporarily held in a neutral state while the system prepares reference colors and comparison paths.

## What This Stage Does

The neutral space stage may organize or prepare:

- the input pixel value
- the active centroid profile
- delayed stream metadata
- comparison-ready RGB values
- internal pipeline alignment

In simple terms, the hardware is making sure the pixel and the known reference colors are ready to meet under the same rules.

## Why This Stage Matters

Without this stage, comparisons may happen too early, too late, or against the wrong profile. The neutral space protects the pixel journey by creating an orderly transition between raw input capture and mathematical comparison.

This stage answers:

> Are the pixel and the reference colors ready for a fair comparison?

## Student Analogy

Imagine a science fair where every project must be judged using the same checklist. The neutral space is like the preparation table where the judge gathers the project sheet, rubric, and scoring form before assigning a score.

The pixel is waiting patiently. It has not been judged yet, but it is now ready to be compared properly.

---

# Stage 3 — Cycles 12-21: Distance Computation Against Centroids

Now the pixel reaches the mathematical heart of the journey.

The system compares the pixel against known color centers called **centroids**.

A centroid is a representative color, such as:

```text
Centroid 0 = (R0, G0, B0)
Centroid 1 = (R1, G1, B1)
Centroid 2 = (R2, G2, B2)
...
```

The pixel asks each centroid:

> How close am I to you?

## What This Stage Does

For each centroid, the system measures color difference.

A simple hardware-friendly method is:

```text
Distance = |R - Rc| + |G - Gc| + |B - Bc|
```

Where:

```text
(R, G, B)    = input pixel
(Rc, Gc, Bc) = centroid color
```

The smaller the distance, the closer the pixel is to that centroid.

## Example

Input pixel:

```text
Pixel = (100, 120, 140)
```

Centroid:

```text
Centroid = (105, 122, 138)
```

Difference:

```text
Red difference   = |100 - 105| = 5
Green difference = |120 - 122| = 2
Blue difference  = |140 - 138| = 2
```

Total distance:

```text
Distance = 5 + 2 + 2 = 9
```

A distance of 9 means this centroid is very close to the input pixel.

## Why This Stage Matters

This stage transforms color into numbers that can be compared. Raw RGB values are not enough by themselves. The hardware needs a measurable way to decide which centroid is closest.

This stage answers:

> How far is this pixel from each known color group?

## Student Analogy

Imagine standing in a room with several friends and asking, “Who is closest to me?” You measure the distance to each person. The nearest person is your match.

Here, the pixel measures distance to each centroid. The closest centroid becomes the best color group.

---

# Stage 4 — Cycles 22-30: Comparator Tree and Cluster Decision

After the distance values are calculated, the pixel enters the comparator tree stage.

The comparator tree is like a tournament bracket. Each distance value competes against another distance value. The smaller distance wins and moves forward.

## What This Stage Does

Suppose the hardware has these distances:

```text
Distance to Centroid 0 = 30
Distance to Centroid 1 = 270
Distance to Centroid 2 = 9
Distance to Centroid 3 = 80
```

The comparator tree asks:

```text
Which distance is smallest?
```

The answer is:

```text
Distance 9
```

So the winning cluster is:

```text
Cluster ID = 2
```

## Why a Comparator Tree Is Used

A comparator tree is important because the hardware may need to compare many centroid distances quickly.

Instead of comparing everything in one long slow chain, the tree breaks the work into smaller decisions:

```text
Round 1: compare pairs
Round 2: compare winners
Round 3: select final winner
```

This helps the hardware stay fast and organized.

## Why This Stage Matters

This is the decision-making stage. Before this point, the hardware only had a list of distances. After this stage, the hardware knows which centroid won.

This stage answers:

> Which centroid is closest to the pixel?

## Student Analogy

Think of a sports tournament. Many teams enter, but only one team wins. The comparator tree runs a tournament where the smallest distance wins.

The prize is the cluster ID.

---

# Stage 5 — Cycles 31-35: Final Output Mapper

The pixel has now received a cluster ID. The final output mapper uses that cluster ID to assign the output color.

If:

```text
Cluster ID = 2
```

And:

```text
Centroid 2 = (105, 122, 138)
```

Then the output mapper produces:

```text
Output Pixel = (105, 122, 138)
```

## What This Stage Does

The final output mapper connects the decision to the visible result.

It takes:

```text
winning cluster ID
```

And maps it to:

```text
final output RGB color
```

It may also pass along delayed metadata so the output pixel still belongs to the correct frame position.

## Why This Stage Matters

The cluster ID is useful for classification, but video output often needs an RGB color. The final mapper turns the internal decision into a visible output.

This stage answers:

> Now that we know the winning cluster, what color should leave the system?

## Student Analogy

Imagine the pixel wins a badge that says “Cluster 2.” The output mapper looks at the badge and gives the pixel its final uniform color.

The pixel enters as one color and exits as the representative color of its assigned group.

---

## 4. The Complete 35-Cycle Story

The pixel begins as raw color data:

```text
Input Pixel = (R, G, B)
```

It is captured, stabilized, prepared in neutral space, compared against centroids, measured by distance, judged by a comparator tree, assigned a cluster ID, and mapped to a final output color.

```text
Cycle 0      : Pixel enters as RGB
Cycles 0-4   : Input capture and stream interception
Cycles 5-11  : Neutral space preparation
Cycles 12-21 : Distance computation against centroids
Cycles 22-30 : Comparator tree selects nearest centroid
Cycles 31-35 : Output mapper assigns cluster ID and output color
```

The final transformation is:

```text
Raw RGB Pixel -> Measured Distances -> Smallest Distance -> Cluster ID -> Output Color
```

---

## 5. Why Every Stage Is Essential

| Stage | Essential Role |
|---|---|
| RGB input capture | Ensures the pixel enters as one stable color sample. |
| Neutral space interception | Aligns the pixel and active profile for fair comparison. |
| Distance computation | Converts color similarity into measurable numbers. |
| Comparator tree | Finds the closest centroid efficiently. |
| Final output mapper | Converts the winning cluster ID into the final output color. |

Each stage protects the correctness of the next stage. If one stage is skipped or misaligned, the output may be wrong.

---

## 6. Encouraging Learning Note

At first, a 35-cycle pipeline may sound complex. But the idea becomes easier when you remember that the hardware is doing one careful job in several small steps.

It is not magic. It is a disciplined sequence:

```text
Capture -> Prepare -> Measure -> Choose -> Map
```

That is the heart of the RGB K-Means Cluster Engine.

The pixel is never lost. It is guided step by step until the hardware can confidently say:

> This pixel belongs to this cluster.

---

## 7. Final Takeaway

A single pixel's 35-cycle journey shows how FPGA hardware turns raw color into organized meaning. The pixel starts as three color numbers, travels through a fair comparison space, gets measured against known colors, passes through a tournament of distances, and exits with a clear cluster ID and assigned output color.

That is how raw RGB data becomes structured visual intelligence inside the hardware pipeline.
