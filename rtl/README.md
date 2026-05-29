# RTL Directory

This directory is reserved for FPGA RTL source files related to the Runtime-Adaptive FPGA Video LUT Reconfiguration system.

## Intended Contents

Future RTL files may include:

- AXI4-Lite register interface
- LUT profile memory
- Shadow LUT buffer
- Active LUT bank
- Command index decoder
- Activation control state machine
- RGB mapping logic
- Diagnostic readback logic

## Suggested File Structure

```text
rtl/
  axi_lite_regs.sv
  lut_shadow_buffer.sv
  lut_active_bank.sv
  command_index_decoder.sv
  lut_activation_ctrl.sv
  rgb_mapping_core.sv
  diagnostic_readback.sv
  top_runtime_lut_reconfig.sv
```

## Status

Placeholder directory for future RTL implementation.
