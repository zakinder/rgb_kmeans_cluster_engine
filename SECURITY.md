# Security Policy

## Supported Project Stage

This repository is currently in the documentation and publication-preparation stage. RTL, host-control software, and hardware deployment assets may be added in later versions.

## Reporting Security Issues

If future source code, RTL modules, host-control utilities, or hardware-control scripts introduce a security concern, please open a GitHub issue with a clear description of the affected file and behavior.

For sensitive issues that should not be disclosed publicly, contact the repository owner directly before posting implementation details.

## Security-Relevant Areas

Future security review should focus on:

- Host-control register access
- Invalid command handling
- Runtime configuration writes
- LUT profile loading tools
- Diagnostic readback exposure
- FPGA memory-mapped register interfaces
- Hardware state-machine failure behavior
- Error handling for invalid or partial updates

## Current Limitations

- No deployed hardware-control software is currently provided.
- No production RTL implementation is currently provided.
- Register addresses and control fields are documentation-stage examples.

## Responsible Use

This project is intended for technical documentation, FPGA research, validation planning, and publication preparation. Any future implementation should be reviewed before use in safety-critical, security-critical, or production video-processing systems.
