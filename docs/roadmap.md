# Project Roadmap — Runtime-Adaptive FPGA Video LUT Reconfiguration

## Purpose

This roadmap defines the planned evolution of the Runtime-Adaptive FPGA Video LUT Reconfiguration repository from documentation foundation to implementation, validation, and publication release.

## Stage 1 — Documentation Foundation

### Goal

Establish a clear technical record and repository structure.

### Deliverables

- README
- License
- Technical overview
- Invention summary
- Publication roadmap
- System architecture
- Register map
- LUT reconfiguration flow
- Diagnostic readback
- Implementation plan
- Validation plan

### Status

In progress / mostly established.

## Stage 2 — Architecture Diagrams

### Goal

Add visual engineering diagrams to support technical understanding and publication reuse.

### Planned Diagrams

- System block diagram
- Control path and video path separation
- Shadow LUT update sequence
- Active/shadow bank switching
- Diagnostic readback path
- Register map overview
- Validation flow

## Stage 3 — RTL Skeleton

### Goal

Create initial SystemVerilog or VHDL module skeletons that match the documented architecture.

### Planned Modules

- AXI4-Lite register block
- Command index decoder
- Shadow LUT buffer
- Active LUT bank
- Activation control state machine
- RGB mapping core
- Diagnostic readback block
- Top-level wrapper

## Stage 4 — Host-Control Utilities

### Goal

Add scripts or software examples that show how a host controller would configure the FPGA design.

### Planned Utilities

- Load LUT profile
- Select command index
- Trigger activation
- Read diagnostic status
- Compare expected and active profile state

## Stage 5 — Testbench and Validation

### Goal

Add simulation tests and validation scenarios.

### Planned Tests

- Register access tests
- Shadow buffer write tests
- Activation control tests
- Invalid command tests
- Active bank switching tests
- RGB mapping tests
- Diagnostic readback tests

## Stage 6 — Technical Paper Package

### Goal

Prepare a formal technical publication package.

### Deliverables

- Expanded white paper
- Architecture diagrams
- Validation evidence
- Release notes
- GitHub release
- Optional Zenodo DOI archive

## Stage 7 — Public Release

### Goal

Publish a stable project release that can be cited and shared.

### Planned Release

`v1.0-public-technical-release`

## Status

Active technical documentation and publication-preparation stage.
