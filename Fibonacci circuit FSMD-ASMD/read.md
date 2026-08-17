# Iterative Fibonacci RTL Processor

A synchronous **iterative Fibonacci-number calculator implemented in SystemVerilog** using an FSM-based control unit and a register-based datapath.

The design accepts a Fibonacci index, performs the calculation over multiple clock cycles, and provides `ready` and `done_tick` control signals to indicate when a new calculation can start and when the result is available.

---

# 📌 Project Overview

The module calculates:

```text id="9h6q4e"
F(0) = 0
F(1) = 1
F(n) = F(n-1) + F(n-2)
```

Instead of calculating the complete result combinationally in a single cycle, the design performs the calculation **iteratively**, updating the datapath once per clock cycle.

This makes the architecture suitable for demonstrating a fundamental RTL design pattern:

```text id="i6p5x3"
        ┌─────────────────┐
        │  Control / FSM  │
        └────────┬────────┘
                 │
        Control Signals
                 │
                 ▼
        ┌─────────────────┐
        │    Datapath     │
        │                 │
        │ t0_reg          │
        │ t1_reg          │
        │ n_reg           │
        └────────┬────────┘
                 │
                 ▼
             Fibonacci
               Result
```

---

# 🧠 Architecture

The design is divided into two major parts:

### Control Unit

The FSM controls:

* When a calculation starts
* When Fibonacci iterations occur
* When the calculation is complete
* `ready` output
* `done_tick` output

### Datapath

The datapath contains:

* `t0_reg` — previous Fibonacci value
* `t1_reg` — current Fibonacci value
* `n_reg` — iteration counter

---

# 🔄 FSM

The controller contains three states:

```systemverilog id="c73nzw"
typedef enum logic [1:0] {
    idle,
    op,
    done
} state_t;
```

| State  | Description                     |
| ------ | ------------------------------- |
| `idle` | Waiting for a new calculation   |
| `op`   | Performing Fibonacci iterations |
| `done` | Result is complete              |

---

# 🔁 FSM Operation

## 1. IDLE

The module waits for `start`.

```text id="b2y3je"
idle
 │
 │ start = 0
 ▼
idle
```

When a calculation is requested:

```text id="f0qgrh"
idle
 │
 │ start = 1
 ▼
op
```

During `idle`:

```text id="smh7ri"
ready = 1
```

This tells the external system that the module can accept a new calculation.

---

## 2. OPERATION

The FSM performs one Fibonacci iteration per clock cycle.

```text id="g5g2am"
op
 │
 ├── n > 1 ─────► op
 │
 └── n ≤ 1 ─────► done
```

The datapath performs:

```systemverilog id="x4l3uj"
t0_next = t1_reg;
t1_next = t1_reg + t0_reg;
n_next  = n_reg - 1;
```

This corresponds to:

```text id="1v4w8c"
t0 = previous value
t1 = current value

Next:
t0 = t1
t1 = t1 + t0
```

---

## 3. DONE

Once the required number of iterations has been completed:

```text id="z17s8v"
op
 │
 │ n <= 1
 ▼
done
```

The module generates:

```text id="7oz6f5"
done_tick = 1
```

and then returns to:

```text id="g5m3ez"
idle
```

Therefore, `done_tick` acts as a **one-clock-cycle completion pulse**.

---

# 📊 Datapath

The Fibonacci calculation uses three registers.

| Register |   Width | Purpose                   |
| -------- | ------: | ------------------------- |
| `t0_reg` | 20 bits | Previous Fibonacci value  |
| `t1_reg` | 20 bits | Current Fibonacci value   |
| `n_reg`  |  5 bits | Remaining iteration count |

Initial values:

```text id="y8u4jd"
t0 = 0
t1 = 1
n  = i
```

For every iteration:

```text id="r8k1gm"
t0_next = t1
t1_next = t1 + t0
n_next  = n - 1
```

---

# 🔢 Example: F(6)

For input:

```text id="ks7m5x"
i = 6
```

The datapath evolves as:

| Iteration | `t0` | `t1` | `n` |
| --------: | ---: | ---: | --: |
|   Initial |    0 |    1 |   6 |
|         1 |    1 |    1 |   5 |
|         2 |    1 |    2 |   4 |
|         3 |    2 |    3 |   3 |
|         4 |    3 |    5 |   2 |
|         5 |    5 |    8 |   1 |

The result is:

```text id="8j42mt"
F(6) = 8
```

The output is driven by:

```systemverilog id="i4u3gy"
assign f = t1_reg;
```

---

# 🔌 Module Interface

| Signal      | Direction | Width | Description                      |
| ----------- | --------- | ----: | -------------------------------- |
| `clk`       | Input     |     1 | System clock                     |
| `reset`     | Input     |     1 | Asynchronous active-high reset   |
| `start`     | Input     |     1 | Starts a new calculation         |
| `i`         | Input     |     5 | Fibonacci index                  |
| `ready`     | Output    |     1 | Module ready for a new operation |
| `done_tick` | Output    |     1 | One-cycle completion pulse       |
| `f`         | Output    |    20 | Fibonacci result                 |

---

# 🤝 Control Interface

The module uses a simple request/completion handshake.

```text id="h6r8qq"
             start
               │
               ▼
        ┌──────────────┐
        │      FSM     │
        │              │
ready ─►│   Fibonacci  │
        │   Processor  │
        └──────┬───────┘
               │
               ▼
          done_tick
               │
               ▼
            result
               f
```

### Starting a calculation

The external logic waits for:

```text id="6oc4tc"
ready = 1
```

and then asserts:

```text id="y0n0v1"
start = 1
```

The FSM enters `op`.

### Completion

When the calculation finishes:

```text id="t2j9vk"
done_tick = 1
```

The Fibonacci result is available on:

```text id="l2z3i9"
f
```

---

# 📈 Example Timing

For a request to calculate `F(6)`:

```text id="gkaxqn"
Cycle       0    1    2    3    4    5    6    7
           ───────────────────────────────────────

start       ─────┐
                 └───────────────────────────────

ready       ─────1────0──────────────────────1────

state       idle  op   op   op   op   op   done idle

n           6     6    5    4    3    2    1

t1          1     1    1    2    3    5    8

done_tick   ────────────────────────────────1────

f           1     1    1    2    3    5    8
```

The exact cycle alignment depends on the testbench sampling convention, but the important architectural behavior is:

```text
start
  ↓
iterative computation
  ↓
done_tick
  ↓
result available
```

---

# 🧪 Special Cases

The design explicitly handles:

### F(0)

```text id="h9k1k1"
i = 0

F(0) = 0
```

### F(1)

```text id="8n4z7e"
i = 1

F(1) = 1
```

### F(n), n > 1

The FSM repeatedly performs:

```text id="z8b1s6"
t1 = t1 + t0
```

until the required number of iterations is complete.

---

# 🧪 Verification

The testbench should verify:

* Reset behavior
* `ready` assertion in `idle`
* Start operation
* Fibonacci values from `F(0)` through higher indices
* Correct iteration count
* `done_tick` timing
* Result stability
* Multiple consecutive calculations

Example test cases:

| Input `i` | Expected `f` |
| --------: | -----------: |
|         0 |            0 |
|         1 |            1 |
|         2 |            1 |
|         3 |            2 |
|         4 |            3 |
|         5 |            5 |
|         6 |            8 |
|         7 |           13 |
|         8 |           21 |
|        10 |           55 |
|        15 |          610 |

---

# 🛠️ RTL Concepts Demonstrated

This project demonstrates:

* SystemVerilog FSM design
* Datapath/control separation
* Iterative arithmetic
* Sequential datapath registers
* FSM-based sequencing
* Start/ready/done handshake
* One-cycle completion pulses
* Non-blocking assignments
* `always_ff`
* `always_comb`
* `typedef enum logic`
* Parameterized datapath width
* Multi-cycle RTL architecture
* Simulation and waveform debugging

---

# ⚠️ Design Considerations

The Fibonacci result is stored in a **20-bit register**:

```systemverilog
localparam int N = 20;
```

Therefore, the maximum representable unsigned result is:

```text id="2f5gda"
2^20 - 1 = 1,048,575
```

The implementation should therefore be used only for Fibonacci indices whose results fit within 20 bits.

For larger Fibonacci numbers, the datapath width should be increased.

---

# 📁 Project Structure

```text id="9y1t5h"
fibonacci-rtl/
│
├── rtl/
│   └── fib.sv
│
├── tb/
│   └── fib_tb.sv
│
├── waveform/
│   └── fib.vcd
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

* Parameterized Fibonacci datapath width
* Configurable input width
* Synchronous reset option
* Self-checking SystemVerilog testbench
* SystemVerilog assertions
* Performance/latency measurements
* Pipelined Fibonacci architecture
* Hardware implementation on FPGA
* Formal verification
* UVM verification environment

---

# 🎯 Key Takeaway

This project demonstrates a fundamental **multi-cycle RTL architecture** where an FSM controls a datapath to perform an arithmetic algorithm over multiple clock cycles.

The central design pattern is:

```text id="4a7s0m"
             ┌──────────────┐
             │     FSM      │
             │   CONTROL    │
             └──────┬───────┘
                    │
                    ▼
             ┌──────────────┐
             │   DATAPATH   │
             │              │
             │ t0 + t1      │
             │ iteration    │
             │ counter      │
             └──────┬───────┘
                    │
                    ▼
                Fibonacci
                  Result
```

**Skills demonstrated:**

**RTL Architecture → FSM → Datapath → Multi-Cycle Control → Handshake → Verification**

---

## Author

**Musab Kazmi**

Master's Student — Modeling and Synthesis of Digital Systems

Focus areas:

**RTL Design | SystemVerilog | Digital Design | FPGA | ASIC | Hardware Verification**
