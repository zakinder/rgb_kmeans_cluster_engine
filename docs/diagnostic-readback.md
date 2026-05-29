# Diagnostic Readback — Runtime-Adaptive FPGA Video LUT Reconfiguration

## Purpose

This document describes the diagnostic readback function of the Runtime-Adaptive FPGA Video LUT Reconfiguration system. Diagnostic readback allows software or host control logic to verify the active LUT state, selected command index, applied profile, and runtime configuration status.

## Diagnostic Objective

The objective of diagnostic readback is to confirm that the LUT profile written by the host has been correctly loaded, activated, and applied to the live video-processing path.

## Why Diagnostic Readback Is Important

Runtime LUT reconfiguration requires verification because live video systems must avoid unstable, partial, or incorrect configuration states. A diagnostic readback path allows the system to confirm the active state after an update event.

## Readback Targets

The diagnostic readback interface may expose the following information:

1. Active command index
2. Active LUT bank selection
3. Shadow LUT update status
4. Active LUT values
5. Update completion flag
6. Error or invalid-state flag
7. Frame-synchronized activation status
8. Configuration version or profile ID

## High-Level Readback Flow

```text
Host Software
    |
    v
Read Diagnostic Register
    |
    v
Return Active Command Index
    |
    v
Return Active LUT Bank State
    |
    v
Return LUT/Profile Status
    |
    v
Verify Applied Configuration
```

## Example Diagnostic Register Fields

| Field | Purpose |
|---|---|
| `active_command_index` | Shows the currently selected LUT command/profile |
| `active_bank_id` | Shows which LUT bank is driving the video path |
| `shadow_valid` | Indicates whether the shadow LUT contains valid data |
| `update_done` | Confirms that activation has completed |
| `update_error` | Indicates an invalid or failed update |
| `frame_sync_done` | Confirms frame-safe activation timing |
| `profile_id` | Identifies the active LUT profile |
| `readback_data` | Returns selected LUT or configuration values |

## Verification Sequence

1. Host writes new LUT/profile data.
2. Shadow buffer receives the update.
3. Host triggers activation.
4. Activation logic switches or transfers the new LUT state.
5. Diagnostic readback confirms the active command index.
6. Diagnostic readback confirms the active LUT bank.
7. Host compares returned state against expected configuration.

## Technical Benefit

Diagnostic readback improves system reliability by allowing runtime verification of LUT updates. This is especially useful in FPGA video systems where incorrect LUT activation could cause visual artifacts, unstable color mapping, or incorrect output behavior.

## Publication Value

This feature strengthens the architecture by showing that the system is not only runtime-configurable, but also verifiable. That makes the design more suitable for formal documentation, FPGA validation, and future implementation testing.

## Status

Initial diagnostic readback description for documentation and publication preparation.
