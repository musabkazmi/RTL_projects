# Single-Cycle RISC-V Processor (RV32I subset) in SystemVerilog

A single-cycle RISC-V processor written in SystemVerilog as a learning project.
The design follows the single-cycle architecture described in *Digital Design and
Computer Architecture: RISC-V Edition* (Harris & Harris), chapter 7.

## Supported instructions

| Type   | Instructions              |
|--------|---------------------------|
| Load   | `lw`                      |
| Store  | `sw`                      |
| R-type | `add`, `sub`, `slt`, `or`, `and` |
| Branch | `beq`                     |

## Architecture

The processor is split into a controller and a datapath.

- **Controller** (`controller.sv`)
  - `main_decoder`: decodes `op` into `RegWrite`, `ImmSrc`, `ALUSrc`, `MemWrite`,
    `ResultSrc`, plus the internal signals `Branch` and `ALUOp`.
  - `alu_decoder`: combines `ALUOp`, `funct3`, `op[5]`, and `funct7[5]` into the 3-bit `ALUControl`.
  - `PCSrc = Branch & Zero`.
- **Datapath** (`riscv_datapath.sv`): PC register, instruction memory, register file,
  immediate extender, ALU, data memory, and the muxes and adders that connect them.
- **Top** (`riscv_top.sv`): wires the controller and datapath together.

### Control encodings

| Signal       | Encoding |
|--------------|----------|
| `ImmSrc`     | `00` I-type, `01` S-type, `10` B-type |
| `ALUSrc`     | `0` register, `1` immediate |
| `ResultSrc`  | `0` ALU result, `1` memory read data |
| `ALUControl` | `000` add, `001` sub, `010` and, `011` or, `101` slt |

## Simulation

Tested with Icarus Verilog:

```
iverilog -g2012 -o sim -f filelist.f tb/tb_lw.sv
vvp sim
```

The testbench `tb_lw.sv` runs `lw x5, 8(x1)` and checks that `ALUResult` is the
address, `ReadData` is the memory word, `Result` equals `ReadData`, and that `x5`
is written on the clock edge.

## Status

- [x] Main decoder and ALU decoder
- [x] Controller + datapath integration
- [x] `lw` verified end to end in simulation
- [ ] `sw`, `or`, `beq` program-level tests
- [ ] Load programs from a file with `$readmemh`
- [ ] Additional instructions (`addi`, `jal`, ...)

## Reference

Sarah Harris and David Harris, *Digital Design and Computer Architecture: RISC-V Edition*.

it run by me on [edaplayground.com](https://edaplayground.com/) , please make adjustement as per your platform
