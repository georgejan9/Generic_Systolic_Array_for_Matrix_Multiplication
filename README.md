# Generic Systolic Array for Matrix Multiplication

A fully parameterizable SystemVerilog implementation of a weight-stationary systolic array that performs matrix multiplication in hardware. The design is generic in both **data width** and **matrix size (N×N)**, built from a small set of reusable building blocks (PE, register, register array, multiplexer) connected via Verilog `generate` blocks.

> Built as Lab 0 for the **STMicroelectronics AI Accelerators Hands-on HW Design** course (Jul. 2025), instructed by Ahmed Abdelsalam.

## Overview

The module computes **C = A × B** for two N×N matrices using a 2D array of Processing Elements (PEs), where each PE performs a multiply-accumulate (`out = out + a_in * b_in`) and forwards its operands diagonally through the array — the classic systolic array data flow used in many AI/ML accelerators (e.g. Google TPU-style MAC arrays).

### Key features
- **Fully generic**: parameterized by `DATAWIDTH` (bit width of matrix elements) and `N_SIZE` (matrix dimension), so the array can be resized for any precision or matrix size without touching the RTL.
- **Self-contained datapath**: input staggering, multiply-accumulate, valid signal propagation, and output row selection are all handled internally.
- **Valid-based handshake**: a simple `valid_in` / `valid_out` protocol controls when matrix data is loaded and when results are ready.
- **Self-checking testbenches**: includes both an assertion-based testbench and a file-logging testbench that dumps full simulation traces to `file.log`.

## Architecture

```
        b_in
          │
 valid_in │   ┌────┐  ┌────┐
──────────┼──►│ reg│─►│ reg│
          │   └────┘  └────┘
 a_in     ▼     ▼        ▼
 ───────►┌────┐┌────┐┌────┐
         │ PE ││ PE ││ PE │
         └────┘└────┘└────┘
 ┌────┐  ┌────┐┌────┐┌────┐
 │ reg│─►│ PE ││ PE ││ PE │
 └────┘  └────┘└────┘└────┘
 ┌────┐┌────┐ ┌────┐┌────┐┌────┐
 │ reg││ reg│►│ PE ││ PE ││ PE │
 └────┘└────┘ └────┘└────┘└────┘
                  │
              ┌───▼───┐
              │  MUX  │──► c_out / valid_out
              └───────┘
```

**Data flow / operating sequence:**
1. **Reset** (`rst_n = 0`): clears all PEs, registers, and counters.
2. **Load phase** (`valid_in = 1`): one row/column of matrix `A` and `B` is fed in per clock cycle. Diagonal register staging (`REG_array`) skews the inputs so each PE receives its operands at the correct cycle, matching the systolic timing pattern.
3. **Stop loading** (`valid_in = 0`): once all rows have been pushed, `valid_in` is de-asserted.
4. **Compute & drain**: the array continues to compute and rows of the result matrix `C` become valid one at a time, flagged by `valid_out`, and are selected to the output via the `MUX_OUT` stage.

### Module hierarchy

| Module | Description |
|---|---|
| `systolic_array` (top) | Instantiates `REG_array` (×2, for A and B), `PE_array`, and `MUX_OUT` to form the complete generic systolic array. |
| `PE` | Processing element: `o_saved = o_saved + a_in * b_in`; forwards `a_in`→right, `b_in`→down, propagates `valid_in`, and asserts `valid_out` after `N_SIZE` accumulation cycles. |
| `PE_array` | N×N generic grid of `PE` instances wired together with `generate` loops. |
| `REG` | Single generic register that delays data + valid by one clock cycle. |
| `REG_array` | Generates the diagonal register staging network needed to skew matrix `A`/`B` inputs into the PE array. |
| `MUX` | Generic output multiplexer that selects which result row is presented on `matrix_c_out` each cycle, driven by an internal rolling `sel` counter. |

## Repository contents

```
.
├── systolic_array.sv       # RTL: top module + PE, PE_array, REG, REG_array, MUX
├── systolic_array_tb.sv     # Self-checking testbench (assertion-based)
├── file.log                  # Example simulation log/trace output
└── report.pdf                 # Full design report (architecture, RTL schematics, sim results)
```

## Parameters

| Parameter | Description | Default |
|---|---|---|
| `DATAWIDTH` | Bit width of each matrix element (inputs) | 16 |
| `N_SIZE` | Matrix dimension (N×N matrices) | 5 |

Output `matrix_c_out` elements are `2*DATAWIDTH` bits wide to avoid overflow from the multiply-accumulate.

## Ports (top-level `systolic_array`)

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk` | input | 1 | Clock |
| `rst_n` | input | 1 | Active-low synchronous-style reset |
| `valid_in` | input | 1 | Asserted while feeding matrix rows/columns in |
| `matrix_a_in` | input | `[DATAWIDTH-1:0]` × `N_SIZE` | One row of matrix A per cycle |
| `matrix_b_in` | input | `[DATAWIDTH-1:0]` × `N_SIZE` | One row of matrix B per cycle |
| `valid_out` | output | 1 | Asserted when a valid output row is available |
| `matrix_c_out` | output | `[2*DATAWIDTH-1:0]` × `N_SIZE` | One row of result matrix C per valid cycle |

## Example: 3×3 matrix multiplication

Tested with `DATAWIDTH = 16`, `N_SIZE = 3`:

```
A = | 3   9   2 |      B = | 8   9   7 |
    | 1   5   7 |          | 5  15   2 |
    | 11 15  21 |          | 1  11  13 |

A × B = C = |  71  184   65 |
            |  40  161  108 |
            | 184  555  380 |
```

This matches the rows seen in `file.log` and the simulation waveform captured in the report (`valid_out` rising row-by-row with the correct accumulated sums).

## Simulation

Both testbenches in this repo:
- Apply reset, then drive `valid_in = 1` for `N_SIZE` cycles while streaming in rows of `A` and `B`.
- De-assert `valid_in` once all data is loaded.
- Wait for `valid_out` to pulse for each output row and check the result against the expected matrix.
- One variant performs in-simulation `$display`/`$stop` assertions ("TEST passed"); the other logs the full transcript (inputs, intermediate state, and outputs) to `file.log` for offline inspection.

Simulated and verified with **Vivado Simulator 2018.2** (1 ps time resolution).

To run with Vivado:
```tcl
vlib work
vlog systolic_array.sv systolic_array_tb.sv
vsim systolic_array_tb
run -all
```
(or use the Vivado XSIM GUI / `xvlog` + `xelab` + `xsim` command-line flow).

## Author

George Jan George Shaffik
