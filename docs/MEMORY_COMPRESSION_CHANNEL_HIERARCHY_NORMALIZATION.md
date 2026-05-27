# Memory Compression Through Channel Hierarchy Normalization

**Designer Name:** Sakinder Ali  
**Repository:** `zakinder/rgb_kmeans_cluster_engine`  
**Document Type:** Concept Explanation / Technical Learning Guide  
**Audience:** FPGA learners, image-processing engineers, embedded vision developers, technical reviewers

---

## 1. Purpose

This document explains the concept of **memory compression through channel hierarchy normalization**.

The main idea is simple:

> Instead of storing every possible physical RGB color arrangement separately, the system stores a generic intensity pattern using the roles **Max**, **Mid**, and **Min**, then maps those roles back to the correct physical RGB channel order when needed.

This reduces memory usage because many RGB colors share the same intensity structure even when the red, green, and blue channels appear in different orders.

---

## 2. The Problem: Physical RGB Combinations Can Grow Quickly

An RGB color has three physical channels:

```text
Red
Green
Blue
```

A conventional system may store color profiles directly in physical RGB order:

```text
(R, G, B)
```

For example:

```text
Color A = (200, 100, 50)
Color B = (200, 50, 100)
Color C = (100, 200, 50)
Color D = (50, 200, 100)
Color E = (100, 50, 200)
Color F = (50, 100, 200)
```

These are six different physical arrangements of the same three intensity values:

```text
200, 100, 50
```

A direct RGB memory system may treat them as six separate cases.

That becomes expensive when many palettes, profiles, thresholds, or centroid boundary sets must be stored.

---

## 3. Key Insight: Separate Intensity Roles from Physical Channels

The compression idea begins by separating two things:

1. **Intensity hierarchy** — which value is largest, middle, and smallest.
2. **Physical channel placement** — whether the largest value belongs to red, green, or blue.

Instead of storing:

```text
R = 200, G = 100, B = 50
```

The system stores:

```text
Max = 200
Mid = 100
Min = 50
```

Then it separately stores or calculates the channel order:

```text
Max belongs to Red
Mid belongs to Green
Min belongs to Blue
```

This means the color can be described as:

```text
Generic intensity pattern + channel order
```

---

## 4. What Max, Mid, and Min Mean

For any RGB pixel or color profile entry:

```text
R, G, B
```

The system determines:

```text
Max = largest channel value
Mid = middle channel value
Min = smallest channel value
```

Example:

```text
R = 200
G = 100
B = 50
```

Then:

```text
Max = 200
Mid = 100
Min = 50
```

The hierarchy is:

```text
Red is Max
Green is Mid
Blue is Min
```

---

## 5. Why This Compresses Memory

Many colors can share the same generic intensity pattern.

For example, all of these colors use the same Max/Mid/Min values:

| Physical RGB | Max | Mid | Min | Channel Order |
|---|---:|---:|---:|---|
| `(200, 100, 50)` | 200 | 100 | 50 | R=Max, G=Mid, B=Min |
| `(200, 50, 100)` | 200 | 100 | 50 | R=Max, B=Mid, G=Min |
| `(100, 200, 50)` | 200 | 100 | 50 | G=Max, R=Mid, B=Min |
| `(50, 200, 100)` | 200 | 100 | 50 | G=Max, B=Mid, R=Min |
| `(100, 50, 200)` | 200 | 100 | 50 | B=Max, R=Mid, G=Min |
| `(50, 100, 200)` | 200 | 100 | 50 | B=Max, G=Mid, R=Min |

A direct RGB approach may store six physical combinations.

A normalized approach can store one generic pattern:

```text
(Max, Mid, Min) = (200, 100, 50)
```

And then store a small channel-order code to reconstruct the physical RGB arrangement.

---

## 6. The Six Possible Channel Orders

With three channels, there are six possible strict orderings:

| Order Code | Meaning | Physical Reconstruction |
|---:|---|---|
| 0 | R=Max, G=Mid, B=Min | `(Max, Mid, Min)` |
| 1 | R=Max, B=Mid, G=Min | `(Max, Min, Mid)` |
| 2 | G=Max, R=Mid, B=Min | `(Mid, Max, Min)` |
| 3 | G=Max, B=Mid, R=Min | `(Min, Max, Mid)` |
| 4 | B=Max, R=Mid, G=Min | `(Mid, Min, Max)` |
| 5 | B=Max, G=Mid, R=Min | `(Min, Mid, Max)` |

Only a small code is needed to identify the mapping.

Since six states require only three bits:

```text
3-bit order code can represent all 6 channel orders
```

This is much smaller than storing full duplicate RGB tables for every channel ordering.

---

## 7. Simple Analogy

Imagine three people standing on a podium:

```text
Tallest
Middle
Shortest
```

Instead of remembering each person by exact position every time, you first describe the height roles:

```text
Max height
Mid height
Min height
```

Then you record who is standing in each role:

```text
Alice = tallest
Bob = middle
Chris = shortest
```

The FPGA does a similar thing with color channels.

It remembers the intensity roles:

```text
Max, Mid, Min
```

Then it remembers which physical channel owns each role:

```text
Red, Green, or Blue
```

---

## 8. Conventional Storage vs Normalized Storage

### Conventional Physical RGB Storage

A conventional table may store entries like this:

```text
Entry 0: R=200, G=100, B=50
Entry 1: R=200, G=50,  B=100
Entry 2: R=100, G=200, B=50
Entry 3: R=50,  G=200, B=100
Entry 4: R=100, G=50,  B=200
Entry 5: R=50,  G=100, B=200
```

This stores repeated intensity information.

### Normalized Max/Mid/Min Storage

A normalized table stores:

```text
Generic Pattern: Max=200, Mid=100, Min=50
Order Code 0: R=Max, G=Mid, B=Min
Order Code 1: R=Max, B=Mid, G=Min
Order Code 2: G=Max, R=Mid, B=Min
Order Code 3: G=Max, B=Mid, R=Min
Order Code 4: B=Max, R=Mid, G=Min
Order Code 5: B=Max, G=Mid, R=Min
```

The intensity pattern is stored once. The channel order is stored compactly.

---

## 9. How the System Reconstructs RGB

When the system needs physical RGB output, it uses the order code to map the generic roles back into red, green, and blue.

Example:

```text
Max = 200
Mid = 100
Min = 50
Order Code = 3
```

Order Code 3 means:

```text
G = Max
B = Mid
R = Min
```

So the reconstructed RGB value is:

```text
R = 50
G = 200
B = 100
```

Output:

```text
RGB = (50, 200, 100)
```

---

## 10. Hardware View

The hardware can implement this using two parts:

```text
1. Hierarchy detector
2. Role-to-channel mapper
```

### 10.1 Hierarchy Detector

The hierarchy detector looks at the three input channels and determines:

```text
which channel is Max
which channel is Mid
which channel is Min
```

### 10.2 Role-to-Channel Mapper

The mapper reconstructs physical RGB from normalized roles.

```text
Input:  Max, Mid, Min, order_code
Output: R, G, B
```

This can be implemented with multiplexers.

---

## 11. Why This Matters in FPGA Design

FPGA memory is valuable. Large lookup tables can consume BRAM, distributed RAM, routing, and timing budget.

Channel hierarchy normalization helps because it can reduce repeated storage patterns.

Instead of storing many physical variants, the design can store:

```text
generic intensity roles + compact channel-order code
```

This helps with:

- smaller memory footprint
- fewer duplicated LUT entries
- faster profile transfer
- simpler profile compression
- more palettes or profiles in the same memory budget
- runtime-adaptive color mapping
- efficient shadow-buffer storage

---

## 12. Relationship to Compressed Profile Libraries

In a runtime-adaptive intelligence layer, profiles may be stored in memory libraries.

A compressed profile can store normalized entries like:

```text
Profile Entry:
    Max intensity
    Mid intensity
    Min intensity
    channel order code
    optional cluster ID
    optional threshold or boundary data
```

This allows the system to represent many color arrangements without storing every expanded RGB combination.

---

## 13. Relationship to Shadow Buffers

When updating profiles safely, the compressed normalized entries can be written into a shadow bank first.

```text
Compressed Profile -> Shadow Bank -> Verify -> Commit -> Active Bank
```

Because the profile is compressed, fewer memory writes may be required. This can make runtime updates faster and reduce the time needed to prepare a new profile.

Before activation, the system can verify:

- Max/Mid/Min values are valid
- channel order code is legal
- reconstructed RGB entries match expected output
- CRC/checksum matches
- reverse-index mapping is consistent

---

## 14. Example Memory Savings Concept

Assume one generic intensity pattern can appear in six physical channel orders.

Without normalization:

```text
6 RGB entries must be stored
```

With normalization:

```text
1 Max/Mid/Min pattern + 6 small order codes
```

The exact memory savings depend on implementation, but the principle is clear:

> The more repeated intensity structures exist across profiles, the more useful normalization becomes.

---

## 15. Important Edge Cases

### 15.1 Equal Channel Values

Sometimes two channels may be equal:

```text
R = 100
G = 100
B = 50
```

Now Max and Mid may be tied.

The hardware must define a deterministic tie rule, such as:

```text
If R and G are equal, Red wins the higher role first.
```

A deterministic tie rule prevents unstable channel-order codes.

### 15.2 Grayscale Values

If all channels are equal:

```text
R = G = B
```

Then:

```text
Max = Mid = Min
```

Any channel order reconstructs the same physical RGB value, but the system should still choose one canonical order code for consistency.

### 15.3 Invalid Order Codes

Since three bits can represent eight values but only six strict RGB orderings are needed, two codes are unused.

The system should treat unused codes as invalid or reserved.

---

## 16. Summary Table

| Concept | Meaning |
|---|---|
| Physical RGB | Actual red, green, and blue channel values. |
| Max | Largest intensity value among R, G, and B. |
| Mid | Middle intensity value among R, G, and B. |
| Min | Smallest intensity value among R, G, and B. |
| Channel order code | Small code that records which physical channel owns Max, Mid, and Min. |
| Normalization | Converting physical RGB into generic Max/Mid/Min roles. |
| Reconstruction | Mapping Max/Mid/Min roles back into physical RGB order. |
| Compression benefit | Avoids storing repeated physical RGB permutations. |

---

## 17. Final Explanation in Plain Language

The system saves memory by noticing that many colors are the same shape in intensity, even when the red, green, and blue channels are rearranged.

Instead of storing every rearranged RGB version, it stores the important intensity pattern once:

```text
Max, Mid, Min
```

Then it stores a small instruction that says where those values belong:

```text
which one goes to Red
which one goes to Green
which one goes to Blue
```

This is why channel hierarchy normalization is powerful:

> It turns many physical color combinations into one generic color structure plus a small channel-order map.

That reduces memory, simplifies profile storage, and supports efficient runtime-adaptive FPGA color processing.
