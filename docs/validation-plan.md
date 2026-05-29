# Validation Plan — Runtime-Adaptive FPGA Video LUT Reconfiguration

## Purpose

This document defines the validation plan for the Runtime-Adaptive FPGA Video LUT Reconfiguration system. The validation goal is to confirm that LUT updates can be written, staged, activated, used by the RGB video path, and verified through diagnostic readback.

## Validation Objectives

- Confirm correct register-control behavior
- Verify shadow LUT loading
- Verify command-index profile selection
- Confirm safe active-bank update behavior
- Confirm RGB mapping uses the expected active LUT state
- Verify diagnostic readback correctness
- Detect invalid update or command conditions
- Preserve deterministic video timing behavior

## Test Area 1 — Register Interface

### Checks

- Write control register
- Read status register
- Write LUT address register
- Write LUT data register
- Read diagnostic selector and data register

### Expected Result

Register writes and reads return deterministic values and preserve documented field behavior.

## Test Area 2 — Shadow LUT Loading

### Checks

- Write a complete LUT profile into the shadow buffer
- Confirm `shadow_valid` or equivalent status flag
- Verify that active output does not change before activation

### Expected Result

Pending LUT data is staged safely without affecting the active video-processing path.

## Test Area 3 — Command Index Selection

### Checks

- Select valid command indices
- Select invalid command indices
- Confirm active command-index readback
- Confirm invalid command error flag

### Expected Result

Valid commands select expected profiles. Invalid commands are rejected or flagged.

## Test Area 4 — Activation Control

### Checks

- Trigger activation after valid shadow update
- Trigger activation without valid shadow update
- Confirm update completion flag
- Confirm error behavior for invalid activation

### Expected Result

Valid updates activate cleanly. Invalid activation requests do not corrupt the active LUT state.

## Test Area 5 — Active LUT Bank Behavior

### Checks

- Confirm active bank changes after activation
- Confirm active bank remains stable during shadow writes
- Confirm active LUT readback matches expected profile

### Expected Result

The active LUT bank remains isolated from incomplete shadow updates and changes only after controlled activation.

## Test Area 6 — RGB Mapping Output

### Checks

- Apply known input RGB pixels
- Apply known LUT profile
- Compare output RGB values against a reference model
- Confirm valid/frame/line metadata alignment if implemented

### Expected Result

RGB mapping output matches the expected active LUT profile behavior.

## Test Area 7 — Diagnostic Readback

### Checks

- Read active command index
- Read active bank ID
- Read update status
- Read selected LUT/profile values
- Read error flags

### Expected Result

Diagnostic readback accurately reports the applied runtime configuration.

## Test Area 8 — Runtime Update Stability

### Checks

- Perform repeated LUT updates
- Alternate command indices
- Write shadow data while active video mapping continues
- Confirm no active-state change before activation

### Expected Result

The system supports repeated runtime updates while maintaining stable active output behavior.

## Evidence to Capture

- Simulation waveform screenshots
- Register transaction logs
- Before/after active LUT readback
- RGB input/output comparison tables
- Error-state test results
- Hardware bring-up screenshots if available

## Status

Initial validation plan for future RTL simulation, hardware testing, and publication evidence.
