// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       tb_riscv_branch.v
// Description: Testbench verifying Branch (BEQ) and Control Hazard Flushes.
//              Tests that instructions along the fall-through path are flushed on taken branch.
// Developers:  Aditya Raj   (2401010032) - Technical Lead & Verification
//              Naveen Kumar (2401020041) - RTL Developer
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module tb_riscv_branch;

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
        .INIT_FILE("testbench/programs/prog_branch.hex")
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
        $dumpfile("simulation/waveform_branch.vcd");
        $dumpvars(0, tb_riscv_branch);
    end

    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;
            $display("[Cycle %2d] PC: 0x%08h | BranchTaken: %b | Flush(IF/ID=%b, ID/EX=%b) | WB: x%02d <= 0x%08h",
                     cycle_count, current_pc, dut.branch_taken_ex,
                     dut.u_hazard_unit.if_id_flush, dut.u_hazard_unit.id_ex_flush, wb_rd, wb_data);
        end
    end

    initial begin
        clk = 0;
        rst_n = 0;

        $display("===============================================================================");
        $display("        PROTOCOLX RISC-V BRANCH (BEQ) & CONTROL HAZARD FLUSH VERIFICATION       ");
        $display("===============================================================================");

        #22;
        rst_n = 1;

        wait (cycle_count >= 18);
        #1;

        $display("\n===============================================================================");
        $display("                   CONTROL HAZARD REGISTER AUDIT                               ");
        $display("===============================================================================");

        assert_reg(5'd1, 32'd5,  "x1 (Initial ADDI x1, x0, 5)");
        assert_reg(5'd2, 32'd5,  "x2 (Initial ADDI x2, x0, 5)");
        assert_reg(5'd3, 32'd0,  "x3 (Flushed instruction: MUST REMAIN 0, NOT 99)");
        assert_reg(5'd4, 32'd0,  "x4 (Flushed instruction: MUST REMAIN 0, NOT 99)");
        assert_reg(5'd5, 32'd42, "x5 (Branch target instruction: ADDI x5, x0, 42)");

        $display("-------------------------------------------------------------------------------");
        $display("Branch & Flush Summary: %0d Passed, %0d Failed", pass_count, fail_count);
        $display("===============================================================================");

        if (fail_count == 0) begin
            $display(">>> CONTROL HAZARD PIPELINE FLUSHING FULLY VERIFIED. <<<");
        end else begin
            $display(">>> VERIFICATION FAILED WITH %0d ERRORS. <<<", fail_count);
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
