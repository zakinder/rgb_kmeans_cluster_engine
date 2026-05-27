# Pixel Journey Narrative — From Input Color to Clustered Output

**Designer Name:** Sakinder Ali  
**Repository:** `zakinder/rgb_kmeans_cluster_engine`  
**Document Type:** Learner-Friendly Technical Narrative  
**Audience:** Students, early FPGA learners, software engineers learning hardware image processing, technical readers new to RGB clustering

---

## 1. Purpose

This document explains the RGB K-Means Cluster Engine by following a single pixel through the system. Instead of starting with VHDL signals, registers, or mathematical notation, this guide tells the story of one pixel as it enters the hardware, gets compared against known colors, and leaves the system with a new assigned color.

The goal is to help a learner visualize what the hardware is doing.

---

## 2. The Pixel as a Traveler

Imagine one pixel entering the system as a small traveler carrying three numbers:

```text
Red   = 100
Green = 120
Blue  = 140
```

Together, these three numbers describe the pixel's color:

```text
Pixel Color = (100, 120, 140)
```

The hardware does not think about the pixel as a picture or object. It sees the pixel as a three-number color point.

The job of the RGB K-Means Cluster Engine is to ask:

> Which known color group is this pixel closest to?

Once the closest known color group is found, the pixel is assigned that group's color.

---

## 3. The Five Processing Stages

The pixel passes through five major stages:

```text
Stage 1: Enter the system
Stage 2: Meet the known color choices
Stage 3: Measure color difference
Stage 4: Pick the closest match
Stage 5: Leave with the new assigned color
```

Each stage performs one clear job.

---

# Stage 1 — The Pixel Enters the System

The pixel arrives from a camera, image stream, video frame, or another processing block.

It carries its original RGB color:

```text
Input Pixel = (100, 120, 140)
```

In simple terms, the hardware first says:

> I have received a pixel. I will remember its red, green, and blue values so I can compare it to known colors.

At this stage, the pixel has not changed. It is only captured and prepared for comparison.

## Learner View

Think of the pixel walking into a sorting room. It gives the system its color identity card:

```text
My red value is 100.
My green value is 120.
My blue value is 140.
```

The system now knows what color the pixel currently is.

---

# Stage 2 — The Pixel Meets the Known Color Choices

The system has a set of known colors stored inside it. These known colors are called **centroids**.

A centroid is simply a representative color. It acts like the center of a color group.

Example known colors:

```text
Known Color 0 = (90, 110, 150)
Known Color 1 = (200, 210, 220)
Known Color 2 = (105, 122, 138)
```

The pixel does not yet know which group it belongs to. It must compare itself with each known color.

## Learner View

Imagine the pixel standing in front of three color stations:

```text
Station 0: bluish-gray color
Station 1: bright pale color
Station 2: color very close to the pixel
```

The pixel will visit each station and ask:

> How different am I from this known color?

---

# Stage 3 — The System Measures Color Difference

Now the mathematical transformation begins.

The system compares the input pixel against each known color by checking the difference in red, green, and blue values.

For the input pixel:

```text
Pixel = (100, 120, 140)
```

And Known Color 0:

```text
Known Color 0 = (90, 110, 150)
```

The system measures:

```text
Red difference   = |100 - 90|  = 10
Green difference = |120 - 110| = 10
Blue difference  = |140 - 150| = 10
```

Then it adds those differences:

```text
Total difference = 10 + 10 + 10 = 30
```

So the distance from the pixel to Known Color 0 is:

```text
Distance to Known Color 0 = 30
```

The same process is repeated for every known color.

## Comparison Table

| Known Color | RGB Value | Difference Calculation | Total Difference |
|---|---|---|---:|
| Color 0 | `(90, 110, 150)` | `10 + 10 + 10` | `30` |
| Color 1 | `(200, 210, 220)` | `100 + 90 + 80` | `270` |
| Color 2 | `(105, 122, 138)` | `5 + 2 + 2` | `9` |

## Learner View

The system is not guessing. It is measuring closeness.

A smaller total difference means:

> This known color looks more like the pixel.

A larger total difference means:

> This known color is farther away from the pixel.

---

# Stage 4 — The Closest Match Is Selected

After measuring all differences, the system looks for the smallest number.

The measured distances were:

```text
Distance to Color 0 = 30
Distance to Color 1 = 270
Distance to Color 2 = 9
```

The smallest distance is:

```text
9
```

That means Known Color 2 is the closest match.

So the hardware decides:

```text
Winning Color = Known Color 2
Winning RGB   = (105, 122, 138)
```

## Learner View

The pixel has visited all stations. The system now says:

> You are closest to Station 2. You belong to that color group.

This is the clustering decision.

---

# Stage 5 — The Pixel Leaves with a New Assigned Color

The pixel entered the system as:

```text
Input Pixel = (100, 120, 140)
```

The closest known color was:

```text
Known Color 2 = (105, 122, 138)
```

So the output pixel becomes:

```text
Output Pixel = (105, 122, 138)
```

The pixel has now been assigned a new color based on the closest centroid.

## Learner View

The pixel walks out of the sorting room wearing the color label of the closest station.

It entered as:

```text
(100, 120, 140)
```

It leaves as:

```text
(105, 122, 138)
```

The pixel has been simplified or classified into a known color group.

---

## 4. Complete Journey Summary

```text
Input Pixel
    |
    v
Stage 1: Capture the pixel color
    |
    v
Stage 2: Compare against known color groups
    |
    v
Stage 3: Measure RGB differences
    |
    v
Stage 4: Select the smallest difference
    |
    v
Stage 5: Output the winning color
```

Using the example:

```text
Input Pixel  = (100, 120, 140)
Closest Match = (105, 122, 138)
Output Pixel = (105, 122, 138)
```

---

## 5. What the Hardware Is Really Doing

Although the story sounds simple, the hardware performs these steps very quickly.

For every pixel, it:

1. reads the RGB values
2. compares them with stored centroid colors
3. subtracts red, green, and blue values
4. converts those differences into positive distances
5. adds the differences together
6. finds the smallest total distance
7. outputs the closest centroid color

The important idea is:

> The hardware changes the pixel color by replacing it with the closest known color.

---

## 6. Why This Is Useful

This process is useful because it can simplify an image.

Instead of allowing millions of possible colors, the system can reduce the image to a smaller set of meaningful colors.

This helps with:

- color quantization
- image segmentation
- object-region detection
- industrial inspection
- robotics vision
- palette-based video processing
- real-time FPGA image classification

---

## 7. Simple Analogy

Imagine sorting colored marbles into buckets.

Each marble has a color. Each bucket has a label color.

For every marble, you ask:

```text
Which bucket color is closest to this marble color?
```

Then you place the marble into that bucket.

The RGB K-Means Cluster Engine does the same thing, but instead of marbles and buckets, it uses:

```text
pixels and centroid colors
```

---

## 8. The Mathematical Transformation in One Line

The system transforms the pixel like this:

```text
Original RGB pixel -> nearest known RGB centroid -> output clustered RGB pixel
```

Or:

```text
(100, 120, 140) -> closest to (105, 122, 138) -> (105, 122, 138)
```

---

## 9. Final Learning Point

The pixel does not randomly change color. It is assigned a new color because the hardware measures which stored color is mathematically closest.

That is the core idea of the RGB K-Means Cluster Engine:

> Every pixel is compared, measured, matched, and replaced with the nearest representative color.
