#  Parameterized Sequential ALU with Pipelined Multiplication

A fully parameterized and clocked **Arithmetic Logic Unit (ALU)** designed in **Verilog HDL** supporting arithmetic, logical, comparison, signed operations, shift/rotate operations, and a dedicated pipelined multiplication architecture.

The project also includes a **self-checking verification environment** with a reference model and extensive directed test cases.

---

# 📌 Project Highlights

 Parameterized ALU Architecture  
 Arithmetic + Logical Modes  
 Sequential Clocked Design  
 3-Cycle Pipelined Multiplication  
 Signed Overflow Detection  
 Carry Output Support  
 Comparison Flags  
 Rotate & Shift Operations  
 Error Handling Logic  
 Self-Checking Testbench  
 DUT vs Reference Model Verification  
 Extensive Corner Case Testing  

---

#  ALU Architecture

The ALU is implemented using a **synchronous sequential architecture** operating on the positive edge of the clock.

The design contains:

- Input Sampling Registers
- Arithmetic Unit
- Logical Unit
- Multiplication Pipeline
- Control Unit
- Status Flag Generator
- Error Detection Logic

---

#  Design Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `N` | Operand Width | 8 |
| `M` | Command Width | 4 |

---

#  Operation Modes

## ➤ Arithmetic Mode (`MODE = 1`)

| CMD | Operation |
|-----|------------|
| 0  | Unsigned Addition |
| 1  | Unsigned Subtraction |
| 2  | Addition with Carry In |
| 3  | Subtraction with Borrow |
| 4  | Increment A |
| 5  | Decrement A |
| 6  | Increment B |
| 7  | Decrement B |
| 8  | Compare A and B |
| 9  | `(OPA + 1) × (OPB + 1)` |
| 10 | `(OPA << 1) × OPB` |
| 11 | Signed Addition |
| 12 | Signed Subtraction |

---

## ➤ Logical Mode (`MODE = 0`)

| CMD | Operation |
|-----|------------|
| 0  | AND |
| 1  | NAND |
| 2  | OR |
| 3  | NOR |
| 4  | XOR |
| 5  | XNOR |
| 6  | NOT A |
| 7  | NOT B |
| 8  | Shift Right A |
| 9  | Shift Left A |
| 10 | Shift Right B |
| 11 | Shift Left B |
| 12 | Rotate Left |
| 13 | Rotate Right |

---

#  Multiplication Pipeline

Multiplication operations are implemented using a dedicated **3-cycle pipeline**.

### Multiplication Flow

| Cycle | Operation |
|-------|------------|
| Cycle 1 | Input Sampling |
| Cycle 2 | Pipeline Register Stage |
| Cycle 3 | Multiplication Result Generation |

### Additional Features

- Detects `MODE` or `CMD` changes during multiplication
- Cancels multiplication if operation changes mid-cycle
- Supports consecutive multiplication operations
- Handles invalid input conditions

---

#  Status Flags

| Signal | Description |
|--------|-------------|
| `RES` | Operation Result |
| `COUT` | Carry Output |
| `OFLOW` | Signed Overflow |
| `G` | Greater Than |
| `L` | Less Than |
| `E` | Equal |
| `ERR` | Error Detection Flag |

---

#  Error Handling

The ALU raises the `ERR` flag for:

- Invalid input combinations
- Unsupported commands
- Invalid rotate values
- Incorrect operand validity
- Illegal operation conditions

---

#  Verification Environment

The project includes a **fully self-checking testbench**.

## Verification Features

 DUT vs Reference Model Comparison  
 Automatic PASS/FAIL Reporting  
 Arithmetic Verification  
 Logical Verification  
 Overflow Verification  
 Carry Verification  
 Reset Testing  
 Clock Enable Testing  
 Consecutive Multiplication Testing  
 Pipeline Verification  
 Invalid Input Testing  
 Mode/CMD Change During Multiplication  
 Corner Case Verification  

---

👨‍💻 Author
Ateef Baig

Verilog RTL Design | Digital Design | Verification | FPGA Development
