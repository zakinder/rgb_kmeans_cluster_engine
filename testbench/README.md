# Testbench Directory

This directory is reserved for simulation and verification files for the Runtime-Adaptive FPGA Video LUT Reconfiguration system.

## Intended Verification Targets

Future testbench files may verify:

- Register write and read behavior
- Shadow LUT loading
- Command-indexed profile selection
- Safe activation behavior
- Active LUT bank switching
- RGB mapping output behavior
- Diagnostic readback correctness
- Invalid command and error handling
- Frame-synchronized update timing

## Suggested File Structure

```text
testbench/
  tb_axi_lite_regs.sv
  tb_lut_shadow_buffer.sv
  tb_command_index_decoder.sv
  tb_lut_activation_ctrl.sv
  tb_rgb_mapping_core.sv
  tb_diagnostic_readback.sv
  tb_top_runtime_lut_reconfig.sv
```

## Example Verification Scenarios

1. Write LUT data into shadow memory.
2. Select a command index.
3. Trigger activation.
4. Confirm active LUT bank changes.
5. Process sample RGB pixels.
6. Read back diagnostic state.
7. Confirm expected status flags.

## Status

Placeholder directory for future simulation and validation work.
