# VHDL Source Code for Multi-Channel Extension and Disparity-Sweep Scheduling

This repository contains the VHDL source-code attachment:

**A Depth-First Scheduling for Stereo-Based Depth-Estimation Convolutional Neural Networks Exploiting Disparity on a Flexible Multi-Core Hardware Architecture**

The repository includes the modified VHDL files used to validate two implemented extensions of the original multi-core FPGA CNN accelerator architecture:

1. Multi-channel extension using SIMD cascading
2. Disparity-sweep scheduling using batch scheduling and sliding-window addressing


## Repository structure

```text
.
├── ComputeCore.vhd
├── ComputeCore_tb.vhd
├── Datapath.vhd
├── DualPortRAM.vhd
├── FloatingPointAdder.vhd
├── FloatingPointAdder_tb.vhd
├── FloatingPointMultiplier.vhd
├── FloatingPointMultiplier_tb.vhd
├── MUX_2.vhd
├── MUX_3.vhd
├── ReLUIfApplied.vhd
├── ReLUIfApplied_tb.vhd
├── SIMDCore.vhd
│
├── multi_channel_extension/
│   ├── FSMOneLine.vhd
│   ├── FSMOneLine_tb1_K2.vhd
│   └── FSMOneLine_tb1_K3.vhd
│
└── disparity_sweep/
    ├── FSMOneLine.vhd
    └── FSMOneLine_tb1.vhd
```

## Shared VHDL files

The files in the repository root are shared by both implemented functions. They include the compute core, datapath, floating-point operators, multiplexers, dual-port RAM, ReLU module, SIMD core, and related testbenches.

These files are required for both the multi-channel extension and the disparity-sweep scheduling implementation.

## Multi-channel extension

The folder `multi_channel_extension/` contains the FSM and testbench files used for validating the multi-channel extension.

The following files are included:

- `FSMOneLine.vhd`: modified FSM for the multi-channel extension
- `FSMOneLine_tb1_K3.vhd`: testbench for validating K = 3
- `FSMOneLine_tb1_K2.vhd`: testbench for validating K = 2

Only one testbench file should be used in the Vivado project at a time.

To validate the multi-channel extension, create a Vivado project and add:

- all required shared files from the repository root
- `multi_channel_extension/FSMOneLine.vhd`
- either `multi_channel_extension/FSMOneLine_tb1_K3.vhd` or `multi_channel_extension/FSMOneLine_tb1_K2.vhd`

## Disparity-sweep scheduling

The folder `disparity_sweep/` contains the FSM and testbench files used for validating the disparity-sweep scheduling function.

The following files are included:

- `FSMOneLine.vhd`: modified FSM for disparity-sweep scheduling
- `FSMOneLine_tb1.vhd`: testbench for validating the disparity-sweep scheduling function

To validate the disparity-sweep scheduling function, create a Vivado project and add:

- all required shared files from the repository root
- `disparity_sweep/FSMOneLine.vhd`
- `disparity_sweep/FSMOneLine_tb1.vhd`

## Important usage note

The FSM files in `multi_channel_extension/` and `disparity_sweep/` are alternative versions of the same module.

They should **not** be added to the same Vivado project at the same time.

For each validation setup, use only the corresponding `FSMOneLine.vhd` and its matching testbench.

## Development environment

The files were tested using:

- Xilinx Vivado 2020.1
- VHDL source files
- Behavioral simulation for functional validation

