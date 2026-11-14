// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       tb_riscv_mem.v
// Description: Testbench verifying Memory (LW/SW) and Load-Use Hazard Interlocking.
//              Tests that a 1-cycle pipeline bubble is automatically injected on load-use.
// Developers:  Aditya Raj   (2401010032) - Technical Lead & Verification
//              Naveen Kumar (2401020041) - RTL Developer
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module tb_riscv_mem;

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
        .INIT_FILE("testbench/programs/prog_load_store.hex")
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
        $dumpfile("simulation/waveform_mem.vcd");
        $dumpvars(0, tb_riscv_mem);
    end

    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;
            $display("[Cycle %2d] PC: 0x%08h | Stall(PC_wr=%b, IF_ID_wr=%b) | WB: x%02d <= 0x%08h",
                     cycle_count, current_pc, dut.u_hazard_unit.pc_write, dut.u_hazard_unit.if_id_write, wb_rd, wb_data);
        end
    end

    initial begin
        clk = 0;
        rst_n = 0;

        $display("===============================================================================");
        $display("        PROTOCOLX RISC-V MEMORY (LW/SW) & LOAD-USE STALL VERIFICATION          ");
        $display("===============================================================================");

        #22;
        rst_n = 1;

        wait (cycle_count >= 20);
        #1;

        $display("\n===============================================================================");
        $display("                 MEMORY & LOAD-USE REGISTER / DMEM AUDIT                       ");
        $display("===============================================================================");

        assert_reg(5'd1, 32'd100, "x1 (Initial value = 100)");
        assert_mem(0,    32'd100, "DMEM[0] (SW x1 stored 100)");
        assert_reg(5'd2, 32'd100, "x2 (LW from DMEM[0] = 100)");
        assert_reg(5'd3, 32'd150, "x3 (Load-Use Stalled ADDI x3, x2, 50 = 150)");
        assert_mem(1,    32'd150, "DMEM[1] (SW x3 stored 150)");
        assert_reg(5'd4, 32'd150, "x4 (LW from DMEM[1] = 150)");

        $display("-------------------------------------------------------------------------------");
        $display("Memory & Stall Summary: %0d Passed, %0d Failed", pass_count, fail_count);
        $display("===============================================================================");

        if (fail_count == 0) begin
            $display(">>> DATA MEMORY INTERFACE AND LOAD-USE INTERLOCKING FULLY VERIFIED. <<<");
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

    task assert_mem(input integer word_idx, input [31:0] expected_val, input [127:0] desc);
        reg [31:0] actual_val;
        begin
            actual_val = dut.u_dmem.memory[word_idx];
            if (actual_val === expected_val) begin
                $display("[PASS] %0s = 0x%08h (%0d)", desc, actual_val, actual_val);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s = 0x%08h (Expected: 0x%08h)", desc, actual_val, expected_val);
                fail_count = fail_count + 1;
            end
        end
    endtask

endmodule
