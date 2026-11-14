# =============================================================================
# Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
# File:       Makefile
# Description: Simple, student-friendly build automation for Icarus Verilog.
# =============================================================================

IV = iverilog
VVP = vvp
IVFLAGS = -g2012 -Irtl

all: test

test:
	@echo "Running complete ProtocolX test suite..."
	@bash simulation/run_sim.sh

test_core:
	@echo "Running top-level core arithmetic test..."
	$(IV) $(IVFLAGS) -o simulation/tb_riscv_core.vvp rtl/riscv_defines.vh rtl/*.v testbench/tb_riscv_core.v
	$(VVP) simulation/tb_riscv_core.vvp
	@rm -f simulation/tb_riscv_core.vvp

test_hazard:
	@echo "Running RAW data hazard forwarding test..."
	$(IV) $(IVFLAGS) -o simulation/tb_riscv_hazard.vvp rtl/riscv_defines.vh rtl/*.v testbench/tb_riscv_hazard.v
	$(VVP) simulation/tb_riscv_hazard.vvp
	@rm -f simulation/tb_riscv_hazard.vvp

test_mem:
	@echo "Running data memory and load-use stall test..."
	$(IV) $(IVFLAGS) -o simulation/tb_riscv_mem.vvp rtl/riscv_defines.vh rtl/*.v testbench/tb_riscv_mem.v
	$(VVP) simulation/tb_riscv_mem.vvp
	@rm -f simulation/tb_riscv_mem.vvp

test_branch:
	@echo "Running branch and control hazard flush test..."
	$(IV) $(IVFLAGS) -o simulation/tb_riscv_branch.vvp rtl/riscv_defines.vh rtl/*.v testbench/tb_riscv_branch.v
	$(VVP) simulation/tb_riscv_branch.vvp
	@rm -f simulation/tb_riscv_branch.vvp

test_alu:
	@echo "Running ALU unit test..."
	$(IV) $(IVFLAGS) -o simulation/tb_alu.vvp rtl/alu.v testbench/tb_alu.v
	$(VVP) simulation/tb_alu.vvp
	@rm -f simulation/tb_alu.vvp

clean:
	@echo "Cleaning up generated vvp and temporary simulation files..."
	@rm -f simulation/*.vvp *.vvp
	@echo "Clean completed."
