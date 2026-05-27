# FPGA Intelligence Layer Integration Manual — Safe Runtime Updates, Commitment Protocol, and Memory Library Management

**Designer Name:** Sakinder Ali  
**Repository:** `zakinder/rgb_kmeans_cluster_engine`  
**Document Type:** Technical Integration Manual  
**Target Audience:** FPGA engineers, firmware engineers, embedded vision architects, high-performance video pipeline integrators

---

## 1. Purpose

This manual provides an engineering-level integration guide for placing the FPGA intelligence layer into high-performance RGB vision pipelines. It focuses on safe runtime reconfiguration, shadow-bank management, hardware commitment protocol, visual-tearing prevention, memory-library organization, and reverse-indexing logic.

The central integration goal is:

> Allow the vision pipeline to adapt its color-classification behavior while live video continues, without exposing the active datapath to partially updated profile data.

---

## 2. Scope

This document covers:

1. Five-step safe update strategy.
2. Hardware-level commitment protocol.
3. Avoidance of visual tearing and mid-frame mixed-profile artifacts.
4. Management of **Live Learning** and **Archived Wisdom** memory libraries.
5. Reverse-indexing logic for maintaining structural consistency across internal shadow banks.
6. Register/interface responsibilities for external controllers.
7. Verification and debug requirements for integration.

---

## 3. System Architecture Context

The FPGA intelligence layer surrounds the RGB clustering datapath and controls how configuration profiles are selected, staged, verified, activated, and archived.

```text
+---------------------------------------------------+
| External Controller                               |
| Firmware / Software / Embedded CPU / Host         |
+--------------------------+------------------------+
                           |
                           | Register / Bus Interface
                           v
+---------------------------------------------------+
| FPGA Intelligence Layer                           |
|                                                   |
|  +-------------------+    +-------------------+   |
|  | Live Learning     |    | Archived Wisdom   |   |
|  | Memory Library    |    | Memory Library    |   |
|  +---------+---------+    +---------+---------+   |
|            |                        |             |
|            v                        v             |
|      +-----------------------------------+        |
|      | Shadow Bank Manager               |        |
|      | - staging                         |        |
|      | - reverse-index mapping           |        |
|      | - integrity verification          |        |
|      +----------------+------------------+        |
|                       |                           |
|                       v                           |
|      +-----------------------------------+        |
|      | Commit Controller                 |        |
|      | - arm                             |        |
|      | - sync wait                       |        |
|      | - atomic activation               |        |
|      | - post-commit confirmation        |        |
|      +----------------+------------------+        |
+-----------------------|---------------------------+
                        v
+---------------------------------------------------+
| RGB K-Means Cluster Engine                        |
| Active Centroid Profile -> Distance -> Comparator |
+---------------------------------------------------+
```

---

## 4. Engineering Problem: Visual Tearing During Runtime Updates

Visual tearing occurs when a frame is processed using inconsistent configuration state. In a color-classification engine, this can happen if software writes new centroid, threshold, boundary, or mapping data directly into active memory while pixels are still flowing.

A hazardous direct-write sequence looks like this:

```text
Frame N begins with Profile A
Software writes first half of Profile B
Middle of Frame N sees mixed Profile A/B values
Software writes second half of Profile B
Frame N ends with Profile B
```

This creates visible or algorithmic artifacts:

- color flicker
- sudden segmentation boundary shifts
- mixed-profile frame output
- false region classification
- unstable robotics perception
- inspection false rejects
- downstream analytics errors

The intelligence layer prevents this by forcing runtime updates through a staged, verified, and synchronized commitment protocol.

---

## 5. Five-Step Safe Update Strategy

The recommended update lifecycle contains five mandatory stages:

```text
1. Stage
2. Verify
3. Arm
4. Commit
5. Confirm
```

These five steps create a disciplined transaction model for runtime video reconfiguration.

---

# Step 1 — Stage the New Configuration

## 5.1 Objective

The controller writes the new profile into an inactive shadow bank rather than active datapath memory.

```text
External Controller -> Shadow Bank
```

The active pipeline continues to use the current active bank.

```text
Active Bank A -> live video datapath
Shadow Bank B -> being updated
```

## 5.2 Required Actions

The controller should:

1. Select a free shadow bank.
2. Lock the selected shadow bank for update.
3. Clear stale error and verification flags.
4. Write new profile entries into shadow memory.
5. Assign a configuration sequence number.
6. Optionally compute and write an expected CRC.

## 5.3 Stage Completion Condition

Staging is complete only when all expected entries have been written and the shadow bank reports write completion.

```text
SHADOW_STATUS.write_done = 1
SHADOW_STATUS.write_error = 0
```

---

# Step 2 — Verify the Shadow Configuration

## 5.4 Objective

The controller verifies that the staged profile is complete, coherent, and readable before the hardware is allowed to activate it.

## 5.5 Required Verification Methods

At minimum, the system should perform:

1. **Entry-level readback**  
   Every programmed profile entry is read back and compared to the expected value.

2. **Aggregate signature check**  
   A CRC, checksum, or hash is computed over the staged profile.

3. **Index-map validation**  
   Reverse-index and forward-index relationships are checked for structural consistency.

4. **Boundary/mode validation**  
   Compressed boundary representations are checked for legal ordering, supported mode selection, and valid channel mapping.

## 5.6 Verification Completion Condition

Verification passes only when:

```text
VERIFY_STATUS.entry_match       = 1
VERIFY_STATUS.crc_match         = 1
VERIFY_STATUS.index_map_valid   = 1
VERIFY_STATUS.profile_complete  = 1
VERIFY_STATUS.error             = 0
```

If verification fails, the profile must not be armed.

---

# Step 3 — Arm the Commit

## 5.7 Objective

Arming marks the verified shadow bank as the pending candidate for activation.

```text
PENDING_BANK_ID <= verified_shadow_bank_id
CONTROL.arm_commit <= 1
```

## 5.8 Hardware Responsibility

When the commit is armed, hardware should:

1. Lock the pending shadow bank.
2. Prevent further writes to that bank.
3. Capture the pending profile ID.
4. Capture the pending sequence number.
5. Capture the pending CRC.
6. Set `commit_pending`.

## 5.9 Arm Completion Condition

```text
STATUS.commit_pending = 1
STATUS.pending_bank_id = selected_shadow_bank
ERROR_STATUS.commit_without_verify = 0
```

---

# Step 4 — Commit at a Safe Synchronization Boundary

## 5.10 Objective

The commit operation atomically switches the active profile pointer from the old bank to the new bank at a safe video boundary.

Recommended safe boundary:

```text
Frame boundary
```

A frame boundary ensures all pixels in a frame use the same configuration.

## 5.11 Hardware-Level Commitment Protocol

The commit controller should perform this sequence:

```text
1. Receive commit request.
2. Confirm pending bank is verified and locked.
3. Wait for selected activation boundary.
4. Quiesce profile pointer update path for one control cycle if required.
5. Atomically update active_bank_id.
6. Latch active sequence number and CRC.
7. Release old active bank to archive or shadow pool.
8. Raise commit_done flag.
9. Optionally raise interrupt.
```

## 5.12 Atomic Switch Requirement

The active bank pointer must change as one coherent event:

```text
active_bank_id_next = pending_bank_id
```

The datapath must never observe:

- partially updated entries
- half-switched bank selection
- profile ID from one bank and centroid values from another bank
- mismatched compressed boundary and reverse-index maps

## 5.13 Commit Completion Condition

```text
STATUS.commit_done = 1
STATUS.commit_pending = 0
ACTIVE_BANK_ID = pending_bank_id
ACTIVE_CONFIG_SEQ = pending_config_seq
ACTIVE_CONFIG_CRC = pending_config_crc
```

---

# Step 5 — Confirm Active State

## 5.14 Objective

After activation, the controller confirms that the active state matches the intended state.

## 5.15 Required Confirmation Checks

Software or firmware should read:

```text
ACTIVE_BANK_ID
ACTIVE_PROFILE_ID
ACTIVE_CONFIG_SEQ
ACTIVE_CONFIG_CRC
ACTIVE_REVERSE_INDEX_CRC
ACTIVE_DIAG_READBACK_DATA
COMMIT_COUNTER
ERROR_STATUS
```

Pass condition:

```text
active_bank_id       == requested_bank_id
active_config_seq    == requested_seq
active_config_crc    == expected_crc
active_reverse_crc   == expected_reverse_crc
error_status         == 0
```

## 5.16 Final Release

After confirmation:

```text
CONTROL.release_shadow_lock = 1
```

The update transaction is complete.

---

## 6. Hardware-Level Commitment Protocol Details

The commitment protocol is the hardware transaction that prevents visual tearing. It must be synchronous, deterministic, and protected from partial writes.

### 6.1 Commit Controller State Machine

Recommended states:

```text
IDLE
  -> STAGE_LOCKED
  -> VERIFIED
  -> ARMED
  -> WAIT_SYNC
  -> SWITCH_ACTIVE
  -> POST_COMMIT_CHECK
  -> DONE
  -> IDLE
```

Error state:

```text
any state -> COMMIT_ERROR
```

### 6.2 State Responsibilities

| State | Responsibility |
|---|---|
| `IDLE` | No active update transaction. |
| `STAGE_LOCKED` | Shadow bank selected and locked for programming. |
| `VERIFIED` | Shadow bank passed readback, CRC, and index checks. |
| `ARMED` | Verified bank selected as pending activation candidate. |
| `WAIT_SYNC` | Hardware waits for safe frame/line/manual boundary. |
| `SWITCH_ACTIVE` | Active bank pointer updates atomically. |
| `POST_COMMIT_CHECK` | Active ID, CRC, sequence, and index map are confirmed. |
| `DONE` | Commit is complete and visible to controller. |
| `COMMIT_ERROR` | Commit failed and requires recovery. |

### 6.3 Synchronization Inputs

The commit controller may use:

- `sof` — start of frame
- `eof` — end of frame
- `eol` — end of line
- external sync pulse
- software manual commit trigger
- pipeline-empty status

For high-performance live vision, frame-synchronous activation is recommended.

### 6.4 Tearing Prevention Rule

The active profile must remain stable for the full visible or processed frame interval.

Formal-style rule:

```text
if frame_active = 1:
    active_bank_id must remain stable
```

Profile switching is permitted only at the selected safe boundary:

```text
if safe_boundary_detected = 1 and commit_pending = 1:
    active_bank_id may update
```

---

## 7. Memory Library Model

The intelligence layer manages two conceptual memory libraries:

1. **Live Learning Memory Library**
2. **Archived Wisdom Memory Library**

These names describe two different roles in adaptive vision systems.

---

# 7.1 Live Learning Memory Library

## Definition

The **Live Learning** memory library stores profiles that are being created, updated, tuned, or recently learned from runtime observations.

It is the working area for adaptive behavior.

## Typical Contents

- newly generated centroid profiles
- recent calibration profiles
- scene-adaptive color maps
- temporary threshold sets
- experimental mode configurations
- runtime-refined max/mid/min boundary sets
- recently validated shadow profiles

## Engineering Role

Live Learning memory supports fast adaptation. It is used when the system is responding to:

- lighting changes
- product changeover
- robot task changes
- camera exposure changes
- material color drift
- inspection recipe tuning
- environmental variation

## Management Rules

1. Live Learning profiles must be tagged with a sequence number.
2. Each profile must include validity and verification flags.
3. A profile cannot become active until it passes the five-step update strategy.
4. Recent failed profiles should remain available for debug until overwritten.
5. Promotion to active state requires readback and CRC verification.

---

# 7.2 Archived Wisdom Memory Library

## Definition

The **Archived Wisdom** memory library stores stable, known-good, previously validated profiles.

It is the long-term memory of reliable configurations.

## Typical Contents

- factory-calibrated profiles
- product-specific inspection recipes
- field-proven centroid sets
- fallback profiles
- certified color maps
- known-good robotics task profiles
- historical best-performing profile versions

## Engineering Role

Archived Wisdom memory supports reliability and repeatability. It provides a safe fallback when live learning fails or when a known operating mode is required.

## Management Rules

1. Archived profiles should be write-protected during normal operation.
2. Profiles should include version, CRC, timestamp, and application metadata.
3. Only verified Live Learning profiles may be promoted into Archived Wisdom.
4. Archived Wisdom profiles should be available for immediate staging into shadow banks.
5. Fallback logic should select Archived Wisdom when runtime verification fails.

---

## 8. Live Learning vs Archived Wisdom — Operational Comparison

| Category | Live Learning | Archived Wisdom |
|---|---|---|
| Purpose | Runtime adaptation and tuning | Stable known-good operation |
| Update frequency | High | Low |
| Write protection | Usually writable | Usually protected |
| Risk level | Higher | Lower |
| Use case | Adapting to new scene or product | Recalling proven profile |
| Activation requirement | Must verify before commit | Must verify, but expected to pass |
| Failure response | Reject, debug, or retry | Use as fallback source |
| Promotion path | Can be promoted after validation | Long-term retained profile |

---

## 9. Shadow Bank Organization

A shadow bank is an inactive memory bank used for staging a candidate profile before activation.

Recommended bank roles:

```text
Bank 0: Active
Bank 1: Shadow candidate
Bank 2: Live Learning staging
Bank 3: Archived Wisdom staging or fallback
```

The exact number of banks may vary, but the key requirement is separation between the active datapath and the update target.

---

## 10. Reverse-Indexing Logic

Reverse-indexing is required when internal memory banks store profile data in an order that differs from the logical order used by software, the centroid selector, or compressed profile representation.

The purpose is structural consistency:

> Logical profile entries must map to the correct physical shadow-bank locations even when banks are mirrored, reversed, rotated, compressed, or internally reorganized.

---

# 10.1 Forward Index and Reverse Index

## Forward Index

The forward index maps a logical entry to a physical memory location.

```text
physical_index = forward_map[logical_index]
```

## Reverse Index

The reverse index maps a physical memory location back to its logical entry.

```text
logical_index = reverse_map[physical_index]
```

Both maps must agree.

---

# 10.2 Structural Consistency Requirement

For every valid logical index:

```text
reverse_map[forward_map[logical_index]] == logical_index
```

For every valid physical index:

```text
forward_map[reverse_map[physical_index]] == physical_index
```

These conditions prove that the mapping is bijective: each logical entry maps to exactly one physical entry, and each physical entry maps back to exactly one logical entry.

---

# 10.3 Simple Reverse Bank Example

Suppose a profile has eight entries:

```text
logical_index = 0,1,2,3,4,5,6,7
```

If an internal shadow bank stores entries in reverse order, then:

```text
physical_index = (K - 1) - logical_index
```

For `K = 8`:

| Logical Index | Physical Index |
|---:|---:|
| 0 | 7 |
| 1 | 6 |
| 2 | 5 |
| 3 | 4 |
| 4 | 3 |
| 5 | 2 |
| 6 | 1 |
| 7 | 0 |

Reverse lookup:

```text
logical_index = (K - 1) - physical_index
```

---

# 10.4 Why Reverse Indexing Matters

Without reverse-index validation, the system could write a correct profile into the wrong physical order.

That error can cause:

- centroid ID mismatch
- wrong cluster output
- diagnostic readback confusion
- active/shadow CRC mismatch
- comparator winner mapped to wrong color
- inconsistent Live Learning to Archived Wisdom promotion
- structural mismatch across banks

The profile may appear complete, but internally the data would be arranged incorrectly.

---

# 10.5 Reverse-Indexing Across Shadow Banks

Each shadow bank should expose or internally maintain:

```text
BANK_ID
BANK_DEPTH
FORWARD_INDEX_MAP
REVERSE_INDEX_MAP
INDEX_MAP_CRC
INDEX_MAP_VALID
```

Before commit, hardware or firmware should verify:

```text
for logical_index in 0 to K-1:
    p = forward_map[logical_index]
    assert p < K
    assert reverse_map[p] == logical_index
```

And:

```text
for physical_index in 0 to K-1:
    l = reverse_map[physical_index]
    assert l < K
    assert forward_map[l] == physical_index
```

---

# 10.6 Reverse-Index CRC

A reverse-index CRC confirms that index-map structure has not been corrupted.

Recommended CRC inputs:

```text
bank_id
bank_depth
forward_map[0:K-1]
reverse_map[0:K-1]
profile_id
config_sequence
```

Pass condition:

```text
INDEX_MAP_CRC == EXPECTED_INDEX_MAP_CRC
```

The commit controller should reject activation if the reverse-index map fails validation.

---

## 11. Compressed Profile Representation and Reverse Mapping

Compressed profiles may store color intelligence in compact forms such as:

```text
max boundary
mid boundary
min boundary
channel order
centroid tuple
profile selector
mode bitfield
```

When compressed data is expanded into a shadow bank, the reverse-index map ensures that the expanded physical layout still corresponds to the intended logical order.

Example flow:

```text
Compressed Profile Entry
        |
        v
Expansion / Decode Logic
        |
        v
Logical Entry Index
        |
        v
Forward Index Mapper
        |
        v
Physical Shadow Bank Location
```

Diagnostic readback must reverse the process:

```text
Physical Shadow Bank Location
        |
        v
Reverse Index Mapper
        |
        v
Logical Entry Index
        |
        v
Controller-Visible Readback
```

This allows software to read the profile back in the same logical order it used when programming the profile.

---

## 12. Register-Level Integration Recommendations

The following registers are recommended for high-performance integration.

| Register | Access | Purpose |
|---|---|---|
| `CONTROL` | RW/W1P | Global enable, reset, arm, commit, clear, lock release. |
| `STATUS` | RO/W1C | Busy, commit pending, commit done, error, active bank. |
| `ACTIVE_BANK_ID` | RO | Currently active bank. |
| `SHADOW_BANK_SELECT` | RW | Selects target bank for staging. |
| `PENDING_BANK_ID` | RW/RO | Bank selected for next activation. |
| `LIBRARY_SELECT` | RW | Selects Live Learning or Archived Wisdom source. |
| `PROFILE_ID` | RW | Selects profile inside memory library. |
| `PROFILE_SEQ` | RW | Sequence number for transaction tracking. |
| `PROFILE_CRC_EXPECTED` | RW | Expected profile CRC. |
| `PROFILE_CRC_OBSERVED` | RO | Hardware-computed profile CRC. |
| `INDEX_MAP_CRC_EXPECTED` | RW | Expected forward/reverse map CRC. |
| `INDEX_MAP_CRC_OBSERVED` | RO | Hardware-computed index-map CRC. |
| `VERIFY_CONTROL` | RW/W1P | Starts profile and index verification. |
| `VERIFY_STATUS` | RO/W1C | Verification pass/fail flags. |
| `VERIFY_FAIL_INDEX` | RO | First failing profile or index entry. |
| `COMMIT_POLICY` | RW | Immediate, frame, line, or manual sync activation. |
| `DIAG_SELECT` | RW | Selects readback source. |
| `DIAG_DATA` | RO | Diagnostic readback data. |

---

## 13. Firmware Update Sequence Example

```c
bool intelligence_layer_update(profile_t *profile)
{
    select_library(profile->source_library);       // Live Learning or Archived Wisdom
    select_shadow_bank(find_free_shadow_bank());
    lock_shadow_bank();
    clear_update_errors();

    for (uint32_t i = 0; i < profile->entry_count; i++) {
        uint32_t physical = forward_index(profile->index_map, i);
        write_shadow_entry(physical, profile->entry[i]);
    }

    if (!readback_verify_profile(profile)) {
        reject_shadow_bank();
        return false;
    }

    if (!verify_forward_reverse_index(profile->index_map)) {
        reject_shadow_bank();
        return false;
    }

    if (!verify_crc(profile)) {
        reject_shadow_bank();
        return false;
    }

    arm_commit(profile->shadow_bank_id, profile->sequence, profile->crc);
    request_commit(COMMIT_ON_FRAME_BOUNDARY);

    if (!wait_commit_done()) {
        enter_commit_error_recovery();
        return false;
    }

    if (!confirm_active_state(profile)) {
        fallback_to_archived_wisdom();
        return false;
    }

    release_shadow_lock();
    return true;
}
```

---

## 14. Verification Requirements

Integration verification should include:

1. Direct profile write/readback test.
2. Live Learning profile staging test.
3. Archived Wisdom profile staging test.
4. Shadow bank lock/unlock test.
5. Commit without verification rejection.
6. Frame-boundary commit test.
7. Mid-frame commit prevention test.
8. Reverse-index bijection test.
9. Reverse-index CRC mismatch test.
10. Comparator output consistency after profile switch.
11. Active bank stability during frame-active interval.
12. Fallback to Archived Wisdom after failed Live Learning profile.
13. Diagnostic readback from active and shadow domains.
14. Reset during staged update.
15. Reset during pending commit.

---

## 15. Formal-Style Assertions

Recommended assertions:

```text
assert active_bank_id stable while frame_active = 1
assert commit only occurs when verify_pass = 1
assert no write accepted when shadow_locked = 1 and bank is pending
assert reverse_map[forward_map[i]] = i for all valid i
assert forward_map[reverse_map[p]] = p for all valid p
assert active_crc = pending_crc after successful commit
assert active_sequence = pending_sequence after successful commit
assert cluster_id maps to the same logical profile entry after bank switch
```

---

## 16. Debug and Diagnostic Strategy

A robust integration should expose diagnostic snapshots for:

- active bank ID
- shadow bank ID
- pending bank ID
- active library source
- pending library source
- profile ID
- profile sequence
- profile CRC
- reverse-index CRC
- first failing index
- commit state
- frame counter at commit
- error status

This allows engineers to determine whether a failure occurred during staging, verification, arming, commit synchronization, active switching, or post-commit confirmation.

---

## 17. Design Guidance for High-Performance Vision Pipelines

For high-performance pipelines, engineers should follow these rules:

1. Keep the active bank read path fully deterministic.
2. Keep shadow-bank writes off the timing-critical pixel datapath.
3. Register commit-control signals across clock domains if required.
4. Synchronize activation to frame boundaries for visual stability.
5. Use CRC and index-map validation for every runtime update.
6. Maintain separate control state for Live Learning and Archived Wisdom libraries.
7. Never allow direct writes into the active bank during live stream operation.
8. Use diagnostic readback to confirm active state after every commit.
9. Treat reverse-index mismatch as a hard commit-blocking error.
10. Provide a known-good Archived Wisdom fallback profile.

---

## 18. Summary

The FPGA intelligence layer provides safe runtime adaptability for high-performance vision pipelines by separating active processing state from staged update state. The five-step update strategy — **Stage, Verify, Arm, Commit, Confirm** — prevents partial configuration writes from reaching the live datapath.

The hardware commitment protocol prevents visual tearing by switching active profile state only at a safe synchronization boundary. The Live Learning memory library enables adaptive runtime tuning, while the Archived Wisdom memory library preserves known-good profiles for repeatable operation and fallback recovery.

Reverse-indexing logic ensures that compressed profiles, logical centroid IDs, and physical shadow-bank layouts remain structurally consistent. This prevents incorrect cluster mapping and protects the integrity of the final output mapper after runtime profile activation.
