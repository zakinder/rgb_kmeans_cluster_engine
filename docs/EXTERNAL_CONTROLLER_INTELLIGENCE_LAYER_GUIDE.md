# External Controller Guide — Runtime Intelligence Layer Management

**Designer Name:** Sakinder Ali  
**Repository:** `zakinder/rgb_kmeans_cluster_engine`  
**Target Audience:** Software engineers, firmware engineers, embedded-system engineers, FPGA-control engineers  
**Design Context:** Runtime-adaptive RGB clustering, centroid LUT management, safe configuration update, diagnostic readback

---

## 1. Purpose

This guide defines how an external controller should manage the RGB clustering intelligence layer at runtime. The external controller may be a processor subsystem, microcontroller, embedded Linux application, bare-metal firmware task, AXI-Lite master, PCIe host, register bus master, or supervisory control block.

The guide specifies:

1. The safe operational sequence for runtime configuration updates.
2. A representative control and status register map.
3. The verification logic required to confirm configuration integrity through diagnostic readback.
4. Software and firmware responsibilities for preventing partial updates, invalid profile activation, and mismatched runtime state.

The objective is to allow centroid profiles, clustering modes, LUT entries, and intelligence-layer controls to be updated while the video or pixel-processing system remains operational and deterministic.

---

## 2. System Context

The intelligence layer is the runtime decision and configuration-management layer around the RGB K-Means Cluster Engine. It controls which centroid profile is active, how centroid LUT entries are loaded, when updates become visible to the datapath, and how software confirms that the active hardware state matches the intended configuration.

```text
+-----------------------------+
| External Controller         |
| Software / Firmware / Host  |
+--------------+--------------+
               |
               | Register Bus / Control Interface
               v
+-----------------------------+
| Intelligence Control Layer  |
| - control registers         |
| - shadow LUT management     |
| - commit / activation logic |
| - diagnostic readback       |
+--------------+--------------+
               |
               v
+-----------------------------+
| RGB K-Means Cluster Engine  |
| - active centroid LUT       |
| - distance computation      |
| - minimum selector          |
| - clustered output stream   |
+-----------------------------+
```

---

## 3. Engineering Problem Addressed

Runtime updates are risky when configuration data is consumed by an active pixel-processing datapath. If software writes directly into active centroid memory while the video stream is live, some pixels may be classified using old centroid values while later pixels use partially updated values. This can cause:

- flicker
- frame tearing in classification output
- unstable segmentation
- color jumps
- inconsistent diagnostic state
- difficult-to-reproduce field failures

The intelligence layer solves this by separating **write/update state** from **active processing state** and requiring software to commit updates only after validation.

---

## 4. Control Philosophy

External controllers should follow four principles:

1. **Write into inactive or shadow state first.**  
   Do not modify the active centroid table directly during live streaming unless the system explicitly supports safe direct writes.

2. **Verify before activation.**  
   Every programmed entry should be read back and compared against the intended value before the new profile becomes active.

3. **Activate atomically.**  
   The active profile should switch only through a controlled commit operation, preferably at a frame boundary or safe synchronization point.

4. **Confirm after activation.**  
   After activation, software should read status and diagnostic registers to confirm that the hardware active state matches the requested state.

---

## 5. Runtime Update Model

The recommended runtime update model uses two configuration domains:

| Domain | Purpose |
|---|---|
| Active domain | Currently used by the RGB clustering datapath. |
| Shadow domain | Writable staging area for the next configuration. |

Software writes new centroid or intelligence-layer values into the shadow domain. The hardware does not use the shadow data for live pixel classification until software requests activation and the hardware accepts the commit.

```text
Software writes -> Shadow LUT -> Readback verification -> Commit -> Active LUT
```

---

## 6. Safe Runtime Update Sequence

The following sequence is the recommended operational flow for firmware or software.

### Step 1 — Read Capability and Version Registers

Software should first read static identification registers:

```text
IP_ID
IP_VERSION
CAPABILITY
LUT_DEPTH
PROFILE_COUNT
DATA_WIDTH
```

Software must confirm that the driver expects the same register layout and feature set exposed by the hardware.

### Step 2 — Check Engine Status

Read the status register:

```text
STATUS.busy
STATUS.stream_active
STATUS.commit_pending
STATUS.error
STATUS.active_profile
```

The controller should not start a new update if:

- a previous commit is pending
- the intelligence layer reports an error
- the shadow bank is locked
- the reset sequence is incomplete

### Step 3 — Select Shadow Profile or Shadow Bank

Choose the inactive target profile or shadow bank:

```text
SHADOW_PROFILE_SELECT = target_profile_id
```

The selected shadow profile becomes the destination for subsequent LUT writes.

### Step 4 — Clear Previous Error and Verification State

Before programming, clear stale state:

```text
CONTROL.clear_error = 1
CONTROL.clear_verify_status = 1
```

Then confirm:

```text
STATUS.error = 0
VERIFY_STATUS.valid = 0 or cleared
```

### Step 5 — Program Shadow LUT Entries

For each centroid entry:

```text
LUT_INDEX      = i
LUT_WRITE_DATA = packed_rgb_value
CONTROL.lut_write_strobe = 1
```

Packed RGB format:

```text
bits [23:16] = red
bits [15:8]  = green
bits [7:0]   = blue
```

Software should respect any required write timing, posted-write flushing, or bus ordering constraints.

### Step 6 — Read Back Shadow LUT Entries

For each programmed entry:

```text
LUT_INDEX = i
CONTROL.lut_read_strobe = 1
read LUT_READ_DATA
```

Software compares:

```text
expected_rgb[i] == readback_rgb[i]
```

If any entry mismatches, software must not commit the profile.

### Step 7 — Compute and Validate Configuration Signature

For stronger integrity checking, software should compute a checksum or CRC over the intended configuration and compare it against hardware diagnostic calculation if available.

Recommended signature inputs:

- profile ID
- centroid count
- all centroid RGB entries
- mode fields
- threshold fields
- update sequence number

Example:

```text
software_crc = CRC32(profile_id, centroid_entries, mode_config)
hardware_crc = DIAG_CONFIG_CRC
```

Commit should proceed only if:

```text
software_crc == hardware_crc
```

### Step 8 — Arm Commit

After readback verification succeeds, software requests activation:

```text
PENDING_PROFILE_SELECT = target_profile_id
CONTROL.arm_commit = 1
```

The hardware marks the update as pending but should not necessarily switch immediately unless immediate activation mode is selected.

### Step 9 — Select Activation Policy

The activation policy controls when the shadow profile becomes active.

Recommended policies:

| Policy | Description | Use Case |
|---|---|---|
| Immediate | Switch as soon as hardware accepts command. | Debug or inactive stream only. |
| Frame boundary | Switch on next `sof` or after current frame completes. | Live video. |
| Line boundary | Switch after current line completes. | Lower-latency but possible frame inconsistency. |
| Manual sync | Switch when external sync input arrives. | Multi-block synchronized systems. |

For live video, **frame-boundary activation is recommended**.

### Step 10 — Commit Update

Software writes:

```text
CONTROL.commit = 1
```

Hardware should then:

1. Lock the shadow profile.
2. Wait for the selected safe activation point.
3. Atomically switch the active profile pointer.
4. Update active-status registers.
5. Set commit-done status.
6. Optionally raise an interrupt.

### Step 11 — Poll or Wait for Commit Completion

Software waits until:

```text
STATUS.commit_done = 1
STATUS.commit_pending = 0
STATUS.active_profile == target_profile_id
```

If timeout expires, software should raise a commit-timeout error and avoid further writes until recovery.

### Step 12 — Confirm Active Configuration Through Diagnostic Readback

After commit, software reads active-domain diagnostic values:

```text
ACTIVE_PROFILE_ID
ACTIVE_CONFIG_SEQ
ACTIVE_CONFIG_CRC
ACTIVE_LUT_READ_DATA
```

The controller verifies:

```text
ACTIVE_PROFILE_ID == target_profile_id
ACTIVE_CONFIG_CRC == expected_crc
ACTIVE_LUT[i] == expected_rgb[i]
```

### Step 13 — Release Update Lock

Once verification passes:

```text
CONTROL.release_shadow_lock = 1
```

The shadow domain may now be reused for the next update.

---

## 7. Representative Control Register Map

The following map is representative and can be adapted to AXI-Lite, Avalon-MM, APB, Wishbone, PCIe BAR, SPI register windows, or memory-mapped firmware control.

### 7.1 Register Summary

| Offset | Name | Access | Description |
|---:|---|---|---|
| `0x0000` | `IP_ID` | RO | Fixed hardware identifier. |
| `0x0004` | `IP_VERSION` | RO | Major/minor/patch version. |
| `0x0008` | `CAPABILITY` | RO | Feature flags. |
| `0x000C` | `CONTROL` | RW/W1P | Global control and command strobes. |
| `0x0010` | `STATUS` | RO/W1C | Runtime status and sticky flags. |
| `0x0014` | `ERROR_STATUS` | RO/W1C | Error flags. |
| `0x0018` | `INT_ENABLE` | RW | Interrupt enable mask. |
| `0x001C` | `INT_STATUS` | RO/W1C | Interrupt status flags. |
| `0x0020` | `ACTIVE_PROFILE` | RO | Currently active centroid profile. |
| `0x0024` | `SHADOW_PROFILE_SELECT` | RW | Shadow profile selected for programming. |
| `0x0028` | `PENDING_PROFILE_SELECT` | RW | Profile requested for next activation. |
| `0x002C` | `ACTIVATION_POLICY` | RW | Immediate, frame, line, or manual sync activation. |
| `0x0030` | `LUT_INDEX` | RW | Centroid LUT index for read/write. |
| `0x0034` | `LUT_WRITE_DATA` | RW | Packed RGB write data. |
| `0x0038` | `LUT_READ_DATA` | RO | Packed RGB readback data. |
| `0x003C` | `LUT_ACCESS_STATUS` | RO/W1C | LUT access done/error flags. |
| `0x0040` | `CONFIG_SEQ` | RW | Software-assigned configuration sequence number. |
| `0x0044` | `EXPECTED_CRC` | RW | Expected configuration CRC supplied by software. |
| `0x0048` | `DIAG_CONFIG_CRC` | RO | Hardware-calculated diagnostic CRC. |
| `0x004C` | `VERIFY_CONTROL` | RW/W1P | Starts hardware verification operations. |
| `0x0050` | `VERIFY_STATUS` | RO/W1C | Verification result flags. |
| `0x0054` | `VERIFY_FAIL_INDEX` | RO | First failing LUT index. |
| `0x0058` | `ACTIVE_CONFIG_CRC` | RO | CRC of active configuration. |
| `0x005C` | `ACTIVE_CONFIG_SEQ` | RO | Sequence number of active configuration. |
| `0x0060` | `STREAM_STATUS` | RO | Frame/line/valid monitoring state. |
| `0x0064` | `FRAME_COUNTER` | RO | Processed frame counter. |
| `0x0068` | `COMMIT_COUNTER` | RO | Number of successful commits. |
| `0x006C` | `DIAG_READBACK_SELECT` | RW | Selects diagnostic readback source. |
| `0x0070` | `DIAG_READBACK_DATA` | RO | Diagnostic readback result. |
| `0x0074` | `SCRATCH` | RW | Driver test register. |

---

## 8. Register Field Definitions

### 8.1 `CONTROL` Register — Offset `0x000C`

| Bit | Name | Access | Description |
|---:|---|---|---|
| 0 | `enable` | RW | Enables the intelligence layer. |
| 1 | `soft_reset` | W1P | Requests internal soft reset. |
| 2 | `lut_write_strobe` | W1P | Writes `LUT_WRITE_DATA` to `LUT_INDEX` in selected shadow profile. |
| 3 | `lut_read_strobe` | W1P | Reads selected LUT entry into `LUT_READ_DATA`. |
| 4 | `arm_commit` | W1P | Arms a verified configuration for activation. |
| 5 | `commit` | W1P | Requests activation according to `ACTIVATION_POLICY`. |
| 6 | `clear_error` | W1P | Clears sticky error state. |
| 7 | `clear_verify_status` | W1P | Clears verification result flags. |
| 8 | `release_shadow_lock` | W1P | Releases shadow profile after completed update. |
| 9 | `freeze_stream` | RW | Optional stream freeze for debug/inactive update. |
| 10 | `diag_capture` | W1P | Captures diagnostic snapshot. |
| 31:11 | reserved | RO | Reserved; write zero. |

### 8.2 `STATUS` Register — Offset `0x0010`

| Bit | Name | Description |
|---:|---|---|
| 0 | `enabled` | Intelligence layer enabled. |
| 1 | `busy` | Hardware is processing a command. |
| 2 | `stream_active` | Input stream is active. |
| 3 | `shadow_locked` | Shadow profile is locked for commit or verification. |
| 4 | `commit_pending` | Commit has been requested but not yet activated. |
| 5 | `commit_done` | Last commit completed. Sticky W1C if implemented. |
| 6 | `verify_pass` | Last verification passed. |
| 7 | `verify_fail` | Last verification failed. |
| 8 | `error` | One or more error bits are set. |
| 15:9 | reserved | Reserved. |
| 23:16 | `active_profile_id` | Currently active profile. |
| 31:24 | `pending_profile_id` | Pending profile, if any. |

### 8.3 `ERROR_STATUS` Register — Offset `0x0014`

| Bit | Name | Description |
|---:|---|---|
| 0 | `invalid_lut_index` | LUT index exceeds implemented depth. |
| 1 | `write_while_locked` | Software attempted write while shadow profile was locked. |
| 2 | `commit_without_verify` | Commit requested before verification passed. |
| 3 | `crc_mismatch` | Expected CRC and hardware CRC do not match. |
| 4 | `readback_mismatch` | Diagnostic readback mismatch detected. |
| 5 | `commit_timeout` | Safe activation point did not occur before timeout. |
| 6 | `unsupported_policy` | Requested activation policy is not supported. |
| 7 | `sequence_error` | Invalid command order. |
| 8 | `stream_sync_error` | Frame/line sync state invalid during activation. |
| 31:9 | reserved | Reserved. |

### 8.4 `ACTIVATION_POLICY` Register — Offset `0x002C`

| Value | Name | Description |
|---:|---|---|
| `0` | Immediate | Activate as soon as command is accepted. |
| `1` | Frame boundary | Activate at the next safe frame boundary. |
| `2` | Line boundary | Activate at the next safe line boundary. |
| `3` | Manual sync | Activate when external/manual sync occurs. |

### 8.5 LUT Data Registers

`LUT_INDEX` selects the target centroid index.

`LUT_WRITE_DATA` format:

```text
[31:24] reserved
[23:16] red
[15:8]  green
[7:0]   blue
```

`LUT_READ_DATA` uses the same format.

---

## 9. Diagnostic Readback Architecture

Diagnostic readback confirms that the configuration seen by software matches the configuration stored or active in hardware.

The design should support two readback domains:

| Domain | Purpose |
|---|---|
| Shadow readback | Confirms staged writes before activation. |
| Active readback | Confirms the configuration actually used by the datapath after activation. |

Recommended diagnostic sources:

- shadow centroid LUT entry
- active centroid LUT entry
- active profile ID
- pending profile ID
- configuration sequence number
- hardware CRC
- frame counter
- commit counter
- last error code
- verification failure index

---

## 10. Configuration Integrity Verification Logic

Configuration integrity verification should include both **entry-level verification** and **aggregate signature verification**.

### 10.1 Entry-Level Readback Verification

For every programmed centroid entry:

```text
write_data[i] -> shadow_lut[i]
readback_data[i] <- shadow_lut[i]
compare(write_data[i], readback_data[i])
```

Pass condition:

```text
for all i: expected_rgb[i] == readback_rgb[i]
```

Fail condition:

```text
any expected_rgb[i] != readback_rgb[i]
```

On failure, hardware or software should record:

- failing profile ID
- failing centroid index
- expected value
- observed value
- timestamp or configuration sequence number

### 10.2 CRC-Based Verification

A CRC or checksum provides stronger validation across the full profile.

Recommended hardware logic:

```text
for i in 0 to K-1:
    crc_next = crc32_update(crc_current, centroid_lut[i])
```

Inputs to CRC should include:

- profile ID
- centroid LUT entries
- clustering mode fields
- activation policy
- configuration sequence number

Pass condition:

```text
DIAG_CONFIG_CRC == EXPECTED_CRC
```

Fail condition:

```text
DIAG_CONFIG_CRC != EXPECTED_CRC
```

### 10.3 Active-State Confirmation

After commit, software must confirm that the active state matches the staged state:

```text
ACTIVE_PROFILE == requested_profile
ACTIVE_CONFIG_SEQ == CONFIG_SEQ
ACTIVE_CONFIG_CRC == EXPECTED_CRC
```

For high-integrity systems, software should also sample active LUT entries and compare them to the expected centroid table.

---

## 11. Recommended Firmware Driver State Machine

A firmware driver should implement an explicit state machine.

```text
IDLE
  -> DISCOVER
  -> CHECK_STATUS
  -> SELECT_SHADOW
  -> PROGRAM_LUT
  -> READBACK_VERIFY
  -> CRC_VERIFY
  -> ARM_COMMIT
  -> WAIT_COMMIT
  -> ACTIVE_VERIFY
  -> COMPLETE
```

Error transitions:

```text
any state -> ERROR_RECOVERY
```

Recovery should:

1. Stop issuing new write commands.
2. Capture status and diagnostic registers.
3. Clear command strobes.
4. Clear error status if safe.
5. Re-read active profile and CRC.
6. Retry from a known state or fall back to a safe profile.

---

## 12. Firmware Pseudocode

```c
bool update_profile(uint32_t profile_id, const rgb_t *centroids, uint32_t k)
{
    read_ip_identity();

    if (status_error() || commit_pending()) {
        clear_errors_if_safe();
    }

    write_reg(SHADOW_PROFILE_SELECT, profile_id);
    write_reg(CONTROL, CLEAR_ERROR | CLEAR_VERIFY_STATUS);

    for (uint32_t i = 0; i < k; i++) {
        uint32_t packed = pack_rgb(centroids[i]);
        write_reg(LUT_INDEX, i);
        write_reg(LUT_WRITE_DATA, packed);
        write_reg(CONTROL, LUT_WRITE_STROBE);
        wait_lut_done_or_timeout();
    }

    for (uint32_t i = 0; i < k; i++) {
        uint32_t expected = pack_rgb(centroids[i]);
        write_reg(LUT_INDEX, i);
        write_reg(CONTROL, LUT_READ_STROBE);
        wait_lut_done_or_timeout();

        uint32_t observed = read_reg(LUT_READ_DATA) & 0x00FFFFFFu;
        if (observed != expected) {
            record_readback_failure(i, expected, observed);
            return false;
        }
    }

    uint32_t crc = compute_profile_crc(profile_id, centroids, k);
    write_reg(EXPECTED_CRC, crc);
    write_reg(VERIFY_CONTROL, START_CRC_VERIFY);
    wait_verify_done_or_timeout();

    if (read_reg(DIAG_CONFIG_CRC) != crc) {
        record_crc_failure();
        return false;
    }

    write_reg(PENDING_PROFILE_SELECT, profile_id);
    write_reg(ACTIVATION_POLICY, ACTIVATE_ON_FRAME_BOUNDARY);
    write_reg(CONTROL, ARM_COMMIT);
    write_reg(CONTROL, COMMIT);

    wait_commit_done_or_timeout();

    if (read_reg(ACTIVE_PROFILE) != profile_id) {
        record_activation_failure();
        return false;
    }

    if (read_reg(ACTIVE_CONFIG_CRC) != crc) {
        record_active_crc_failure();
        return false;
    }

    write_reg(CONTROL, RELEASE_SHADOW_LOCK);
    return true;
}
```

---

## 13. Software/Firmware Integration Requirements

External controller software should provide:

1. Register-level abstraction for read/write access.
2. Timeout handling for all command strobes.
3. Ordered writes or memory barriers when using posted buses.
4. Shadow-profile management.
5. Readback comparison logic.
6. CRC or checksum generation.
7. Error logging with failing index and observed data.
8. Safe fallback to a known-good profile.
9. Optional interrupt support for commit completion.
10. Version checking to prevent incompatible driver/hardware pairing.

---

## 14. Safety Rules for Runtime Updates

The following rules should be enforced by software and, where practical, hardware:

1. Do not commit a profile that has not passed readback verification.
2. Do not write to a shadow profile while it is locked for commit.
3. Do not switch active profiles in the middle of a frame unless explicitly permitted.
4. Do not ignore CRC mismatch or diagnostic mismatch flags.
5. Do not assume a write succeeded without readback or command-complete status.
6. Do not reuse a shadow profile after error until it has been cleared or reprogrammed.
7. Do not rely only on software state; always confirm hardware state through readback.

---

## 15. Recommended Error Handling

| Error | Recommended Action |
|---|---|
| Invalid LUT index | Stop update, fix driver bounds, clear error. |
| Readback mismatch | Reprogram failing entry or full profile, then verify again. |
| CRC mismatch | Recompute software CRC, reread LUT, reject commit. |
| Commit timeout | Check stream sync, activation policy, and frame markers. |
| Commit without verify | Reject command and require full verification sequence. |
| Write while locked | Wait for commit completion or release lock after safe recovery. |
| Active CRC mismatch | Fall back to known-good profile and capture diagnostics. |

---

## 16. Validation Checklist

Before releasing firmware, verify that the controller can:

- detect the correct IP version
- write all centroid entries
- read back all centroid entries
- detect deliberate readback mismatch
- detect deliberate CRC mismatch
- commit on frame boundary
- confirm active profile after commit
- recover from invalid index access
- recover from reset during update
- preserve live stream stability during runtime profile change

---

## 17. Summary

External controllers should manage the intelligence layer through a disciplined write-verify-commit-confirm sequence. The controller writes new configuration data into shadow state, verifies that state through diagnostic readback, commits the verified profile at a safe activation boundary, and confirms the active hardware state after activation.

This approach prevents partial-update artifacts, improves configuration integrity, and gives software and firmware engineers a deterministic control model for runtime-adaptive RGB clustering systems.
