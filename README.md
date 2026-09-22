# FPGA-Based APB3 FIFO, Elapsed-Time Timer & PWM Controller

## 📌 Project Overview

This project implements an **AMBA APB3-based peripheral system** on the **Digilent Nexys A7-100T FPGA board** using **Verilog HDL**.

The system integrates three main APB3 peripherals:

* 🗃️ **FIFO (First-In First-Out)**
* ⏱️ **Elapsed-Time Timer**
* 📈 **PWM (Pulse Width Modulation) Controller**

An APB3 master communicates with these peripherals through an **APB3 decoder**. The timer measures the processing time of FIFO and PWM operations, and the elapsed time can be displayed on the **7-segment display**.

---

## 🎯 Objectives

The main objectives of this project are:

1. To understand and implement the **AMBA APB3 protocol**.
2. To design an APB3 master and peripheral slaves using Verilog HDL.
3. To integrate multiple peripherals using an APB address decoder.
4. To implement a FIFO memory block.
5. To generate PWM signals with selectable duty cycles.
6. To implement an elapsed-time timer.
7. To display timer information using the Nexys A7 7-segment display.
8. To verify the complete design using **Vivado Behavioral Simulation**.
9. To implement and test the design on an FPGA board.

---

## 🏗️ System Architecture

```text
                         ┌─────────────────────┐
                         │      APB3 Master     │
                         └──────────┬──────────┘
                                    │
                           APB3 Interface
                                    │
                         ┌──────────▼──────────┐
                         │     APB3 Decoder     │
                         └──────┬─────┬─────┬──┘
                                │     │     │
                    ┌───────────┘     │     └───────────┐
                    │                 │                 │
              ┌─────▼─────┐    ┌─────▼─────┐    ┌─────▼─────┐
              │    FIFO   │    │    PWM    │    │   TIMER   │
              │   Slave   │    │   Slave   │    │   Slave   │
              └─────┬─────┘    └─────┬─────┘    └─────┬─────┘
                    │                 │                 │
                    │                 │                 │
                    └─────────────────┼─────────────────┘
                                      │
                             ┌────────▼────────┐
                             │  FPGA Outputs   │
                             │ LEDs / 7-Segment│
                             └─────────────────┘
```

---

## 🔌 APB Address Map

Each peripheral is assigned a unique APB address.

| Peripheral | Address |
| ---------- | ------: |
| UART       |  `0x05` |
| GPIO       |  `0x10` |
| FIFO       |  `0x20` |
| PWM        |  `0x30` |
| Timer      |  `0x40` |

### Timer Address

The timer is assigned:

```text
0x40
```

Binary representation:

```text
0100 0000
```

The address decoder detects `8'h40` and activates the timer peripheral.

---

# 🗃️ FIFO Peripheral

The FIFO implements a **First-In First-Out** data storage mechanism.

### Features

* 8-bit data width
* Multiple storage locations
* Write and read operations
* Full and empty status
* APB3 interface
* Error detection for invalid read/write operations

### Basic Operation

```text
Write Data
    ↓
   FIFO
    ↓
Read Data
```

The FIFO stores data in the order in which it is written.

For example:

```text
Write: 10 → 20 → 30 → 40

Read:  10 → 20 → 30 → 40
```

---

# 📈 PWM Peripheral

The PWM slave generates a PWM output signal with selectable duty cycles.

The duty cycle can be selected through the APB interface.

| Selection | Duty Cycle |
| --------- | ---------: |
| `00`      |        25% |
| `01`      |        50% |
| `10`      |        75% |
| `11`      |       100% |

The PWM output is available as:

```text
pwm_out
```

### PWM Concept

```text
25% Duty Cycle

____        ____
    |______|

50% Duty Cycle

________
        |________

75% Duty Cycle

____________
            |____
```

The duty cycle determines the percentage of one PWM period for which the output remains HIGH.

---

# ⏱️ Elapsed-Time Timer

The timer measures the amount of time taken by a selected operation.

The timer counts upward:

```text
0 → 1 → 2 → 3 → 4 → 5 → ...
```

The timer can be started when an operation begins and stopped when the operation is completed.

### Timer Flow

```text
Operation Start
       ↓
 Timer START
       ↓
0 → 1 → 2 → 3 → 4 → 5 ...
       ↓
Operation Complete
       ↓
 Timer STOP
       ↓
Display Elapsed Time
```

The timer uses a clock counter to determine when one second has elapsed.

For FPGA hardware, the timer uses the system clock frequency:

```text
CLK_PER_SEC = 100,000,000
```

for a 100 MHz clock.

For behavioral simulation, a smaller value can be used to make the timer run faster.

Example:

```verilog
.CLK_PER_SEC(10)
```

This allows the timer to be verified quickly in simulation.

---

# 🖥️ 7-Segment Display

The elapsed timer value can be displayed on the Nexys A7's 4-digit 7-segment display.

The timer value is stored in BCD format.

For example:

```text
0000
0001
0002
0003
0004
0005
...
```

The display multiplexer selects the required digit and continuously refreshes the display.

---

# 🔄 APB3 Communication

The project uses the standard APB3 transaction sequence:

```text
IDLE
  ↓
SETUP
  ↓
ACCESS
  ↓
IDLE
```

### SETUP Phase

The master selects the required peripheral.

```text
PSEL = 1
PENABLE = 0
```

### ACCESS Phase

The transfer takes place.

```text
PSEL = 1
PENABLE = 1
```

The slave responds using:

```text
PREADY
PRDATA
PSLVERR
```

---

# 📂 Project Structure

A possible project structure is:

```text
APB3-FIFO-TIMER-PWM/
│
├── README.md
│
├── rtl/
│   ├── apb3_master.v
│   ├── apb3_decoder.v
│   ├── apb_fifo_slave.v
│   ├── FIFO.v
│   ├── pwm_slave.v
│   ├── elapsed_timer.v
│   ├── display_mux.v
│   └── top.v
│
├── simulation/
│   ├── elapsed_timer_tb.v
│   └── top_tb.v
│
├── constraints/
│   └── NexysA7.xdc
│
└── docs/
    └── project_documentation.pdf
```

---

# 🧪 Simulation

The design can be verified using **Xilinx Vivado Behavioral Simulation**.

For timer verification, the simulation testbench uses a smaller clock-per-second value.

Example:

```verilog
elapsed_timer #(
    .CLK_PER_SEC(10)
)
```

This makes it possible to observe the timer counting during a short simulation.

### Expected Simulation

```text
Time
 │
 │     START
 │       ↓
 └───────┬─────────────────────────────
         │
         0    1    2    3    4    5
         │    │    │    │    │    │
         └────Timer Counting─────────┐
                                    │
                                  STOP
```

The important signals to observe are:

```text
clk
rst
start
stop
running
bcd_seconds
```

---

# 🛠️ Tools & Technologies

| Tool / Technology | Usage                             |
| ----------------- | --------------------------------- |
| Verilog HDL       | Hardware description              |
| Xilinx Vivado     | Design, simulation and synthesis  |
| Nexys A7-100T     | FPGA development board            |
| AMBA APB3         | Peripheral communication protocol |
| 7-Segment Display | Timer output                      |
| LEDs              | Hardware debugging                |

---

# ⚙️ FPGA Board

### Digilent Nexys A7-100T

The design targets the:

```text
Nexys A7-100T
```

FPGA device:

```text
XC7A100TCSG324-1
```

The project uses the board's:

* 100 MHz clock
* Push buttons
* Switches
* LEDs
* 4-digit 7-segment display

---

# 🚀 How to Run the Project

## 1. Open Vivado

Create or open the Vivado project.

## 2. Add Design Sources

Add all Verilog modules inside the `rtl` directory.

## 3. Add Simulation Sources

Add the required testbench files:

```text
elapsed_timer_tb.v
top_tb.v
```

## 4. Add Constraints

Add:

```text
NexysA7.xdc
```

to the project.

## 5. Select the Top Module

For FPGA implementation:

```text
top.v
```

should be selected as the design top.

For timer behavioral simulation:

```text
elapsed_timer_tb.v
```

should be selected as the simulation top.

## 6. Run Behavioral Simulation

Go to:

```text
Flow Navigator
    → Simulation
        → Run Simulation
            → Run Behavioral Simulation
```

Observe:

```text
clk
rst
start
stop
running
bcd_seconds
```

## 7. Synthesize

Run:

```text
Run Synthesis
```

## 8. Implement

Run:

```text
Run Implementation
```

## 9. Generate Bitstream

Run:

```text
Generate Bitstream
```

## 10. Program the FPGA

Open:

```text
Hardware Manager
```

Connect the Nexys A7 board and program the generated bitstream.

---

# 📊 Expected Working

The complete system works approximately as follows:

```text
             User Input
                 │
                 ▼
          ┌──────────────┐
          │   APB Master │
          └──────┬───────┘
                 │
                 ▼
          ┌──────────────┐
          │ APB Decoder  │
          └──────┬───────┘
                 │
        ┌────────┼────────┐
        │        │        │
        ▼        ▼        ▼
      FIFO      PWM     Timer
        │        │        │
        └────────┼────────┘
                 │
                 ▼
          7-Segment Display
```

The timer provides information about the elapsed processing time of the selected operation.

---

# ⭐ Key Features

* ✅ AMBA APB3 communication
* ✅ Modular Verilog design
* ✅ APB master
* ✅ APB address decoder
* ✅ FIFO peripheral
* ✅ PWM peripheral
* ✅ Elapsed-time timer
* ✅ 7-segment display interface
* ✅ LED-based debugging
* ✅ Behavioral simulation support
* ✅ FPGA implementation support
* ✅ Nexys A7-100T compatible

---

# 🔮 Future Improvements

Possible future enhancements include:

* UART interface for external commands
* More APB peripherals
* Configurable timer resolution
* Countdown timer mode
* Interrupt support
* FIFO depth expansion
* More PWM channels
* Register-based timer control
* Performance measurement of individual APB transactions
* Automated testbench verification

---

# 👩‍💻 Authors

**Jiya Mulla**
Electronics and Telecommunication Engineering
Rajarambapu Institute of Technology, Islampur

**Project:** FPGA-Based APB3 FIFO, Elapsed-Time Timer & PWM Controller

---

# 📜 License

This project is developed for **academic and educational purposes**.

You are free to study and modify the source code with appropriate attribution.
