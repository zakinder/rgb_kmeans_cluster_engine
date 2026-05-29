# Contributing Guide

Thank you for your interest in the Runtime-Adaptive FPGA Video LUT Reconfiguration project.

## Project Scope

This repository focuses on FPGA-based runtime video LUT reconfiguration, including documentation, architecture planning, RTL design, host-control software, simulation, validation, diagrams, and publication material.

## Contribution Areas

Useful contributions may include:

- Documentation improvements
- Architecture diagrams
- Register map refinements
- RTL module skeletons
- Simulation testbenches
- Host-control scripts
- Validation examples
- White paper edits
- Issue reports and review notes

## Documentation Standards

When updating documentation:

- Use clear Markdown headings.
- Keep terminology consistent with the README.
- Distinguish implemented features from planned features.
- Use engineering-focused language.
- Prefer tables for register maps and verification matrices.
- Use `text` code blocks for architecture flow diagrams.

## Technical Naming Conventions

Recommended terms:

- `shadow_lut_buffer`
- `active_lut_bank`
- `command_index`
- `activation_control`
- `diagnostic_readback`
- `rgb_mapping_logic`
- `profile_id`
- `update_done`
- `update_error`

## Suggested Branch Names

```text
feature/rtl-skeleton
feature/register-map-update
docs/architecture-diagram
docs/white-paper-update
validation/testbench-plan
```

## Suggested Commit Messages

```text
Add shadow LUT buffer documentation
Update register map fields
Add diagnostic readback verification plan
Add RTL module skeleton
Refine white paper abstract
```

## Pull Request Checklist

Before submitting a pull request:

- [ ] The update matches the project scope.
- [ ] Markdown renders correctly.
- [ ] Technical terms are consistent.
- [ ] New files are linked from the README when appropriate.
- [ ] Future work is clearly labeled if implementation is not yet present.
- [ ] Patent-sensitive material has been reviewed before public disclosure.

## Status

Initial contribution guide for documentation and future implementation collaboration.
