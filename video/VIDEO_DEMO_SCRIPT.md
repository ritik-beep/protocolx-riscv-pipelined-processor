# ProtocolX — 5-Minute Prototype Video Presentation Script

**Project Title:** 5-Stage Pipelined RISC-V Processor  
**Team Name:** ProtocolX  
**Video Target Duration:** Exactly 4 to 5 minutes  
**Prepared by:** Ritik Ranjan (2401010388)  

---

## Video Outline & Time Breakdown

```
[0:00 - 0:35] Part 1: Project Introduction & Motivation (Naveen)
[0:35 - 1:10] Part 2: Team Member Introductions & Responsibilities (All 5 Members)
[1:10 - 2:00] Part 3: Architecture & Block Diagram Walkthrough (Ritik & Archit)
[2:00 - 3:15] Part 4: Verilog Implementation & Pipeline Stages (Naveen)
[3:15 - 4:30] Part 5: Actual Simulation & Waveform Demonstration (Aditya)
[4:30 - 5:00] Part 6: Summary & Phase II Roadmap (Shagun)
```

---

## Detailed Spoken Script

### Part 1: Project Introduction & Motivation (0:00 – 0:35)
**Speaker: Naveen Kumar (Project Lead)**
> "Hello everyone and respected evaluators. We are team ProtocolX, and today we are presenting Phase I of our college project: the design and verification of a **5-Stage Pipelined RISC-V Processor** implementing the 32-bit RV32I instruction set.
> 
> In traditional single-cycle CPUs, the entire instruction must finish within one long clock cycle, leaving most of the hardware sitting idle. In this project, we broke down execution into five independent stages separated by pipeline registers so that up to five instructions can be processed at the very same time, significantly boosting instruction throughput."

---

### Part 2: Team Member Introductions (0:35 – 1:10)
**Speaker: Naveen Kumar**
> "Before we dive into the hardware, let us introduce our team and what each of us worked on:"

- **Naveen Kumar (2401020041):**  
  > "I served as the Project Lead and Primary RTL Developer, writing the Verilog code for the pipeline stages, ALU, register file, and datapath integration."
- **Aditya Raj (2401010032):**  
  > "I served as Technical Lead for Pipeline Design and Verification, designing the hazard detection and forwarding unit, writing testbenches, and verifying all simulation runs."
- **Archit Mamodiya (2401010095):**  
  > "I led the Literature Review and Research, studying the RISC-V unprivileged specification, pipeline hazard theory, and open-source academic cores."
- **Shagun Vishnoi (2401020060):**  
  > "I managed the IEEE Project Report and documentation, formatting the paper, writing the abstract and methodology, and compiling verified references."
- **Ritik Ranjan (2401010388):**  
  > "I prepared the architecture block diagrams, GitHub documentation, and organized this demonstration video presentation."

---

### Part 3: Architecture & Block Diagram Walkthrough (1:10 – 2:00)
*(Screen shows: `diagrams/protocolx_pipeline_architecture.svg`)*  
**Speaker: Ritik Ranjan & Archit Mamodiya**

**Ritik Ranjan:**
> "Here on the screen is our high-level architecture diagram. Our processor is divided into five color-coded stages:
> 1. **Instruction Fetch (IF)** in blue, where the Program Counter fetches instructions from memory.
> 2. **Instruction Decode (ID)** in green, where the 32-bit register file and control unit decode instructions.
> 3. **Execute (EX)** in orange, where our 32-bit ALU and branch logic do the calculations.
> 4. **Memory (MEM)** in purple, where data is read from or written to RAM.
> 5. **Write-Back (WB)** in teal, where final values are written back into registers."

**Archit Mamodiya:**
> "Between each stage, you see the vertical barrier registers: `IF/ID`, `ID/EX`, `EX/MEM`, and `MEM/WB`. These registers keep the stages isolated so every stage can work on a different instruction simultaneously. 
> 
> Notice the green dashed arrows: that is our **Data Forwarding Unit**. When an instruction needs a value that was just computed in the previous stage, we forward it directly to the ALU without wasting any clock cycles."

---

### Part 4: Verilog Implementation (2:00 – 3:15)
*(Screen shows: VS Code with `rtl/` folder open)*  
**Speaker: Naveen Kumar**
> "Let's take a look at our Verilog source code in the `rtl/` directory.
> 
> - First, `alu.v` handles all arithmetic and bitwise operations including addition, subtraction, AND, OR, XOR, shifts, and signed comparisons.
> - Second, `reg_file.v` models 32 general-purpose 32-bit registers. We made sure `x0` is hardwired to zero so it cannot be accidentally overwritten, and we built in same-cycle write-to-read bypass so there is no delay between write-back and decode.
> - Third, our four pipeline register modules (`pipe_if_id`, `pipe_id_ex`, etc.) feature active-low reset, enable lines for stalling, and synchronous clear lines for flushing.
> - And finally, `riscv_core.v` connects all the modules and buses into a complete top-level processor."

---

### Part 5: Actual Simulation & Waveform Demo (3:15 – 4:30)
*(Screen shows: Terminal executing `./simulation/run_sim.sh` and opening GTKWave)*  
**Speaker: Aditya Raj**
> "Now let's see the processor running live. I am running our automated simulation script in terminal: `./simulation/run_sim.sh`.
> 
> Notice the output on the screen:
> 1. Our ALU unit test passed all 10 operations.
> 2. Our register file test passed all 3 checks.
> 3. Our hazard unit passed all 4 tests.
> 4. And in our top-level processor test, all 10 register assertions passed!
> 
> Let's look closely at the memory and branch tests:
> - In `tb_riscv_mem.v`, when `LW` was immediately followed by a dependent instruction, the Hazard Unit detected the load-use hazard at Cycle 4, paused the PC and IF/ID registers, and injected a 1-cycle bubble.
> - In `tb_riscv_branch.v`, when the `BEQ` condition was true, the pipeline flushed the two instructions fetched along the wrong path. We verified that registers `x3` and `x4` remained zero and were not overwritten.
> 
> In GTKWave, you can clearly see the clock, the PC advancing by 4, the control signals, and the waveform transition on write-back."

---

### Part 6: Conclusion & Phase II Roadmap (4:30 – 5:00)
**Speaker: Shagun Vishnoi**
> "To summarize Phase I: our team has successfully designed, implemented, and verified a 5-stage pipelined RISC-V processor in Verilog with real simulation proof.
> 
> For Phase II, our roadmap includes:
> 1. Adding Control and Status Registers (CSRs) for exception handling.
> 2. Adding hardware timer and external interrupts.
> 3. Implementing dynamic 2-bit branch prediction.
> 4. Adding the RV32M multiplier hardware extension.
> 5. Synthesizing and testing on an FPGA development board.
> 
> Thank you very much for your time!"
