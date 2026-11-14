# PROTOCOLX: Design and Implementation of a 5-Stage Pipelined RISC-V Processor (Phase I Report)

**Team Members:**  
- **Naveen Kumar** (Roll No: 2401020041) — Project Lead & Primary RTL Developer  
- **Aditya Raj** (Roll No: 2401010032) — Technical Lead, Pipeline Design & Verification  
- **Archit Mamodiya** (Roll No: 2401010095) — Literature Review & Research  
- **Shagun Vishnoi** (Roll No: 2401020060) — IEEE Report & Documentation  
- **Ritik Ranjan** (Roll No: 2401010388) — Architecture Diagrams, GitHub Documentation & Video Prep  

**Department of Computer Science & Applications**  
**Submission Date:** November 2026  

---

## Abstract

In modern computer architecture, pipelining is the fundamental technique used to increase instruction throughput and make CPUs faster. Instead of waiting for one instruction to finish all its steps before starting the next one, a pipelined processor overlaps the execution of multiple instructions like an assembly line. 

In this Phase I project, our team (ProtocolX) designed, implemented, and verified a 32-bit 5-stage pipelined processor based on the open-source RISC-V (RV32I) instruction set architecture. We implemented the five standard pipeline stages: Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory Access (MEM), and Write-Back (WB), separated by four pipeline registers. To ensure our processor executes code correctly without wrong answers or crashes, we designed a Hazard Detection and Forwarding Unit. This unit resolves Read-After-Write (RAW) data hazards through operand forwarding, handles load-use data hazards by inserting a 1-cycle stall bubble, and flushes instructions fetched during taken branches. 

All modules were written in Verilog HDL and thoroughly simulated using Icarus Verilog. We verified the core using a test suite covering arithmetic/logic instructions, data hazards, memory load/stores, and conditional branches. All 42 verification assertions passed with zero errors, giving us a solid, working hardware prototype for Phase I.

---

## 1. Introduction

When we first learn about computer organization, processors are usually introduced as single-cycle machines. In a single-cycle CPU, every instruction must complete fetching, decoding, arithmetic calculation, memory access, and register write-back within a single clock cycle. Because the clock period must be stretched to accommodate the longest possible instruction (typically `LW`), the CPU runs at a low frequency, and most hardware blocks sit idle during the cycle.

Pipelining breaks the execution of an instruction into independent, balanced stages. In our project, we chose the classic 5-stage RISC architecture. The open-source RISC-V instruction set (specifically RV32I) is an ideal foundation for our project because of its clean, modular, and fixed 32-bit instruction formats, free from legacy complexities found in older architectures like x86.

Our primary goal in Phase I was to build a clean, working, and verifiable 5-stage pipelined RISC-V core in Verilog HDL that can run basic RV32I programs while correctly managing pipeline hazards.

---

## 2. Literature Review

Before starting RTL development, we surveyed textbooks and academic literature to understand how pipelining is designed and how pipeline hazards have been historically tackled.

1. **RISC-V Instruction Set Architecture:**  
   Waterman and Asanović [1] introduced the open RISC-V ISA. The base integer ISA (RV32I) uses only 4 primary instruction formats (R-type, I-type, S-type, and U-type), along with two slight variations (B-type for branches and J-type for jumps). This makes the hardware decoder simple and fast, which is very helpful for college students building a processor from scratch.

2. **Classic Pipelined Processors:**  
   Patterson and Hennessy [2] provide the foundation for 5-stage RISC microarchitectures. They explain why pipeline registers are necessary to isolate each stage and how instruction execution can overlap across successive clock cycles.

3. **Pipeline Hazards and Solutions:**  
   Hennessy and Patterson [3] categorized hazards into three types:
   - *Structural Hazards:* Hardware resource conflicts (solved in our core by separating instruction memory and data memory into a Harvard-style architecture).
   - *Data Hazards (RAW):* An instruction depends on the result of a previous instruction that is still in the pipeline. Rather than stalling every time, operands can be forwarded directly from pipeline registers to the ALU inputs.
   - *Control Hazards:* Caused by branches and jumps when the next PC depends on an uncompleted instruction.

4. **Existing Open-Source RISC-V Cores:**  
   We also studied simple existing open-source RISC-V educational cores such as PicoRV32 by Claire Wolf [4] and SERV by Olof Kindgren [5]. While PicoRV32 uses a state-machine based multi-cycle approach and SERV is bit-serial, our goal for ProtocolX was to build a true 5-stage parallel pipeline with hardware hazard interlocking and forwarding.

---

## 3. Proposed Solution & Architecture

Our processor consists of five distinct pipeline stages, four pipeline barrier registers, and a central Hazard Detection & Forwarding Unit.

### 3.1 The Five Pipeline Stages

1. **Instruction Fetch (IF):**
   - Holds the 32-bit Program Counter (PC).
   - Increments the PC by 4 on each rising clock edge (`PC + 4`).
   - If a branch is taken or a jump occurs, a multiplexer selects the target address computed in the EX stage instead of `PC + 4`.
   - Fetches the 32-bit instruction word from the instruction memory.

2. **Instruction Decode (ID):**
   - Breaks the 32-bit instruction into opcode, register source fields (`rs1`, `rs2`), destination register (`rd`), and function codes (`funct3`, `funct7`).
   - Contains the 32-entry Register File (`x0` to `x31`). Register `x0` is hardwired to 0. It allows reading two registers simultaneously and writing one register synchronously. A write-through bypass is included so that if an instruction reads a register in the same clock cycle it is being written by the write-back stage, it receives the updated data immediately.
   - The Immediate Generator sign-extends immediate constants according to the instruction format (I, S, B, U, or J).
   - The Control Unit decodes control signals for the downstream pipeline stages.

3. **Execute (EX):**
   - The Arithmetic Logic Unit (ALU) performs 32-bit calculations: addition, subtraction, bitwise AND/OR/XOR, logical/arithmetic shifts (SLL, SRL, SRA), and signed/unsigned comparisons (SLT, SLTU).
   - Forwarding multiplexers choose whether each ALU input comes from the ID/EX register, the EX/MEM register, or the MEM/WB register.
   - A dedicated branch adder computes the branch target address: $\text{Target} = \text{PC} + \text{Immediate}$.
   - Evaluates branch conditions (e.g., `BEQ`, `BNE`, `BLT`, `BGE`).

4. **Memory Access (MEM):**
   - Interacts with the Data Memory (4KB RAM model).
   - For store instructions (`SW`), writes the forwarded data to memory at the address calculated by the ALU.
   - For load instructions (`LW`), reads 32-bit data from memory.
   - Instructions that do not access memory simply pass their ALU result through to the MEM/WB register.

5. **Write-Back (WB):**
   - A final multiplexer selects between the ALU result, memory read data, or `PC + 4` (for link instructions like `JAL`).
   - The selected value is written into the destination register (`rd`) in the Register File when `RegWrite` is enabled.

### 3.2 The Pipeline Registers

Between stages, dedicated register modules latch the data and control signals on every clock tick:
- **`pipe_if_id`:** Latches PC, `PC + 4`, and the fetched instruction. Supports an enable line (to freeze during stalls) and a flush line (to clear to NOP).
- **`pipe_id_ex`:** Latches decoded register values, immediate constant, PC, register addresses, and control flags. Supports a synchronous flush line.
- **`pipe_ex_mem`:** Latches the ALU calculation result, memory write data, destination register address, and memory control flags.
- **`pipe_mem_wb`:** Latches the loaded memory data, ALU result, and write-back control flags.

### 3.3 Hazard Detection and Forwarding Unit

- **Data Forwarding (RAW Hazards):**  
  When an instruction in the EX stage needs a register that was just computed by an instruction currently in the MEM stage or WB stage, data is forwarded directly into the ALU input mux. This resolves back-to-back register dependencies with zero lost clock cycles.
- **Load-Use Data Hazard:**  
  Because load instructions only retrieve data from memory at the end of the MEM stage, an instruction that immediately uses the loaded data cannot get it through simple EX-stage forwarding. The Hazard Unit detects this condition:
  $$\text{MemRead}_{\text{EX}} = 1 \quad \text{AND} \quad (rd_{\text{EX}} = rs1_{\text{ID}} \;\text{OR}\; rd_{\text{EX}} = rs2_{\text{ID}})$$
  When detected, it disables the PC update (`pc_write = 0`), disables the IF/ID register update (`if_id_write = 0`), and flushes the ID/EX register with a NOP bubble for exactly 1 cycle.
- **Control Hazards (Branches):**  
  When a conditional branch evaluates to true in the EX stage, the processor flushes the instructions that were speculatively fetched in the IF/ID and ID/EX registers, and redirects the PC to the computed target address.

---

## 4. Verification and Simulation Results

We verified our design using the open-source Icarus Verilog simulator (`iverilog` v13.0) and GTKWave. We wrote individual unit testbenches and full processor integration testbenches.

### 4.1 Test Summary

| Test Suite | Purpose | Assertions | Result |
|:---|:---|:---:|:---:|
| `tb_alu.v` | Unit test of all ALU operations | 10 | **PASS (10/10)** |
| `tb_reg_file.v` | Dual-port reads, write port, and x0 zero check | 3 | **PASS (3/3)** |
| `tb_hazard_unit.v` | Forwarding selects, stall signal, and branch flush | 4 | **PASS (4/4)** |
| `tb_riscv_core.v` | Complete pipeline arithmetic program (`prog_arithmetic.hex`) | 10 | **PASS (10/10)** |
| `tb_riscv_hazard.v` | Back-to-back RAW data hazard forwarding (`prog_hazard.hex`) | 4 | **PASS (4/4)** |
| `tb_riscv_mem.v` | Store word, Load word, and 1-cycle stall (`prog_load_store.hex`) | 6 | **PASS (6/6)** |
| `tb_riscv_branch.v` | Branch taken condition and speculative instruction flush (`prog_branch.hex`) | 5 | **PASS (5/5)** |

Across all testbenches, **42 out of 42 assertions passed (100% success rate)**.

### 4.2 Waveform and Cycle Traces
Real simulation logs were generated and saved in `simulation/simulation_results.log`, and waveform files (`.vcd`) were generated for each test suite. In the branch test, we clearly observed that when the branch was taken at Cycle 4, both `if_id_flush` and `id_ex_flush` went high, and the instructions at addresses `0x0C` and `0x10` were converted to NOPs, preventing any incorrect writes to registers `x3` and `x4`.

---

## 5. Phase I Scope and Future Work (Phase II)

In accordance with our project rules, we clearly identify what has been completed and what is planned for Phase II:

### Completed in Phase I:
- Full 5-stage pipeline datapath (IF, ID, EX, MEM, WB).
- All 4 pipeline registers with stall and flush capabilities.
- 32-bit RV32I integer instructions: R-type (`ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLL`, `SRL`, `SRA`, `SLT`, `SLTU`), I-type arithmetic (`ADDI`, `ANDI`, `ORI`, `XORI`, `SLLI`, `SRLI`, `SRAI`, `SLTI`, `SLTIU`), Memory transfer (`LW`, `SW`), Branch (`BEQ`, `BNE`, `BLT`, `BGE`), and Jump (`JAL`, `JALR`).
- Hardware forwarding unit and load-use hazard stall unit.
- Full verification suite with waveform generation.

### Pending / Planned for Phase II:
- Control and Status Registers (CSRs) for exception handling.
- Support for hardware timer interrupts and external interrupts.
- Dynamic branch prediction (e.g., 2-bit saturating counter branch history table).
- Multiplication and division hardware extension (RV32M).
- Synthesis and FPGA prototype deployment on a Xilinx Artix-7 / Basys 3 board.

---

## 6. Individual Team Contributions

| Team Member | Enrollment No | Core Responsibilities & Contributions |
|:---|:---:|:---|
| **Naveen Kumar** | 2401020041 | **Project Lead & Primary RTL Developer:** Developed processor core datapath, ALU, register file, pipeline registers, and control unit integration. |
| **Aditya Raj** | 2401010032 | **Technical Lead, Pipeline Design & Verification:** Designed hazard detection and forwarding unit, authored all testbenches, created hex test programs, and ran automated simulation verification. |
| **Archit Mamodiya** | 2401010095 | **Literature Review & Research:** Researched RISC-V unprivileged specification, studied comparative open-source processor cores, and authored literature review. |
| **Shagun Vishnoi** | 2401020060 | **IEEE Report & Documentation:** Structured and authored the IEEE Phase I report, compiled authentic references, and maintained documentation accuracy. |
| **Ritik Ranjan** | 2401010388 | **Architecture Diagrams & Video Preparation:** Created vector pipeline architecture diagrams, authored diagram walkthrough, created demo video presentation script, and set up video links. |

---

## 7. References

[1] A. Waterman and K. Asanović, "The RISC-V Instruction Set Manual, Volume I: Unprivileged ISA," Version 20191213, RISC-V Foundation, Dec. 2019.  
[2] D. A. Patterson and J. L. Hennessy, *Computer Organization and Design: The Hardware/Software Interface (RISC-V Edition)*, Morgan Kaufmann, 2017.  
[3] J. L. Hennessy and D. A. Patterson, *Computer Architecture: A Quantitative Approach*, 6th ed., Morgan Kaufmann, 2019.  
[4] C. Wolf, "PicoRV32 — A Size-Optimized RISC-V CPU," YosysHQ GitHub Repository, 2019. [Online]. Available: https://github.com/YosysHQ/picorv32  
[5] O. Kindgren, "SERV: The SErial RISC-V Core," Qamcom Research & Technology, 2020. [Online]. Available: https://github.com/olofk/serv  
[6] S. Harris and D. Harris, *Digital Design and Computer Architecture (RISC-V Edition)*, Morgan Kaufmann, 2021.  
