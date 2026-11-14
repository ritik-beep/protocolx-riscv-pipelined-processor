// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       tb_alu.v
// Description: Unit testbench for Arithmetic Logic Unit (ALU).
// Developers:  Aditya Raj   (2401010032) - Technical Lead & Verification
//              Naveen Kumar (2401020041) - RTL Developer
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module tb_alu;

    reg  [3:0]       alu_op;
    reg  [`XLEN-1:0] a;
    reg  [`XLEN-1:0] b;
    wire [`XLEN-1:0] result;
    wire             zero;
    wire             less_than;
    wire             less_than_unsigned;

    integer pass_count = 0;
    integer fail_count = 0;

    alu dut (
        .alu_op(alu_op),
        .a(a),
        .b(b),
        .result(result),
        .zero(zero),
        .less_than(less_than),
        .less_than_unsigned(less_than_unsigned)
    );

    task check_result(input [`XLEN-1:0] expected, input [127:0] test_name);
        begin
            #1;
            if (result === expected) begin
                $display("[PASS] %0s | Result = 0x%08h (Expected: 0x%08h)", test_name, result, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s | Result = 0x%08h (Expected: 0x%08h)", test_name, result, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("==================================================");
        $display("   PROTOCOLX RISC-V ALU UNIT VERIFICATION");
        $display("==================================================");

        // ADD
        alu_op = `ALU_ADD; a = 32'd15; b = 32'd25;
        check_result(32'd40, "ALU ADD 15 + 25");

        // SUB
        alu_op = `ALU_SUB; a = 32'd50; b = 32'd20;
        check_result(32'd30, "ALU SUB 50 - 20");

        // AND
        alu_op = `ALU_AND; a = 32'hF0F0F0F0; b = 32'hFFFF0000;
        check_result(32'hF0F00000, "ALU AND");

        // OR
        alu_op = `ALU_OR; a = 32'hF0F00000; b = 32'h0F0F0000;
        check_result(32'hFFFF0000, "ALU OR");

        // XOR
        alu_op = `ALU_XOR; a = 32'hAA55AA55; b = 32'hFFFF0000;
        check_result(32'h55AAaa55, "ALU XOR");

        // SLL (Shift Left Logical)
        alu_op = `ALU_SLL; a = 32'h00000001; b = 32'd4;
        check_result(32'h00000010, "ALU SLL 1 << 4");

        // SRL (Shift Right Logical)
        alu_op = `ALU_SRL; a = 32'h00000080; b = 32'd3;
        check_result(32'h00000010, "ALU SRL 128 >> 3");

        // SRA (Shift Right Arithmetic)
        alu_op = `ALU_SRA; a = 32'h80000000; b = 32'd2;
        check_result(32'hE0000000, "ALU SRA -2^31 >>> 2");

        // SLT (Set Less Than signed)
        alu_op = `ALU_SLT; a = -32'd10; b = 32'd5;
        check_result(32'd1, "ALU SLT (-10 < 5)");

        // SLTU (Set Less Than unsigned)
        alu_op = `ALU_SLTU; a = 32'd10; b = 32'd50;
        check_result(32'd1, "ALU SLTU (10 < 50)");

        $display("--------------------------------------------------");
        $display(" ALU Test Summary: Passed = %0d, Failed = %0d", pass_count, fail_count);
        $display("==================================================");

        if (fail_count == 0) $finish(0);
        else $finish(1);
    end

endmodule
