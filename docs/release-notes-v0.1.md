# Release Notes — v0.1 Documentation Foundation

## Release Name

`v0.1-docs-foundation`

## Project

Runtime-Adaptive FPGA Video LUT Reconfiguration

## Release Purpose

This release establishes the initial public documentation foundation for the Runtime-Adaptive FPGA Video LUT Reconfiguration project. It organizes the technical concept, architecture, publication direction, implementation plan, validation plan, and invention-oriented disclosure into a structured GitHub repository.

## Main Additions

### Repository Foundation

- Main README
- License file
- Changelog
- GitHub documentation-task issue template
- Folder structure for documentation, papers, images, RTL, source utilities, and testbench material

### Documentation Package

- Technical overview
- Invention summary
- Publication roadmap
- System architecture
- Register map
- LUT reconfiguration flow
- Diagnostic readback
- Implementation plan
- Validation plan
- Release checklist
- Project roadmap

### Paper Package

- Technical white paper draft
- Patent-style disclosure draft

### Placeholder Implementation Areas

- `rtl/README.md`
- `src/README.md`
- `testbench/README.md`
- `images/README.md`

## Technical Scope Covered

This release documents the core architecture model:

1. Host software configuration path
2. AXI4-Lite style register interface
3. Command-indexed LUT/profile selection
4. Shadow LUT buffering
5. Active LUT bank separation
6. Safe activation control
7. RGB mapping logic
8. Diagnostic readback verification

## Known Limitations

- RTL implementation is not yet included.
- Simulation testbenches are not yet included.
- Hardware validation evidence is not yet included.
- Diagrams are planned but not yet added.
- Register addresses are representative and may change during implementation.

## Recommended Next Version

`v0.2-architecture-package`

Planned additions:

- System block diagram
- Shadow-buffer update diagram
- Active/shadow LUT bank switching diagram
- Diagnostic readback diagram
- Expanded register map
- White paper refinement

## Status

Initial documentation release candidate.
