# FPGA-Based APB3 FIFO, PWM, UART & Elapsed Timer

An FPGA-based **AMBA APB3 peripheral system** implemented in Verilog HDL on the **Digilent Nexys A7-100T** FPGA board.

The project integrates an **APB3 Master, Address Decoder, FIFO, PWM Controller, UART Interface, and an Elapsed-Time Timer**. The timer measures the time taken between a FIFO write operation and a FIFO read operation and displays the elapsed time on the onboard **4-digit 7-segment display**.

---

## 🚀 Project Overview

This project demonstrates how multiple peripherals can communicate through the **AMBA APB3 protocol**.

The APB master generates peripheral transactions, while the decoder selects the appropriate slave based on the APB address.

### Main peripherals

* APB3 Master
* APB3 Address Decoder
* FIFO Memory
* APB FIFO Slave
* PWM Slave
* UART Slave
* Baud Rate Generator
* UART Transmitter
* Elapsed-Time Timer
* 4-Digit 7-Segment Display
* Push-button debounce and edge detection

---

## 🧩 System Architecture

```text
                    ┌─────────────────────┐
                    │      APB3 MASTER    │
                    └──────────┬──────────┘
                               │
                         APB3 BUS
                               │
                    ┌──────────▼──────────┐
                    │    APB3 DECODER     │
                    └──────┬───┬───┬──────┘
                           │   │   │
             ┌─────────────┘   │   └─────────────┐
             │                 │                 │
       ┌─────▼─────┐     ┌────▼─────┐     ┌─────▼─────┐
       │    UART   │     │   FIFO   │     │    PWM    │
       │   SLAVE   │     │   SLAVE  │     │   SLAVE   │
       └───────────┘     └────┬─────┘     └───────────┘
                              │
                         ┌────▼────┐
                         │  FIFO   │
                         │ MEMORY  │
                         └────┬────┘
                              │
                    FIFO WRITE / FIFO READ
                              │
                    ┌─────────▼─────────┐
                    │  ELAPSED TIMER   │
                    └─────────┬─────────┘
                              │
                       Elapsed Seconds
                              │
                    ┌─────────▼─────────┐
                    │   7-SEGMENT      │
                    │     DISPLAY       │
                    └───────────────────┘
```

---

## 📍 APB Address Map

| Address | Peripheral    | Function                |
| ------: | ------------- | ----------------------- |
|   `05h` | UART          | UART communication      |
|   `10h` | GPIO / Legacy | Reserved/legacy address |
|   `20h` | FIFO          | FIFO read/write         |
|   `30h` | PWM           | PWM duty-cycle control  |

The elapsed timer is **internally connected to the FIFO operation** and does not require a separate APB address.

---

# ⏱️ Elapsed-Time Timer

The timer measures the time between:

```text
FIFO WRITE → Timer START → FIFO READ → Timer STOP
```

### Timer operation

A successful FIFO write generates:

```text
fifo_wr_en = 1
```

This starts the timer.

The timer then counts:

```text
1 → 2 → 3 → 4 → 5 → ...
```

When a successful FIFO read occurs:

```text
fifo_rd_en = 1
```

the timer stops.

The final elapsed time remains stored and is displayed on the 7-segment display.

### Important behavior

* Timer starts only on the first FIFO write.
* Additional FIFO writes do not restart the timer.
* Timer stops when a FIFO read is successfully performed.
* After stopping, the elapsed value remains frozen.
* The hardware timer uses the 100 MHz Nexys A7 clock.
* For simulation, the clock-per-second value is reduced to make verification faster.

---

# 🗃️ FIFO Operation

The FIFO is an **8-bit, 8-location FIFO**.

```text
Data width  : 8 bits
Depth       : 8
Count       : 0 to 8
```

It uses:

* Write pointer
* Read pointer
* Memory array
* FIFO counter
* Full flag
* Empty flag

### FIFO Write

The FIFO address is:

```text
20h
```

For example:

```text
16'hA520
```

means:

```text
A5 → Data
20 → FIFO Address
```

Therefore:

```text
A5 is written into FIFO
```

A successful write produces:

```text
wr_en = 1
fifo_wr_en = 1
```

and the FIFO count increases.

---

# 📥 FIFO Read

The FIFO read is performed using the **BTND push button** in the current implementation.

When a valid FIFO read occurs:

```text
rd_en = 1
fifo_rd_en = 1
```

The FIFO returns the stored data and the FIFO count decreases.

At the same time:

```text
fifo_rd_en → Timer Stop
```

---

# 🌊 PWM Controller

The PWM peripheral is mapped to:

```text
30h
```

The duty cycle is selected using the lower two bits of the APB write data.

| `pwdata[1:0]` | Duty Cycle |
| :-----------: | ---------: |
|      `00`     |        25% |
|      `01`     |        50% |
|      `10`     |        75% |
|      `11`     |       100% |

The PWM output is available on the FPGA output:

```text
pwm_out
```

---

# 📡 UART

The project includes an APB-connected UART peripheral consisting of:

* UART Slave
* Baud Generator
* UART Transmitter

The UART peripheral is selected using:

```text
05h
```

The UART transmitter output is connected to the FPGA `tx` pin.

---

# 🔘 Push Buttons

The Nexys A7 push buttons are processed using:

```text
Button
   ↓
Synchronizer
   ↓
Debounce
   ↓
Edge Detector
   ↓
Single-cycle Pulse
```

This prevents mechanical button bouncing from generating multiple FIFO operations.

Current controls:

| Input  | Function     |
| ------ | ------------ |
| `btnU` | FIFO Write   |
| `btnD` | FIFO Read    |
| `rst`  | System Reset |

---

# 🔢 7-Segment Display

The onboard 4-digit 7-segment display shows the elapsed timer value.

Example:

```text
0001
0002
0003
0004
0005
```

During timer operation the displayed value increases once per simulated/actual second according to the configured clock frequency.

The display uses multiplexing to drive all four digits.

---

# 💡 LED Debugging

The LEDs are also used for hardware debugging.

| LED  | Signal               |
| ---- | -------------------- |
| LED0 | APB Select           |
| LED1 | APB Enable           |
| LED2 | APB Write            |
| LED3 | APB Transaction Done |
| LED4 | Timer Running        |
| LED5 | FIFO Write Pulse     |
| LED6 | FIFO Read Pulse      |
| LED7 | FIFO Full            |
| LED8 | FIFO Empty           |
| LED9 | PWM Output           |

This makes it easier to observe the internal operation directly on the FPGA board.

---

# 🧪 Behavioral Simulation

A dedicated testbench is included:

```text
top_tb.v
```

The simulation verifies:

1. System reset
2. FIFO write
3. Timer start
4. Timer counting
5. Second FIFO write
6. FIFO read
7. Timer stop
8. Timer value freezing

### Simulation Timer

For practical simulation, the timer parameter is changed from:

```text
100,000,000 clocks/second
```

to:

```text
10 clocks/second
```

This allows the timer behavior to be observed quickly in XSim.

---

# 📊 Simulation Signals

The following signals are useful for waveform verification:

```text
fifo_wr_en
fifo_rd_en
timer_running
timer_seconds
```

FIFO internal signals:

```text
wr_en
rd_en
count
full
empty
```

Expected sequence:

```text
FIFO WRITE
    ↓
fifo_wr_en = 1
    ↓
timer_running = 1
    ↓
timer_seconds = 1, 2, 3, 4...
    ↓
FIFO READ
    ↓
fifo_rd_en = 1
    ↓
timer_running = 0
    ↓
timer_seconds freezes
```

---

# 🛠️ Tools & Technologies

* **Verilog HDL**
* **Xilinx Vivado**
* **XSim Behavioral Simulator**
* **AMBA APB3**
* **FPGA**
* **Nexys A7-100T**
* **UART**
* **FIFO**
* **PWM**
* **7-Segment Display**

---

# 💻 Target Hardware

**Board:**

Digilent Nexys A7-100T

**FPGA:**

```text
XC7A100TCSG324-1
```

**System Clock:**

```text
100 MHz
```

---

# 📁 Project Structure

```text
APB3-FPGA-Project/
│
├── apb3_master.v
├── apb3_decoder.v
│
├── FIFO.v
├── apb_fifo_slave.v
│
├── pwm_slave.v
│
├── uart_slave.v
├── uart_transmitter.v
├── baud_generator.v
│
├── elapsed_timer.v
├── timer_display_mux.v
│
├── debounce.v
├── edge_detector.v
│
├── hex_to_7seg.v
├── display_mux.v
│
├── top.v
├── top_tb.v
│
└── Nexys_A7.xdc
```

---

# ▶️ How to Run

### 1. Open Vivado

Create/open the Vivado project targeting:

```text
XC7A100TCSG324-1
```

### 2. Add Design Sources

Add all `.v` files from the project.

### 3. Add Constraints

Add the Nexys A7 `.xdc` file.

### 4. Set Top Module

Set:

```text
top
```

as the synthesis/implementation top module.

For simulation, use:

```text
top_tb
```

as the simulation top.

### 5. Run Behavioral Simulation

Open:

```text
Flow Navigator
→ Simulation
→ Run Behavioral Simulation
```

Then add the following signals to the waveform:

```text
fifo_wr_en
fifo_rd_en
timer_running
timer_seconds
```

Click:

```text
Run All
```

and observe the timer behavior.

---

# 🔬 Hardware Testing

After successful behavioral simulation:

```text
Synthesis
    ↓
Implementation
    ↓
Generate Bitstream
    ↓
Program FPGA
```

Then:

### FIFO Write

Set the required switch data/address and press:

```text
BTNU
```

The FIFO write occurs and the timer starts.

### FIFO Read

Press:

```text
BTND
```

The FIFO read occurs and the timer stops.

The final elapsed time remains visible on the 7-segment display.

---

# 🎯 Project Objectives

The main objectives of this project are:

* Implement an APB3-based peripheral architecture.
* Interface multiple peripherals through a common APB bus.
* Implement FIFO-based data storage.
* Generate configurable PWM output.
* Implement UART transmission.
* Measure FIFO processing time using an FPGA timer.
* Display elapsed time on a multiplexed 7-segment display.
* Verify the complete system through behavioral simulation.
* Implement and test the design on the Nexys A7 FPGA board.

---

# 📌 Key Learning Outcomes

This project provides practical understanding of:

* AMBA APB3 protocol
* Master-slave communication
* Address decoding
* Memory-based FIFO design
* PWM generation
* UART transmission
* Clock-based timing
* Button debouncing
* Edge detection
* 7-segment multiplexing
* Verilog HDL
* FPGA implementation
* Behavioral simulation and waveform analysis

---

## 👩‍💻 Author

**Jiya Mulla**

Electronics & Telecommunication Engineering

FPGA / Verilog HDL Project

---

## ⭐ Project Highlights

```text
APB3 Master
     +
APB3 Decoder
     +
UART
     +
FIFO
     +
PWM
     +
Elapsed Timer
     +
7-Segment Display
     =
Complete FPGA-Based APB3 Peripheral System
```
