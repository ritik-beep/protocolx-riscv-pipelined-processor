# ProtocolX — Phase I Verification & Test Report

**Prepared by:** Aditya Raj (Technical Lead) & Naveen Kumar (RTL Developer)  
**Simulator Used:** Icarus Verilog v13.0 (stable) + VVP runtime on macOS  
**Waveform Output:** Value Change Dump (`.vcd`) files viewable in GTKWave  

---

## 1. Summary of Test Results

All tests written for Phase I have been simulated, checked with automated assertions, and verified. 100% of tests passed with zero failures.

| Testbench | Focus Area | Checks / Assertions | Result | Waveform File |
|:---|:---|:---:|:---:|:---|
| `tb_alu.v` | Arithmetic Logic Unit Operations | 10 operations (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU) | **PASS (10/10)** | — |
| `tb_reg_file.v` | 32-Register Bank & x0 check | 3 checks (normal write/read, x0 hardwired to zero, same-cycle bypass) | **PASS (3/3)** | — |
| `tb_hazard_unit.v` | Forwarding & Stall Logic | 4 checks (EX/MEM fwd, MEM/WB fwd, load-use stall, branch flush) | **PASS (4/4)** | — |
| `tb_riscv_core.v` | Top-Level Pipeline Arithmetic | 10 register value checks (`prog_arithmetic.hex`) | **PASS (10/10)** | `simulation/waveform.vcd` |
| `tb_riscv_hazard.v` | Back-to-Back RAW Data Hazards | 4 register value checks (`prog_hazard.hex`) | **PASS (4/4)** | `simulation/waveform_hazard.vcd` |
| `tb_riscv_mem.v` | Memory Load/Store & Load-Use Stall | 6 checks (register values + DMEM memory words, `prog_load_store.hex`) | **PASS (6/6)** | `simulation/waveform_mem.vcd` |
| `tb_riscv_branch.v` | Branch Taken & Pipeline Flushes | 5 register checks (verifying flushed instructions didn't run, `prog_branch.hex`) | **PASS (5/5)** | `simulation/waveform_branch.vcd` |

**Total Assertions:** 42  
**Total Passed:** 42 (100%)  
**Total Failed:** 0  

---

## 2. Key Verification Findings

### A. Arithmetic & Logic Operations
- Program `prog_arithmetic.hex` executed 10 instructions sequentially through the pipeline.
- Results confirmed that registers `x1` through `x10` received their exact calculated values on their respective write-back cycles.
- Zero-immutability of register `x0` was verified: instructions writing to `x0` did not corrupt the hardwired 0.

### B. RAW Data Hazard Forwarding
- Program `prog_hazard.hex` ran dependent instructions back-to-back:
  ```assembly
  addi x1, x0, 15    # x1 = 15
  addi x2, x1, 5     # x2 uses x1 immediately (EX/MEM forwarding) -> x2 = 20
  add  x3, x1, x2    # x3 uses both x1 (MEM/WB) and x2 (EX/MEM) -> x3 = 35
  addi x4, x3, 10    # x4 uses x3 immediately -> x4 = 45
  ```
- The simulation confirmed that both ALU inputs received forwarded data without needing stall bubbles. All four registers held their exact expected values.

### C. Load-Use Data Hazard Stalling
- Program `prog_load_store.hex` tested memory access and dependency:
  ```assembly
  addi x1, x0, 100   # x1 = 100
  sw   x1, 0(x0)     # Store 100 to DMEM[0]
  lw   x2, 0(x0)     # Load DMEM[0] into x2
  addi x3, x2, 50    # Load-Use hazard! Depends on x2 immediately.
  ```
- **Observed behavior:** At Cycle 4, the hazard unit detected that the instruction in ID needed `x2` which was still in the EX stage being loaded. It lowered `pc_write` and `if_id_write` to `0` and inserted a NOP into `ID/EX`.
- In Cycle 5, the PC stayed at `0x00000010` (held for 1 cycle). Once `x2` reached write-back/forwarding availability, execution resumed cleanly, yielding `x3 = 150` and `x4 = 150`.

### D. Branch & Control Hazard Flushing
- Program `prog_branch.hex` tested conditional branching:
  ```assembly
  addi x1, x0, 5     # x1 = 5
  addi x2, x0, 5     # x2 = 5
  beq  x1, x2, 12    # Condition met! Jump to PC = PC + 12
  addi x3, x0, 99    # Speculatively fetched (MUST BE FLUSHED)
  addi x4, x0, 99    # Speculatively fetched (MUST BE FLUSHED)
  addi x5, x0, 42    # Target instruction (MUST RUN)
  ```
- **Observed behavior:** At Cycle 4, `branch_taken_ex` went high (`1`). The hazard unit asserted `if_id_flush = 1` and `id_ex_flush = 1`.
- Registers `x3` and `x4` remained `0` throughout the test (the value `99` was never written).
- Register `x5` correctly received `42` (`0x2A`).

---

## 3. Real Simulation Output Logs

The complete, unabridged cycle-by-cycle trace of all test runs is saved in [`simulation/simulation_results.log`](../simulation/simulation_results.log). Anyone can reproduce this identical output by running:
```bash
./simulation/run_sim.sh
```
