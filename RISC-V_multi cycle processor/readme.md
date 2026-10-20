# Multicycle RISC-V Processor (SystemVerilog)

A multicycle RISC-V processor in SystemVerilog, following the design in Harris & Harris,
*Digital Design and Computer Architecture: RISC-V Edition*, section 7.4 (Figures 7.27 and 7.28).

## Supported instructions
`lw`, `sw`, `add`, `sub`, `and`, `or`, `slt`, `addi`, `beq`, `jal`

| Instruction | Cycles | State sequence |
|---|---|---|
| lw | 5 | Fetch, Decode, MemAdr, MemRead, MemWB |
| sw | 4 | Fetch, Decode, MemAdr, MemWrite |
| R-type (add, sub, and, or, slt) | 4 | Fetch, Decode, ExecuteR, ALUWB |
| addi | 4 | Fetch, Decode, ExecuteI, ALUWB |
| beq | 3 | Fetch, Decode, BEQ |
| jal | 4 | Fetch, Decode, JAL, ALUWB |

## Structure
```
rtl/
  controller.sv            top of the control unit (Figure 7.28), PCWrite = (Branch & Zero) | PCUpdate
  main_FSM.sv              Moore FSM, 11 states
  alu_decoder.sv           ALUOp, funct3, op[5], funct7[5] -> ALUControl
  instr_decoder.sv         opcode -> ImmSrc
  multi_cycle_datapath.sv  datapath (Figure 7.27) with unified instruction/data memory
  register_file.sv extend_unit.sv alu.sv flopr.sv flopenr.sv mux2.sv mux3.sv memory_inst_data.sv
  top.sv                   controller + datapath
tb/
  controller_tb.sv         self-checking, cycle-by-cycle check of every control signal
  top_tb.sv                runs a test program on the full processor and checks registers, memory and PC
sw/
  program.hex              the test program (also loaded directly by top_tb.sv)
```

## Control encodings
| Signal | Encoding |
|---|---|
| ALUSrcA | 00 PC, 01 OldPC, 10 A |
| ALUSrcB | 00 WriteData (rs2), 01 ImmExt, 10 constant 4 |
| ResultSrc | 00 ALUOut, 01 Data, 10 ALUResult |
| ImmSrc | 00 I-type, 01 S-type, 10 B-type, 11 J-type |
| ALUControl | 000 add, 001 sub, 010 and, 011 or, 101 slt |

## Run the tests
Requires [Icarus Verilog](https://steveicarus.github.io/iverilog/) (tested with 12.0).
```
make test              # both suites
make test_controller   # controller only
make test_system       # full processor
```
Expected output ends with `ALL PASS (0 errors)` for each.

## Test program
```
00: addi x1, x0, 5        18: beq  x3, x5, +8   (taken, skips 1c)
04: addi x2, x0, 7        1c: addi x6, x0, 99   (skipped)
08: add  x3, x1, x2       20: beq  x1, x2, +8   (not taken)
0c: sub  x4, x2, x1       24: addi x7, x0, 1
10: sw   x3, 0x80(x0)     28: jal  x8, +8       (x8 = 0x2c)
14: lw   x5, 0x80(x0)     2c: addi x9, x0, 99   (skipped)
                          30: addi x10, x0, 42
                          34: addi x11, x0, -3
                          38: jal  x0, 0        (halt loop)
```

## Notes
- Unsupported opcodes return to Fetch after Decode.
- `top_tb.sv` loads the program through hierarchical references and clears the register file at
  time 0. Both are simulation-only conveniences.
- To load from a file instead, set the `INIT_FILE` parameter of `memory_inst_data`.
