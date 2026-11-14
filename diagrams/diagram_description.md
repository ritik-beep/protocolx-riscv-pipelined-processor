# ProtocolX 5-Stage RISC-V Pipeline Architecture

**Prepared by:** Ritik Ranjan (2401010388)  
**Project:** ProtocolX — 5-Stage Pipelined RISC-V (RV32I) Processor  

---

## 1. Overview

This document explains our processor's architecture diagram located in [`protocolx_pipeline_architecture.svg`](protocolx_pipeline_architecture.svg). 

Our processor takes a 32-bit RISC-V instruction and runs it through five sequential stages. Instead of waiting for one instruction to completely finish before starting the next one, each stage works on a different instruction at the same clock cycle, just like an assembly line.

```
Cycle 1:  [ IF ]
Cycle 2:  [ ID ] [ IF ]
Cycle 3:  [ EX ] [ ID ] [ IF ]
Cycle 4:  [ MEM] [ EX ] [ ID ] [ IF ]
Cycle 5:  [ WB ] [ MEM] [ EX ] [ ID ] [ IF ]
```

---

## 2. Walkthrough of the 5 Stages

### Stage 1: Instruction Fetch (IF)
- **What it does:** Reads the next instruction from instruction memory.
- **Key parts:**
  - **Program Counter (PC):** Holds the memory address of the current instruction. It increases by 4 every cycle (`PC + 4`) because each RISC-V instruction is 4 bytes (32 bits) long.
  - **Instruction Memory:** A 4KB memory block holding our program machine code.
  - **PC Mux:** If a branch or jump is taken, the PC changes to the branch target address instead of `PC + 4`.

### Stage 2: Instruction Decode (ID)
- **What it does:** Breaks down the 32-bit instruction to understand what operation needs to be done and reads the required input registers.
- **Key parts:**
  - **Control Unit:** Decodes opcode and funct fields to create control signals (such as ALU operation, register write enable, memory read/write).
  - **Register File:** 32 general-purpose 32-bit registers (`x0` through `x31`). `x0` is always hardwired to 0. It can read two registers at the same time and write one register on the clock edge.
  - **Immediate Generator:** Extracts numbers (constants/offsets) from instructions (I, S, B, U, J types) and sign-extends them to 32 bits.

### Stage 3: Execute (EX)
- **What it does:** Performs calculations and computes branch addresses.
- **Key parts:**
  - **Arithmetic Logic Unit (ALU):** Performs addition, subtraction, AND, OR, XOR, shifts (SLL, SRL, SRA), and comparisons (SLT, SLTU).
  - **Forwarding Muxes:** Selects whether the ALU inputs come from the register file or are forwarded directly from later stages to prevent data waiting stalls.
  - **Branch Adder:** Calculates `PC + Immediate` to know where to jump if a branch condition (like `BEQ`, `BNE`) is true.

### Stage 4: Memory Access (MEM)
- **What it does:** Reads data from or writes data to the data RAM.
- **Key parts:**
  - **Data Memory:** 4KB RAM. For a store instruction (`SW`), it writes data to memory. For a load instruction (`LW`), it reads data from memory. Other instructions simply pass their ALU result through to the next stage.

### Stage 5: Write-Back (WB)
- **What it does:** Writes the final calculation or loaded memory value back into the destination register (`rd`) in the Register File.
- **Key parts:**
  - **Write-Back Mux:** Chooses between the ALU result, memory read data, or `PC + 4` (for jump link instructions).

---

## 3. The 4 Pipeline Registers

Between each stage, we have pipeline registers that store the intermediate results and control signals on every clock edge:
1. **IF/ID Register:** Carries the fetched instruction and PC from Stage 1 to Stage 2. Supports hold (stall) and flush (NOP).
2. **ID/EX Register:** Carries decoded register values, immediate value, PC, and control signals from Stage 2 to Stage 3.
3. **EX/MEM Register:** Carries ALU calculation results, forwarded store data, and memory control signals from Stage 3 to Stage 4.
4. **MEM/WB Register:** Carries loaded data and ALU results from Stage 4 to Stage 5.

---

## 4. How Hazards Are Solved

- **RAW Data Hazards (Read After Write):**
  If instruction 2 needs a register calculated by instruction 1, our **Data Forwarding Unit** forwards the answer directly from the EX/MEM or MEM/WB register into the ALU inputs. This avoids wasting clock cycles.
- **Load-Use Data Hazard:**
  When an instruction immediately uses the value loaded by `LW`, the data isn't ready in time for simple forwarding. Our **Hazard Unit** automatically detects this, pauses PC and IF/ID for 1 clock cycle, and inserts a single bubble (NOP).
- **Control Hazards (Branch Taken):**
  When a conditional branch is taken, the instructions already fetched behind it in the pipeline are wrong. The Hazard Unit flushes them (turns them into NOPs) so they don't modify any registers or memory.
