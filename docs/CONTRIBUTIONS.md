# ProtocolX — Team Contribution Details (Phase I)

This document gives an honest and clear breakdown of what each team member worked on for Phase I of our 5-Stage Pipelined RISC-V Processor project.

---

## Team Roster & Roles

| S.No | Name | Enrollment No | Designated Role | Primary Work Area |
|:---:|:---|:---:|:---|:---|
| 1 | **Naveen Kumar** | 2401020041 | Project Lead & Primary RTL Developer | Core processor RTL, pipeline registers, datapath integration |
| 2 | **Aditya Raj** | 2401010032 | Technical Lead, Pipeline Design & Verification | Hazard detection unit, data forwarding, testbench writing, simulation runs |
| 3 | **Archit Mamodiya** | 2401010095 | Literature Review & Research | Researching RISC-V ISA, studying standard pipeline hazards and academic papers |
| 4 | **Shagun Vishnoi** | 2401020060 | IEEE Report & Documentation | Writing and organizing the IEEE Phase I report, compiling references and formatting |
| 5 | **Ritik Ranjan** | 2401010388 | Architecture Diagrams, GitHub Documentation & Video Prep | SVG architecture block diagram, diagram guide, video script and demo plan |

---

## Detailed Task Breakdown

### 1. Naveen Kumar (2401020041) — Project Lead & Primary RTL Developer
- Planned the top-level architecture and overall timeline for Phase I.
- Implemented the core Verilog modules:
  - `rtl/riscv_defines.vh` (Constants, opcodes, funct codes, and ALU operations).
  - `rtl/alu.v` (Arithmetic Logic Unit for RV32I basic instructions).
  - `rtl/reg_file.v` (32-register bank, x0 hardwired zero, synchronous write, same-cycle bypass).
  - `rtl/imm_gen.v` (Immediate sign-extension for I, S, B, U, J types).
  - `rtl/control_unit.v` (Main instruction decoder and ALU control).
  - `rtl/pipe_if_id.v`, `rtl/pipe_id_ex.v`, `rtl/pipe_ex_mem.v`, `rtl/pipe_mem_wb.v` (The 4 pipeline registers).
  - `rtl/riscv_core.v` (Connecting all stages, wires, and modules together into the full processor core).

### 2. Aditya Raj (2401010032) — Technical Lead, Pipeline Design & Verification
- Designed the Hazard and Forwarding logic:
  - `rtl/hazard_unit.v` (Detecting EX/MEM and MEM/WB forwarding for RAW data hazards, 1-cycle stall for load-use hazards, and pipeline flushes on taken branches).
  - `rtl/execution_unit.v` (Forwarding multiplexers, branch condition checker, target address calculation).
- Wrote the testbenches and created hex test programs:
  - `testbench/tb_alu.v` (ALU unit tests).
  - `testbench/tb_reg_file.v` (Register file unit tests).
  - `testbench/tb_hazard_unit.v` (Hazard logic unit tests).
  - `testbench/tb_riscv_core.v` (Full pipeline arithmetic tests).
  - `testbench/tb_riscv_hazard.v` (RAW hazard forwarding tests).
  - `testbench/tb_riscv_mem.v` (Data memory load/store and stall tests).
  - `testbench/tb_riscv_branch.v` (Branch condition and flush tests).
- Automated test runs using Icarus Verilog (`simulation/run_sim.sh`) and verified output waveforms.

### 3. Archit Mamodiya (2401010095) — Literature Review & Research
- Studied the official RISC-V RV32I specification (Volume I: Unprivileged ISA).
- Researched how 5-stage pipelines handle data hazards and control hazards in textbooks (Patterson & Hennessy) and research publications.
- Conducted a comparative study of beginner-friendly and open-source academic RISC-V cores.
- Authored the Literature Review section for the Phase I IEEE project report.

### 4. Shagun Vishnoi (2401020060) — IEEE Report & Documentation
- Structured and formatted the official Phase I project report according to IEEE conference standards.
- Drafted the Abstract, Introduction, Proposed Solution, and References sections.
- Maintained consistent project documentation across Markdown (`docs/IEEE_Phase1_Project_Report.md`) and LaTeX (`docs/IEEE_Phase1_Project_Report.tex`).
- Checked that all citations and references are genuine and properly cited.

### 5. Ritik Ranjan (2401010388) — Architecture Diagrams, GitHub Documentation & Video Prep
- Designed the clean vector architecture block diagram (`diagrams/protocolx_pipeline_architecture.svg`).
- Wrote the step-by-step architectural walkthrough guide (`diagrams/diagram_description.md`).
- Prepared the 5-minute prototype presentation script (`video/VIDEO_DEMO_SCRIPT.md`) dividing speaking time across all 5 members.
- Created the video link placeholder document (`video/VIDEO_LINK.md`) for the final demonstration recording.
- Assisted in structuring the GitHub repository README.
