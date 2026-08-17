# FSM-Based Switch Debounce with Counter

A SystemVerilog implementation of a **digital switch debouncer using a finite-state machine (FSM) and programmable down-counter**.

The design filters mechanical switch bounce and produces two clean outputs:

* `db_level` — debounced switch level
* `db_tick` — one-clock-cycle pulse when a valid switch transition has been confirmed

This project demonstrates the combination of **FSM control logic and sequential datapath logic** in RTL.

---

# 📌 Project Overview

Mechanical switches can produce multiple rapid transitions when pressed or released.

For example, a clean transition:

```text
0 ─────────────────── 1
```

can physically look like:

```text
0 ──────┐ ┌─┐ ┌──┐ ┌──────── 1
        └─┘ └─┘ └──┘
             ↑
           bounce
```

If this signal is connected directly to digital logic, the system may detect several transitions instead of one.

This design solves the problem by requiring the switch input to remain stable for a configurable number of clock cycles before accepting the transition.

---

# 🧠 Design Architecture

The design consists of:

1. **Finite State Machine**
2. **Debounce Counter**
3. **Debounced Level Output**
4. **Transition Tick Output**

```text
                    ┌────────────────────┐
                    │                    │
                    │    Debounce FSM    │
                    │                    │
sw ────────────────►│  zero / wait1      │
                    │  one  / wait0      │
                    │                    │
                    └─────────┬──────────┘
                              │
                         Counter Control
                       q_load / q_dec
                              │
                              ▼
                    ┌────────────────────┐
                    │    Down Counter    │
                    │                    │
                    │      q_reg         │
                    └─────────┬──────────┘
                              │
                           q_zero
                              │
                              ▼
                    ┌────────────────────┐
                    │  Debounced Output  │
                    │                    │
                    │ db_level / db_tick │
                    └────────────────────┘
```

---

# 🔄 FSM States

The design uses four states:

```systemverilog
typedef enum logic [1:0] {
    zero,
    wait1,
    wait0,
    one
} state_t;
```

| State   | Description                                |
| ------- | ------------------------------------------ |
| `zero`  | Switch is confirmed LOW                    |
| `wait1` | Waiting to confirm a LOW → HIGH transition |
| `one`   | Switch is confirmed HIGH                   |
| `wait0` | Waiting to confirm a HIGH → LOW transition |

---

# 🔀 FSM State Transitions

## LOW → HIGH

When the switch is stable LOW, the FSM is in:

```text
zero
```

When `sw` becomes HIGH:

```text
zero
  │
  │ sw = 1
  ▼
wait1
```

The counter is loaded with its maximum value.

The FSM then waits while the switch remains HIGH:

```text
wait1
  │
  ├── sw = 0 ──► zero
  │
  └── sw = 1
          │
          ▼
       decrement
          │
          ▼
       counter = 0
          │
          ▼
         one
```

Once the counter reaches zero, the HIGH level is considered valid.

---

# 🔀 HIGH → LOW

When the switch is confirmed HIGH, the FSM remains in:

```text
one
```

When the switch becomes LOW:

```text
one
 │
 │ sw = 0
 ▼
wait0
```

The counter is loaded again.

The FSM waits while the switch remains LOW:

```text
wait0
  │
  ├── sw = 1 ──► one
  │
  └── sw = 0
          │
          ▼
       decrement
          │
          ▼
       counter = 0
          │
          ▼
         zero
```

This confirms the LOW transition.

---

# 📊 FSM State Table

| Current State | `sw` | Counter   | Next State       | `db_level` |
| ------------- | ---: | --------- | ---------------- | ---------: |
| `zero`        |    0 | —         | `zero`           |          0 |
| `zero`        |    1 | Load      | `wait1`          |          0 |
| `wait1`       |    0 | —         | `zero`           |          0 |
| `wait1`       |    1 | Decrement | `wait1` / `one`  |          0 |
| `one`         |    0 | Load      | `wait0`          |          1 |
| `one`         |    1 | —         | `one`            |          1 |
| `wait0`       |    1 | —         | `one`            |          1 |
| `wait0`       |    0 | Decrement | `wait0` / `zero` |          1 |

---

# ⏱️ Counter-Based Debouncing

The counter is declared as:

```systemverilog
parameter int N = 21;

logic [N-1:0] q_reg;
logic [N-1:0] q_next;
```

The counter is controlled by two signals:

```text
q_load
q_dec
```

### Counter control

```text
q_load = 1
    │
    ▼
q_next = all 1s
```

or:

```text
q_dec = 1
    │
    ▼
q_next = q_reg - 1
```

Otherwise:

```text
q_next = q_reg
```

The counter logic is:

```systemverilog
always_comb begin

    if (q_load)
        q_next = '1;
    else if (q_dec)
        q_next = q_reg - 1'b1;
    else
        q_next = q_reg;

end
```

This separates the **counter datapath** from the **FSM control logic**.

---

# 🧩 Datapath and Control

One of the important RTL concepts demonstrated by this project is the separation between **control** and **datapath**.

### Control

The FSM generates:

```text
q_load
q_dec
state_next
db_tick
```

### Datapath

The counter performs:

```text
Load maximum value
       ↓
Decrement
       ↓
Check zero
```

Conceptually:

```text
              ┌────────────────┐
              │      FSM       │
              │    CONTROL     │
              └───────┬────────┘
                      │
              q_load / q_dec
                      │
                      ▼
              ┌────────────────┐
              │    COUNTER     │
              │   DATAPATH     │
              └───────┬────────┘
                      │
                    q_zero
                      │
                      ▼
                    FSM
```

This is a useful architecture for larger RTL designs where control logic and datapath logic are explicitly separated.

---

# 🔢 Counter Configuration

The counter width is configurable:

```systemverilog
parameter int N = 21;
```

The counter starts at:

```text
2^N - 1
```

For example, with:

```text
N = 21
```

the counter can represent:

```text
0 → 2,097,151
```

The debounce interval therefore depends on:

* Clock frequency
* Counter width
* Initial counter value

Approximate debounce time:

```text
Debounce Time ≈ Counter Cycles / Clock Frequency
```

For example, with a 50 MHz clock:

```text
2,097,151 / 50,000,000
≈ 41.94 ms
```

---

# 📤 Output Signals

## `db_level`

`db_level` represents the **confirmed state of the switch**.

```text
FSM state:

zero / wait1 → db_level = 0

one / wait0  → db_level = 1
```

Therefore, while a transition is being verified, the output maintains the previous valid switch state.

---

## `db_tick`

`db_tick` is a one-clock-cycle pulse generated when the debounce process successfully confirms a transition.

For a LOW → HIGH transition:

```text
zero → wait1 → one
                 │
                 └── db_tick = 1
```

This allows downstream logic to detect a **single clean event** rather than continuously monitoring the level.

---

# 📈 Example Waveform

A noisy switch input might look like:

```text
clk     _|‾|_|‾|_|‾|_|‾|_|‾|_|‾|_

sw      ______‾_‾_‾________________‾‾‾
              ↑
            bounce

state   zero → wait1 → wait1 → wait1 → one
                                          
db_level ______________________________‾‾‾‾

db_tick  _______________________________‾__
                                         ↑
                                  one-cycle pulse
```

The important behavior is that `db_level` does not immediately respond to the noisy input.

---

# 🧪 Verification

The testbench should verify the following cases.

### Reset

```text
reset = 1
```

Expected:

```text
state    = zero
db_level = 0
db_tick  = 0
```

### Clean LOW → HIGH

```text
sw: 0 → 1
```

Expected:

```text
zero → wait1 → one
```

After the debounce interval:

```text
db_level = 1
db_tick  = 1
```

`db_tick` should only remain HIGH for one clock cycle.

---

### HIGH → LOW

```text
sw: 1 → 0
```

Expected:

```text
one → wait0 → zero
```

After the debounce interval:

```text
db_level = 0
```

---

### Bounce During LOW → HIGH

Example:

```text
sw:

0 → 1 → 0 → 1 → 0 → 1 → 1 → 1
```

The FSM should restart/cancel the debounce operation whenever the input does not remain stable.

Only the final stable HIGH level should cause:

```text
wait1 → one
```

---

### Bounce During HIGH → LOW

Example:

```text
sw:

1 → 0 → 1 → 0 → 1 → 0 → 0 → 0
```

The FSM should only accept the LOW state after it remains stable for the required debounce period.

---

# 🛠️ RTL Concepts Demonstrated

This project demonstrates practical understanding of:

* SystemVerilog
* FSM design
* Moore-style output behavior
* Sequential logic
* Combinational next-state logic
* Counter datapath design
* Control/datapath separation
* Parameterized RTL
* Switch debouncing
* State-based output generation
* One-cycle event/tick generation
* Asynchronous reset
* Waveform-based debugging

---

# 📁 Project Structure

```text
fsm-debounce-counter/
│
├── rtl/
│   └── debounce.sv
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

# 🧰 Tools

* **SystemVerilog**
* **Verilator**
* **EDA Playground**
* **GTKWave**
* **Linux**
* **Git/GitHub**

---

# 🚀 Possible Improvements

Future versions could include:

* Configurable debounce time in milliseconds
* Clock-frequency parameter
* Synchronous reset option
* Separate rising/falling edge tick outputs
* SystemVerilog assertions
* Self-checking testbench
* Functional coverage
* FPGA board implementation
* UVM verification environment

---

# 🎯 Key Takeaway

This project demonstrates a practical RTL architecture for converting a **noisy mechanical input into a reliable synchronous digital signal**.

The key design pattern is:

```text
Raw Input
    ↓
FSM Detects Transition
    ↓
Counter Verifies Stability
    ↓
Transition Confirmed
    ↓
Clean Level + Tick
```

**Skills demonstrated:**

**RTL Design → FSM → Datapath → Counter → Control Logic → Verification**

---

## Author

**Musab Kazmi**

Master's Student — Modeling and Synthesis of Digital Systems

Focus areas:

**RTL Design | SystemVerilog | Digital Design | FPGA | ASIC | Hardware Verification**
