#!/usr/bin/env bash
# =============================================================================
# Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
# Script:     run_sim.sh
# Description: Automated simulation runner for all unit tests and full pipeline
#              verification testbenches. Uses Icarus Verilog and VVP.
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

LOG_FILE="${SCRIPT_DIR}/simulation_results.log"
echo "================================================================================" > "${LOG_FILE}"
echo "           PROTOCOLX RISC-V 5-STAGE PROCESSOR - FULL VERIFICATION SUITE         " >> "${LOG_FILE}"
echo "                       Execution Date: $(date)                                  " >> "${LOG_FILE}"
echo "================================================================================" >> "${LOG_FILE}"

echo -e "\n>>> 1. Running ALU Unit Test..." | tee -a "${LOG_FILE}"
iverilog -g2012 -Irtl -o "${SCRIPT_DIR}/tb_alu.vvp" rtl/alu.v testbench/tb_alu.v
vvp "${SCRIPT_DIR}/tb_alu.vvp" | tee -a "${LOG_FILE}"
rm -f "${SCRIPT_DIR}/tb_alu.vvp"

echo -e "\n>>> 2. Running Register File Unit Test..." | tee -a "${LOG_FILE}"
iverilog -g2012 -Irtl -o "${SCRIPT_DIR}/tb_reg_file.vvp" rtl/reg_file.v testbench/tb_reg_file.v
vvp "${SCRIPT_DIR}/tb_reg_file.vvp" | tee -a "${LOG_FILE}"
rm -f "${SCRIPT_DIR}/tb_reg_file.vvp"

echo -e "\n>>> 3. Running Hazard Unit Test..." | tee -a "${LOG_FILE}"
iverilog -g2012 -Irtl -o "${SCRIPT_DIR}/tb_hazard_unit.vvp" rtl/hazard_unit.v testbench/tb_hazard_unit.v
vvp "${SCRIPT_DIR}/tb_hazard_unit.vvp" | tee -a "${LOG_FILE}"
rm -f "${SCRIPT_DIR}/tb_hazard_unit.vvp"

echo -e "\n>>> 4. Running Core Pipeline Arithmetic Test..." | tee -a "${LOG_FILE}"
iverilog -g2012 -Irtl -o "${SCRIPT_DIR}/tb_riscv_core.vvp" rtl/riscv_defines.vh rtl/*.v testbench/tb_riscv_core.v
vvp "${SCRIPT_DIR}/tb_riscv_core.vvp" | tee -a "${LOG_FILE}"
rm -f "${SCRIPT_DIR}/tb_riscv_core.vvp"

echo -e "\n>>> 5. Running Core RAW Data Hazard Forwarding Test..." | tee -a "${LOG_FILE}"
iverilog -g2012 -Irtl -o "${SCRIPT_DIR}/tb_riscv_hazard.vvp" rtl/riscv_defines.vh rtl/*.v testbench/tb_riscv_hazard.v
vvp "${SCRIPT_DIR}/tb_riscv_hazard.vvp" | tee -a "${LOG_FILE}"
rm -f "${SCRIPT_DIR}/tb_riscv_hazard.vvp"

echo -e "\n>>> 6. Running Core Memory & Load-Use Stall Test..." | tee -a "${LOG_FILE}"
iverilog -g2012 -Irtl -o "${SCRIPT_DIR}/tb_riscv_mem.vvp" rtl/riscv_defines.vh rtl/*.v testbench/tb_riscv_mem.v
vvp "${SCRIPT_DIR}/tb_riscv_mem.vvp" | tee -a "${LOG_FILE}"
rm -f "${SCRIPT_DIR}/tb_riscv_mem.vvp"

echo -e "\n>>> 7. Running Core Branch & Control Hazard Flush Test..." | tee -a "${LOG_FILE}"
iverilog -g2012 -Irtl -o "${SCRIPT_DIR}/tb_riscv_branch.vvp" rtl/riscv_defines.vh rtl/*.v testbench/tb_riscv_branch.v
vvp "${SCRIPT_DIR}/tb_riscv_branch.vvp" | tee -a "${LOG_FILE}"
rm -f "${SCRIPT_DIR}/tb_riscv_branch.vvp"

echo -e "\n================================================================================" | tee -a "${LOG_FILE}"
echo "           ALL VERIFICATION SUITES COMPLETED SUCCESSFULLY!                      " | tee -a "${LOG_FILE}"
echo "================================================================================" | tee -a "${LOG_FILE}"
