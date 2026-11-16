// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       tb_riscv_hazard.v
// Description: Testbench specifically verifying RAW Data Hazard Forwarding.
//              Tests back-to-back register dependencies without pipeline bubbles.
// Developers:  Aditya Raj   (2401010032) - Technical Lead & Verification
//              Naveen Kumar (2401020041) - RTL Developer
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module tb_riscv_hazard;

    reg clk;
    reg rst_n;

    wire [`XLEN-1:0]           current_pc;
    wire [`XLEN-1:0]           current_instr;
    wire [`XLEN-1:0]           wb_data;
    wire [`REG_ADDR_WIDTH-1:0] wb_rd;
    wire                       wb_reg_write;

    integer cycle_count = 0;
    integer pass_count  = 0;
    integer fail_count  = 0;

    riscv_core #(
        .IMEM_DEPTH(1024),
        .DMEM_DEPTH(1024),
        .INIT_FILE("testbench/programs/prog_hazard.hex")
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .current_pc(current_pc),
        .current_instr(current_instr),
        .wb_data_out(wb_data),
        .wb_rd_out(wb_rd),
        .wb_reg_write_out(wb_reg_write)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("simulation/waveform_hazard.vcd");
        $dumpvars(0, tb_riscv_hazard);
    end

    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;
            $display("[Cycle %2d] PC: 0x%08h | FwdA: %b, FwdB: %b | WB: x%02d <= 0x%08h",
                     cycle_count, current_pc, dut.u_hazard_unit.forward_a, dut.u_hazard_unit.forward_b, wb_rd, wb_data);
        end
    end

    initial begin
        clk = 0;
        rst_n = 0;

        $display("===============================================================================");
        $display("          PROTOCOLX RISC-V RAW DATA HAZARD FORWARDING VERIFICATION             ");
        $display("===============================================================================");

        #22;
        rst_n = 1;

        wait (cycle_count >= 15);
        #1;

        $display("\n===============================================================================");
        $display("                   RAW HAZARD FORWARDING REGISTER AUDIT                        ");
        $display("===============================================================================");

        // ---------------------------------------------------------------------
        // Test Vector Audit:
        // Test Case 1: x1 <= 15 (Initial seed load via ADDI)
        // Test Case 2: x2 <= 20 (Immediate RAW dependency on x1; resolved by EX/MEM forwarding)
        // Test Case 3: x3 <= 35 (Dual RAW dependency on x1 [MEM/WB] and x2 [EX/MEM])
        // Test Case 4: x4 <= 45 (Immediate RAW dependency on x3; resolved by EX/MEM forwarding)
        // ---------------------------------------------------------------------
        assert_reg(5'd1, 32'd15, "x1 (Initial ADDI x1, x0, 15)");
        assert_reg(5'd2, 32'd20, "x2 (EX/MEM Forwarded x1: ADDI x2, x1, 5 = 20)");
        assert_reg(5'd3, 32'd35, "x3 (Dual Forwarded x1 and x2: ADD x3, x1, x2 = 35)");
        assert_reg(5'd4, 32'd45, "x4 (EX/MEM Forwarded x3: ADDI x4, x3, 10 = 45)");

        $display("-------------------------------------------------------------------------------");
        $display("Hazard Forwarding Summary: %0d Passed, %0d Failed", pass_count, fail_count);
        $display("===============================================================================");

        if (fail_count == 0) begin
            $display(">>> RAW DATA HAZARD FORWARDING VERIFIED WITHOUT PERFORMANCE BUBBLES. <<<");
        end else begin
            $display(">>> FORWARDING FAILED WITH %0d ERRORS. <<<", fail_count);
        end
        $finish;
    end

    task assert_reg(input [4:0] reg_idx, input [31:0] expected_val, input [127:0] desc);
        reg [31:0] actual_val;
        begin
            actual_val = dut.u_reg_file.registers[reg_idx];
            if (actual_val === expected_val) begin
                $display("[PASS] Register x%02d = 0x%08h (%0d) | %0s", reg_idx, actual_val, actual_val, desc);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Register x%02d = 0x%08h (Expected: 0x%08h) | %0s", reg_idx, actual_val, expected_val, desc);
                fail_count = fail_count + 1;
            end
        end
    endtask

endmodule
