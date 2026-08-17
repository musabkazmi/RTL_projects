# FSM-Based Switch Debounce

A parameterized **switch debouncing circuit implemented in SystemVerilog** using a finite-state machine (FSM) and a configurable timing tick generator.

The design filters mechanical switch bounce by requiring the input signal to remain stable for a defined amount of time before changing the debounced output.

---

## 📌 Project Overview

Mechanical switches do not transition cleanly between `0` and `1`.

When a switch is pressed or released, the electrical signal can rapidly oscillate:

```text
Ideal signal:

sw       ────────┐
                 │
                 └────────────────

Actual signal:

sw       ────────┐ ┌─┐ ┌──┐
                 │ │ │ │  │
                 └─┘ └─┘  └────────
                    ↑
                  bounce
```

If this raw signal is connected directly to digital logic, the system may interpret a single button press as multiple transitions.

This project solves the problem by requiring the switch input to remain stable for a configurable period before accepting the new state.

---

# 🧠 Design Approach

The debounce circuit consists of two main components:

1. **Tick Generator**
2. **FSM-based Debounce Controller**

```text
                    ┌─────────────────┐
                    │  Tick Generator │
                    │                 │
             clk ──►│     Counter     │
           reset ──►│                 │
                    └────────┬────────┘
                             │
                           m_tick
                             │
                             ▼
sw ─────────────────►┌───────────────┐
                     │ Debounce FSM  │
                     │               │
                     │ State Machine  │
                     └───────┬───────┘
                             │
                             ▼
                            db
```

The `m_tick` signal provides the timing reference used by the FSM to determine how long the switch input has remained stable.

---

# 🔧 Parameters

The debounce time is controlled through the parameter:

```systemverilog
parameter int MAX_COUNT = 500_000 - 1
```

This makes the design configurable for different clock frequencies and required debounce intervals.

The tick generator counts clock cycles until `MAX_COUNT` is reached and then produces a timing pulse.

---

# 🔄 FSM Architecture

The debounce controller contains eight states:

```text
zero
wait1_1
wait1_2
wait1_3
one
wait0_1
wait0_2
wait0_3
```

The states are divided into two groups:

### LOW → HIGH transition

```text
zero
  │
  │ sw = 1
  ▼
wait1_1
  │
  │ m_tick
  ▼
wait1_2
  │
  │ m_tick
  ▼
wait1_3
  │
  │ m_tick
  ▼
one
```

The switch must remain HIGH through the required waiting periods before the FSM accepts the transition.

---

### HIGH → LOW transition

```text
one
  │
  │ sw = 0
  ▼
wait0_1
  │
  │ m_tick
  ▼
wait0_2
  │
  │ m_tick
  ▼
wait0_3
  │
  │ m_tick
  ▼
zero
```

Similarly, the switch must remain LOW for the required debounce interval before the output changes.

---

# 📊 State Table

| State     | Meaning                 | `sw = 0`  | `sw = 1`          |
| --------- | ----------------------- | --------- | ----------------- |
| `zero`    | Stable LOW              | `zero`    | `wait1_1`         |
| `wait1_1` | Waiting for HIGH        | `zero`    | Wait for `m_tick` |
| `wait1_2` | HIGH confirmation       | `zero`    | Wait for `m_tick` |
| `wait1_3` | Final HIGH confirmation | `zero`    | Wait for `m_tick` |
| `one`     | Stable HIGH             | `wait0_1` | `one`             |
| `wait0_1` | Waiting for LOW         | `one`     | `wait0_1`         |
| `wait0_2` | LOW confirmation        | `one`     | `wait0_2`         |
| `wait0_3` | Final LOW confirmation  | `one`     | `wait0_3`         |

The FSM returns to the stable state if the input changes during the debounce period.

This prevents short glitches from being interpreted as valid switch transitions.

---

# 💡 Output Logic

The debounced output is generated from the FSM state:

```systemverilog
assign db = (state_reg == one) ||
            (state_reg == wait0_1) ||
            (state_reg == wait0_2) ||
            (state_reg == wait0_3);
```

Therefore:

```text
Stable LOW:
db = 0

During LOW → HIGH debounce:
db = 0

Stable HIGH:
db = 1

During HIGH → LOW debounce:
db = 1
```

This means the output does not change until the FSM has confirmed the new switch state.

---

# ⏱️ Tick Generator

The debounce FSM uses a separate `tick_generator` module.

```systemverilog
tick_generator #(
    .MAX_COUNT(MAX_COUNT)
) tick_generator_inst (
    .clk(clk),
    .reset(reset),
    .m_tick(m_tick)
);
```

The tick generator provides a periodic timing event:

```text
Clock:

_‾_‾_‾_‾_‾_‾_‾_‾_‾_‾_‾_

m_tick:

____________________‾____
                    ↑
                 one-cycle
                   tick
```

This allows the FSM to measure time without requiring a large counter inside every FSM state.

---

# 🔌 Module Interface

## Debounce

| Signal  | Direction | Type    | Description                    |
| ------- | --------- | ------- | ------------------------------ |
| `clk`   | Input     | `logic` | System clock                   |
| `reset` | Input     | `logic` | Asynchronous active-high reset |
| `sw`    | Input     | `logic` | Raw switch input               |
| `db`    | Output    | `logic` | Debounced switch output        |

### Parameter

| Parameter   |  Default | Description                  |
| ----------- | -------: | ---------------------------- |
| `MAX_COUNT` | `499999` | Tick generator counter limit |

---

# 🔄 Example Operation

Suppose the switch is initially LOW:

```text
sw:
───────────────────
```

The FSM remains in:

```text
zero
```

When the switch is pressed:

```text
sw:
─────────┐┌─┐┌──────┐┌────────
         ││ ││      ││
         └┘ └┘      └┘
           ↑
         bounce
```

Instead of immediately changing the output, the FSM enters:

```text
zero
  ↓
wait1_1
  ↓
wait1_2
  ↓
wait1_3
  ↓
one
```

Only after the input remains stable long enough does:

```text
db = 1
```

The same process occurs in reverse when the switch is released.

---

# 🧪 Verification

The design should be verified using a SystemVerilog testbench that applies:

### 1. Reset

```text
reset = 1
```

Expected:

```text
state = zero
db    = 0
```

### 2. Clean switch transition

```text
sw: 0 → 1
```

Expected:

```text
zero → wait1_1 → wait1_2 → wait1_3 → one
```

and finally:

```text
db = 1
```

### 3. Switch bounce

Rapid transitions such as:

```text
0 → 1 → 0 → 1 → 0 → 1
```

should **not** cause the debounced output to repeatedly toggle.

### 4. Clean release

```text
sw: 1 → 0
```

Expected:

```text
one → wait0_1 → wait0_2 → wait0_3 → zero
```

and finally:

```text
db = 0
```

### 5. Bounce during release

Rapid LOW/HIGH transitions should be rejected until the signal remains stable for the required debounce period.

---

# 📈 Expected Waveform

A simplified waveform can be represented as:

```text
clk     _|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_

sw      ________‾_‾_‾____________‾
                  ↑
                bounce

state   zero → wait1_1 → wait1_2 → wait1_3 → one
                                           
db      __________________________‾‾‾‾‾‾‾‾
```

The important characteristic is that `db` does **not** respond immediately to the noisy input.

---

# 🛠️ RTL Design Techniques Demonstrated

This project demonstrates:

* SystemVerilog FSM implementation
* `typedef enum logic` state encoding
* `always_ff` sequential logic
* `always_comb` next-state logic
* Parameterized RTL
* Modular RTL design
* Counter-based timing
* Clock/tick generation
* Mechanical switch debouncing
* State-based output generation
* Asynchronous reset
* Simulation-based debugging

---

# 📁 Project Structure

```text
fsm-debounce/
│
├── rtl/
│   ├── debounce.sv
│   └── tick_generator.sv
│
├── tb/
│   └── debounce_tb.sv
│
├── waveform/
│   └── debounce.vcd
│
└── README.md
```

---

# ▶️ Simulation

The design can be simulated using **Verilator** or **EDA Playground**.

Typical flow:

```text
RTL
 │
 ▼
SystemVerilog Testbench
 │
 ▼
Verilator / EDA Playground
 │
 ▼
Simulation
 │
 ▼
VCD Waveform
 │
 ▼
GTKWave
```

Example Verilator command:

```bash
verilator --binary --trace debounce.sv tick_generator.sv debounce_tb.sv
```

Run the generated simulation:

```bash
./obj_dir/Vdebounce
```

Waveform analysis can then be performed using GTKWave.

---

# 🚀 Possible Improvements

Future versions of this project could include:

* Parameterized number of debounce states
* Configurable debounce time in microseconds
* Synchronous reset option
* Both-edge detection
* Edge-detection pulse output
* Assertion-based verification
* Self-checking testbench
* FPGA board implementation
* UVM-based verification

---

# 🎯 Learning Objectives

The main objective of this project is to demonstrate how a real-world asynchronous/noisy input can be converted into a clean digital signal using **RTL state-machine design**.

Key concepts demonstrated:

**FSM Design → Timing Control → Input Filtering → State Validation → Clean Digital Output**

---

## Author

**Musab Kazmi**

Master's Student — Modeling and Synthesis of Digital Systems

Focus:

**RTL Design | SystemVerilog | Digital Design | FPGA | ASIC | Hardware Verification**
