// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       tb_reg_file.v
// Description: Unit testbench for Register File (32x32-bit).
//              Tests x0 zero-immutability, dual-port read, and write bypass.
// Developers:  Aditya Raj   (2401010032) - Technical Lead & Verification
//              Naveen Kumar (2401020041) - RTL Developer
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module tb_reg_file;

    reg         clk;
    reg         rst_n;
    reg         reg_write;
    reg  [4:0]  read_addr1;
    reg  [4:0]  read_addr2;
    reg  [4:0]  write_addr;
    reg  [31:0] write_data;
    wire [31:0] read_data1;
    wire [31:0] read_data2;

    integer pass_count = 0;
    integer fail_count = 0;

    reg_file dut (
        .clk(clk),
        .rst_n(rst_n),
        .reg_write(reg_write),
        .read_addr1(read_addr1),
        .read_addr2(read_addr2),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // Clock generator: 10ns period (100MHz)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        reg_write = 0;
        read_addr1 = 0;
        read_addr2 = 0;
        write_addr = 0;
        write_data = 0;

        $display("==================================================");
        $display(" PROTOCOLX RISC-V REGISTER FILE VERIFICATION");
        $display("==================================================");

        #12;
        rst_n = 1;

        // Test 1: Write to x1 and verify read
        @(posedge clk);
        write_addr = 5'd1;
        write_data = 32'hDEADBEEF;
        reg_write  = 1'b1;

        @(posedge clk);
        reg_write = 1'b0;
        read_addr1 = 5'd1;
        #1;
        if (read_data1 === 32'hDEADBEEF) begin
            $display("[PASS] Write and Read x1 = 0x%08h", read_data1);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Read x1 = 0x%08h (Expected 0xDEADBEEF)", read_data1);
            fail_count = fail_count + 1;
        end

        // Test 2: Verify x0 is hardwired to 0
        @(posedge clk);
        write_addr = 5'd0;
        write_data = 32'hFFFFFFFF;
        reg_write  = 1'b1;

        @(posedge clk);
        reg_write = 1'b0;
        read_addr1 = 5'd0;
        #1;
        if (read_data1 === 32'h00000000) begin
            $display("[PASS] x0 Zero Immutability Verified (x0 = 0x%08h)", read_data1);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] x0 written to non-zero: 0x%08h", read_data1);
            fail_count = fail_count + 1;
        end

        // Test 3: Write-Through Bypass in Same Cycle
        @(posedge clk);
        write_addr = 5'd5;
        write_data = 32'h12345678;
        reg_write  = 1'b1;
        read_addr2 = 5'd5; // Read in same cycle
        #1;
        if (read_data2 === 32'h12345678) begin
            $display("[PASS] Same-cycle WB bypass verified on x5 = 0x%08h", read_data2);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Same-cycle bypass failed: 0x%08h", read_data2);
            fail_count = fail_count + 1;
        end

        @(posedge clk);
        reg_write = 1'b0;

        $display("--------------------------------------------------");
        $display(" RegFile Test Summary: Passed = %0d, Failed = %0d", pass_count, fail_count);
        $display("==================================================");

        if (fail_count == 0) $finish(0);
        else $finish(1);
    end

endmodule
