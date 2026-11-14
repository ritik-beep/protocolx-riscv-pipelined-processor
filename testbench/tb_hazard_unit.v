// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       tb_hazard_unit.v
// Description: Unit testbench for Hazard Detection & Forwarding Unit.
// Developers:  Aditya Raj   (2401010032) - Technical Lead & Pipeline Design
//              Naveen Kumar (2401020041) - RTL Developer
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module tb_hazard_unit;

    reg  [4:0] rs1_id, rs2_id, rd_ex;
    reg        mem_read_ex;
    reg  [4:0] rs1_ex, rs2_ex, rd_mem, rd_wb;
    reg        reg_write_mem, reg_write_wb;
    reg        branch_taken_ex, jump_ex;

    wire       pc_write;
    wire       if_id_write;
    wire       if_id_flush;
    wire       id_ex_flush;
    wire [1:0] forward_a;
    wire [1:0] forward_b;

    integer pass_count = 0;
    integer fail_count = 0;

    hazard_unit dut (
        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .rd_ex(rd_ex),
        .mem_read_ex(mem_read_ex),
        .rs1_ex(rs1_ex),
        .rs2_ex(rs2_ex),
        .rd_mem(rd_mem),
        .reg_write_mem(reg_write_mem),
        .rd_wb(rd_wb),
        .reg_write_wb(reg_write_wb),
        .branch_taken_ex(branch_taken_ex),
        .jump_ex(jump_ex),
        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .if_id_flush(if_id_flush),
        .id_ex_flush(id_ex_flush),
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    initial begin
        $display("==================================================");
        $display(" PROTOCOLX HAZARD DETECTION & FORWARDING UNIT TEST");
        $display("==================================================");

        // Reset all inputs
        rs1_id = 0; rs2_id = 0; rd_ex = 0; mem_read_ex = 0;
        rs1_ex = 0; rs2_ex = 0; rd_mem = 0; rd_wb = 0;
        reg_write_mem = 0; reg_write_wb = 0;
        branch_taken_ex = 0; jump_ex = 0;
        #1;

        // Test 1: EX/MEM Forwarding to operand A (rd_mem == rs1_ex)
        rs1_ex = 5'd3;
        rd_mem = 5'd3;
        reg_write_mem = 1'b1;
        #1;
        if (forward_a === `FWD_MEM_STAGE) begin
            $display("[PASS] Forwarding EX/MEM -> EX (forward_a = 2'b10)");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Forwarding EX/MEM -> EX (forward_a = %b)", forward_a);
            fail_count = fail_count + 1;
        end

        // Test 2: MEM/WB Forwarding to operand B (rd_wb == rs2_ex)
        rs2_ex = 5'd4;
        rd_wb  = 5'd4;
        reg_write_wb = 1'b1;
        #1;
        if (forward_b === `FWD_WB_STAGE) begin
            $display("[PASS] Forwarding MEM/WB -> EX (forward_b = 2'b01)");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Forwarding MEM/WB -> EX (forward_b = %b)", forward_b);
            fail_count = fail_count + 1;
        end

        // Test 3: Load-Use Hazard Detection
        reg_write_mem = 0; reg_write_wb = 0;
        rd_ex = 5'd6;
        mem_read_ex = 1'b1;
        rs1_id = 5'd6; // Dependent instruction in ID stage
        #1;
        if (!pc_write && !if_id_write && id_ex_flush) begin
            $display("[PASS] Load-Use Hazard detected: Stall injected (pc_write=0, if_id_write=0, id_ex_flush=1)");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Load-Use Hazard stall failed: pc_write=%b, if_id_write=%b, id_ex_flush=%b",
                     pc_write, if_id_write, id_ex_flush);
            fail_count = fail_count + 1;
        end

        // Test 4: Branch Taken Flush
        mem_read_ex = 0; rd_ex = 0;
        branch_taken_ex = 1'b1;
        #1;
        if (if_id_flush && id_ex_flush && pc_write && if_id_write) begin
            $display("[PASS] Control Hazard: Branch Taken Flushed IF/ID and ID/EX");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Branch flush failed: if_id_flush=%b, id_ex_flush=%b", if_id_flush, id_ex_flush);
            fail_count = fail_count + 1;
        end

        $display("--------------------------------------------------");
        $display(" Hazard Unit Test Summary: Passed = %0d, Failed = %0d", pass_count, fail_count);
        $display("==================================================");

        if (fail_count == 0) $finish(0);
        else $finish(1);
    end

endmodule
