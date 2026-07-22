# UART Protocol in Verilog HDL

A complete **UART (Universal Asynchronous Receiver/Transmitter)** implementation in **Verilog HDL** featuring configurable baud rate generation, UART Transmitter, UART Receiver, Transmit FIFO, Receive FIFO, and a comprehensive loopback testbench. The design is modular, synthesizable, and suitable for FPGA and ASIC applications.

---

## Features

- UART Transmitter (TX)
- UART Receiver (RX)
- Configurable Baud Rate Generator
- Parameterized Data Width
- Transmit (TX) FIFO
- Receive (RX) FIFO
- Loopback Communication Testbench
- Modular RTL Design
- Synthesizable Verilog Code
- Verified using Icarus Verilog & GTKWave

---

## Project Structure

```
UART_Protocol/
│── baud_generator.v
│── uart_tx.v
│── uart_rx.v
│── uart_fifo.v
│── uart_top.v
│── tb_uart_top.v
│── README.md
```

---

## Architecture

```
               +----------------+
               | Baud Generator |
               +--------+-------+
                        |
                        |
        +---------------+---------------+
        |                               |
        v                               v
+---------------+               +---------------+
|   TX FIFO     |               |   RX FIFO     |
+-------+-------+               +-------+-------+
        |                               ^
        v                               |
+---------------+    Serial Line   +---------------+
|   UART TX     | ---------------> |   UART RX     |
+---------------+                  +---------------+
```

---

## Modules

### 1. Baud Generator
- Generates baud tick for UART communication.
- Configurable baud rate.

### 2. UART Transmitter
- Converts parallel data into serial format.
- Generates:
  - Start Bit
  - Data Bits
  - Stop Bit

### 3. UART Receiver
- Samples incoming serial data.
- Reconstructs received byte.
- Generates receive done signal.

### 4. TX FIFO
- Buffers outgoing data.
- Prevents transmitter underflow.

### 5. RX FIFO
- Buffers incoming data.
- Prevents receiver overflow.

### 6. UART Top
Integrates:
- Baud Generator
- UART TX
- UART RX
- TX FIFO
- RX FIFO

---

## Simulation

The design is verified using a **loopback testbench** where the transmitter output is directly connected to the receiver.

```
assign rx = tx;
```

### Example Transmission

```
Input:
HELLO

Output:
HELLO
```

Simulation Log

```
TX START data=48
RX_DONE data=48

TX START data=45
RX_DONE data=45

TX START data=4C
RX_DONE data=4C

TX START data=4C
RX_DONE data=4C

TX START data=4F
RX_DONE data=4F

Time=12000430000 Data=48 (H)
Time=12000470000 Data=45 (E)
Time=12000510000 Data=4C (L)
Time=12000550000 Data=4C (L)
Time=12000590000 Data=4F (O)
```

---

## Test Cases

- ✔ ASCII String Transmission
- ✔ Loopback Verification
- ✔ FIFO Read/Write
- ✔ Continuous Data Transfer
- ✔ Start Bit Detection
- ✔ Stop Bit Verification
- ✔ Parameterized Data Width
- ✔ Baud Rate Synchronization

---

## Tools Used

- Verilog HDL
- Icarus Verilog
- GTKWave
- Visual Studio Code

---

## How to Run

### Compile

```bash
iverilog -o uart_sim *.v
```

### Run

```bash
vvp uart_sim
```

### View Waveform

```bash
gtkwave uart.vcd
```

---

## Future Improvements

- Configurable parity bit
- Multiple stop bits
- Flow control (RTS/CTS)
- Interrupt support
- Error detection (Framing, Overrun, Parity)
- FPGA implementation and hardware validation

---

## Learning Outcomes

This project demonstrates:

- UART Serial Communication
- Finite State Machine (FSM) Design
- FIFO Buffer Design
- RTL Design in Verilog
- Digital Communication Protocols
- Simulation & Debugging
- FPGA-Oriented Design Practices

---

## Author

**Irfan Khan**

Electronics & Communication Engineering  
National Institute of Technology Jalandhar

GitHub: https://github.com/irfannsd
