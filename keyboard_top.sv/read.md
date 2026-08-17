# PS/2 Keyboard Controller — RTL Design

A modular **SystemVerilog RTL implementation of a PS/2 keyboard interface** that receives serial keyboard data, decodes scan codes, identifies numeric key presses, and drives a seven-segment display.

The project was developed as part of the **Modeling and Synthesis of Digital Systems (ModSy)** laboratory.

The design demonstrates a complete synchronous digital system built from multiple RTL modules.

---

# 📌 Project Overview

The keyboard communicates using two asynchronous signals:

* `kb_clk` — PS/2 keyboard clock
* `kb_data` — PS/2 serial data

The RTL design synchronizes these signals to the FPGA/system clock, detects the keyboard clock edge, reconstructs the serial PS/2 frame, decodes the received scan code, and drives the corresponding seven-segment display.

### Overall architecture

```text id="9g1l1c"
             PS/2 Keyboard
             ┌────────────┐
             │            │
       kb_clk│            │kb_data
          ───►            ├───────
             │            │
             └─────┬──────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ Input Synchronizer  │
        │                     │
        │ 2-stage DFFs        │
        └──────────┬──────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │  Edge Detector      │
        │                     │
        │ Falling-edge detect │
        └──────────┬──────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ Scan Code Converter │
        │                     │
        │ Serial → Parallel   │
        └──────────┬──────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ Keyboard Controller │
        │                     │
        │ FSM / Scan Decode   │
        └──────────┬──────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ Binary Converter    │
        │                     │
        │ Scan Code → Number  │
        └──────────┬──────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │ Seven Segment       │
        │ Decoder             │
        └──────────┬──────────┘
                   │
                   ▼
             7-Segment Display
```

---

# 🧩 Module Architecture

The project is divided into several independent RTL modules:

| Module              | Function                      |
| ------------------- | ----------------------------- |
| `keyboard_top`      | Top-level integration         |
| `dflipflop`         | Basic D flip-flop             |
| `sync_keyboard`     | Synchronizes PS/2 inputs      |
| `edge_detector`     | Detects keyboard clock edge   |
| `convert_scancode`  | Serial-to-parallel conversion |
| `keyboard_ctrl`     | Keyboard scan-code controller |
| `convert_to_binary` | Scan-code lookup table        |
| `binary_to_sg`      | Seven-segment decoder         |

This modular structure makes the design easier to verify, debug, and synthesize.

---

# 1. Keyboard Input Synchronization

The PS/2 keyboard signals are asynchronous with respect to the FPGA system clock.

Directly sampling asynchronous signals can introduce **metastability**.

The project therefore uses a two-stage flip-flop synchronizer.

```text id="uhh1r5"
             Asynchronous Input
                    │
                    ▼
              ┌──────────┐
              │   DFF 1  │
              └────┬─────┘
                   │
                   ▼
              ┌──────────┐
              │   DFF 2  │
              └────┬─────┘
                   │
                   ▼
             Synchronized
                 Signal
```

Both `kb_clk` and `kb_data` are synchronized.

The implementation uses:

```systemverilog id="b8rh5v"
dflipflop f0
dflipflop f1
```

for the keyboard clock and another pair for keyboard data.

---

# 2. Keyboard Clock Edge Detection

The synchronized keyboard clock is monitored for the required transition.

The edge detector generates:

```text id="e7zv7v"
edge_found = 1
```

when the relevant edge of `kb_clk_sync` is detected.

This signal is used as a **clock-enable/event signal**, not as a physical clock.

The design specifically avoids:

```systemverilog id="h3p2bf"
always_ff @(posedge edge_found)
```

and instead keeps all sequential logic synchronized to:

```systemverilog id="8xq3bi"
posedge clk
```

This is an important RTL design practice because creating clocks from ordinary logic signals can lead to clock-domain and timing problems.

---

# 3. PS/2 Serial-to-Parallel Conversion

The PS/2 keyboard transmits data serially.

The `convert_scancode` module collects the serial bits into an 11-bit shift register:

```systemverilog id="8n1y4p"
logic [10:0] shift_reg;
```

The converter receives one bit whenever:

```text id="9ujr3g"
edge_found = 1
```

and shifts the data into the register.

After the complete PS/2 frame has been received, the relevant eight data bits are extracted:

```systemverilog id="yrz9c9"
scan_code_out <= shift_reg[8:1];
```

The module then generates:

```text id="6r2n4s"
valid_scan_code = 1
```

to indicate that a complete scan code is available.

---

# 4. PS/2 Frame Processing

A standard PS/2 keyboard transmission contains:

```text id="v1dz1c"
┌─────┬──────────────┬──────┬───────┐
│Start│  8 Data Bits │Parity│ Stop  │
└─────┴──────────────┴──────┴───────┘
```

The design therefore collects 11 serial bits.

Conceptually:

```text id="5t2n3x"
Bit:
 10  9  8  7  6  5  4  3  2  1  0
 ───────────────────────────────────
 Stop Parity    Data Bits      Start
```

The data portion is extracted and presented as an 8-bit scan code.

---

# 5. Keyboard Controller

The `keyboard_ctrl` module processes valid scan codes.

It recognizes numeric keyboard scan codes and converts them into the corresponding display value.

For example:

| Key | PS/2 Scan Code | Display Value |
| --- | -------------- | ------------: |
| `1` | `16h`          |             1 |
| `2` | `1Eh`          |             2 |
| `3` | `26h`          |             3 |
| `4` | `25h`          |             4 |
| `5` | `2Eh`          |             5 |
| `6` | `36h`          |             6 |
| `7` | `3Dh`          |             7 |
| `8` | `3Eh`          |             8 |
| `9` | `46h`          |             9 |
| `0` | `45h`          |             0 |

The controller also handles the PS/2 break-code prefix:

```text id="gckh0r"
F0
```

which indicates that a key has been released.

The controller therefore distinguishes between make codes and break-code sequences.

---

# 6. Scan Code Lookup Table

The `convert_to_binary` module implements a combinational lookup table.

For example:

```systemverilog id="0nq1pd"
8'h16 → 4'b0001
8'h1E → 4'b0010
8'h26 → 4'b0011
```

This converts keyboard scan codes into a four-bit binary representation.

Conceptually:

```text id="yixw7n"
PS/2 Scan Code
      │
      ▼
┌──────────────┐
│     LUT      │
│              │
│ 16h → 1      │
│ 1Eh → 2      │
│ 26h → 3      │
│ ...          │
└──────┬───────┘
       │
       ▼
  4-bit Binary
```

---

# 7. Seven-Segment Decoder

The `binary_to_sg` module converts the four-bit number into the seven-segment display pattern.

Example:

```text id="2gkwc8"
Binary       Seven Segment
  0       →  00111111
  1       →  00000110
  2       →  01011011
  3       →  01001111
```

The decoder uses a combinational `case` statement.

```text id="c4r6n0"
       a
      ───
   f │   │ b
      ───
       g
      ───
   e │   │ c
      ───
       d
```

The output pattern determines which segments are illuminated.

---

# 🔌 Top-Level Interface

The `keyboard_top` module provides the following interface:

| Signal    | Direction | Width | Description                |
| --------- | --------- | ----: | -------------------------- |
| `clk`     | Input     |     1 | System clock               |
| `rst`     | Input     |     1 | Reset                      |
| `kb_data` | Input     |     1 | PS/2 serial data           |
| `kb_clk`  | Input     |     1 | PS/2 keyboard clock        |
| `sc`      | Output    |     8 | Received scan code         |
| `num`     | Output    |     8 | Seven-segment pattern      |
| `seg_en`  | Output    |     4 | Seven-segment digit enable |

---

# 🔄 Complete Data Flow

A keyboard key press travels through the following pipeline:

```text id="f6qgls"
Key Press
   │
   ▼
PS/2 Keyboard
   │
   │ kb_clk / kb_data
   ▼
Synchronizer
   │
   ▼
Clock Edge Detector
   │
   ▼
Serial-to-Parallel Converter
   │
   │ 8-bit scan code
   ▼
Keyboard Controller
   │
   ▼
Scan-Code Lookup
   │
   │ 4-bit number
   ▼
Seven-Segment Decoder
   │
   ▼
Display
```

---

# 🧪 Verification

The design can be verified by providing recorded PS/2 keyboard scan-code sequences to the testbench.

Verification should check:

### Input synchronization

Verify that asynchronous keyboard signals are safely transferred into the system clock domain.

### Edge detection

Verify that the expected keyboard clock transition produces a single `edge_found` event.

### Serial conversion

Verify that 11 received bits produce the correct 8-bit scan code.

### Keyboard decoding

Verify that known scan codes produce the correct numeric values.

### Seven-segment output

Verify that the binary value produces the correct display pattern.

---

# 📋 Example

For a keyboard press of the `5` key:

```text id="3ly4ad"
Keyboard
   │
   │ PS/2 frame
   ▼
Synchronizer
   │
   ▼
Edge Detector
   │
   ▼
Scan Code Converter
   │
   │ 8'h2E
   ▼
Keyboard Controller
   │
   ▼
Binary Converter
   │
   │ 4'b0101
   ▼
Seven Segment Decoder
   │
   │ 8'b01101101
   ▼
Display shows: 5
```

---

# 🛠️ RTL Design Concepts Demonstrated

This project demonstrates several important concepts used in practical digital design:

* SystemVerilog RTL
* Modular RTL architecture
* Asynchronous input synchronization
* Two-stage synchronizers
* Metastability mitigation
* Edge detection
* Clock-enable/event-based design
* Serial-to-parallel conversion
* Shift registers
* Counters
* FSM-based control
* Lookup tables
* Combinational decoding
* Seven-segment display control
* Sequential logic
* Reset handling
* Hardware-oriented debugging

---

# 🧠 Important RTL Design Principle

One of the key lessons from this project is:

> **Do not use derived logic signals as clocks when a synchronous enable can be used instead.**

The keyboard clock is synchronized to the system clock, and its edge is converted into an event:

```text id="86n3jj"
kb_clk
   │
   ▼
Synchronizer
   │
   ▼
kb_clk_sync
   │
   ▼
Edge Detector
   │
   ▼
edge_found
   │
   ▼
Clock Enable
```

All sequential modules continue to operate using:

```systemverilog
always_ff @(posedge clk)
```

This keeps the design within a single primary clock domain.

---

# 📁 Repository Structure

```text id="1z3p8f"
keyboard-modsy/
│
├── rtl/
│   ├── keyboard_top.sv
│   ├── dflipflop.sv
│   ├── sync_keyboard.sv
│   ├── edge_detector.sv
│   ├── convert_scancode.sv
│   ├── keyboard_ctrl.sv
│   ├── convert_to_binary.sv
│   └── binary_to_sg.sv
│
├── tb/
│   └── keyboard_tb.sv
│
├── input/
│   └── input.txt
│
├── waveform/
│   └── keyboard.vcd
│
└── README.md
```

---

# 🧰 Tools

* **SystemVerilog**
* **Verilator**
* **EDA Playground**
* **GTKWave**
* **Linux**
* **Git/GitHub**

---

# 🚀 Possible Improvements

Potential extensions to this project include:

* Full PS/2 protocol verification
* Parity-bit checking
* Start/stop-bit validation
* Error detection
* Support for alphabetic keys
* Support for function keys
* Full keyboard scan-code table
* Key repeat handling
* Improved FSM-based break-code handling
* Seven-segment multiplexing
* SystemVerilog assertions
* Self-checking testbench
* FPGA hardware demonstration

---

# 🎯 Learning Objectives

The project demonstrates how a real-world peripheral can be converted into a synchronous RTL system:

```text id="xv6glb"
Asynchronous Peripheral
        ↓
Synchronization
        ↓
Edge Detection
        ↓
Serial Data Capture
        ↓
Protocol/Scan-Code Processing
        ↓
Lookup Table
        ↓
Display Driver
```

The main skills demonstrated are:

**RTL Architecture → CDC Synchronization → FSM Control → Serial Data Processing → Decoding → FPGA Output**

---

## Author

**Musab Kazmi**

Master's Student — Modeling and Synthesis of Digital Systems

Focus areas:

**RTL Design | SystemVerilog | Digital Design | FPGA | ASIC | Hardware Verification**
