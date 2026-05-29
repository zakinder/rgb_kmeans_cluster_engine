# Source Directory

This directory is reserved for software, scripts, drivers, utilities, or host-control examples for the Runtime-Adaptive FPGA Video LUT Reconfiguration system.

## Intended Contents

Future source files may include:

- Host configuration scripts
- Register write/read utilities
- LUT profile loading tools
- Diagnostic readback utilities
- Example command-index profile selector
- Python-based test utilities
- C/C++ driver examples

## Suggested File Structure

```text
src/
  load_lut_profile.py
  select_command_index.py
  read_diagnostics.py
  runtime_lut_control.c
  runtime_lut_control.h
```

## Example Host Flow

1. Load LUT profile data.
2. Write profile values through the control interface.
3. Select a command index.
4. Trigger safe activation.
5. Read diagnostic status.
6. Verify active configuration.

## Status

Placeholder directory for future host-control implementation.
