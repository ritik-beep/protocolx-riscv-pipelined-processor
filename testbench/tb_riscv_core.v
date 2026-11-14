// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       tb_riscv_core.v
// Description: Comprehensive Verification Testbench for 5-Stage RV32I Processor.
//              Loads machine code test suites, tracks cycle-by-cycle pipeline stages,
//              records waveform artifacts (.vcd), and performs self-checking assertions.
// Developers:  Aditya Raj   (2401010032) - Technical Lead & Verification
//              Naveen Kumar (2401020041) - RTL Developer
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module tb_riscv_core;

    reg clk;
    reg rst_n;

    wire [`XLEN-1:0]           current_pc;
    wire [`XLEN-1:0]           current_instr;
    wire [`XLEN-1:0]           wb_data;
    wire [`REG_ADDR_WIDTH-1:0] wb_rd;
    wire                       wb_reg_write;

    // Simulation control parameters
    parameter MAX_CYCLES = 40;
    integer cycle_count = 0;
    integer pass_count  = 0;
    integer fail_count  = 0;

    // Configurable program file passed from runtime or default
    reg [255:0] hex_prog_file;

    // Processor Core Instance
    riscv_core #(
        .IMEM_DEPTH(1024),
        .DMEM_DEPTH(1024),
        .INIT_FILE("testbench/programs/prog_arithmetic.hex")
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .current_pc(current_pc),
        .current_instr(current_instr),
        .wb_data_out(wb_data),
        .wb_rd_out(wb_rd),
        .wb_reg_write_out(wb_reg_write)
    );

    // 100 MHz Clock Generator (10ns period)
    always #5 clk = ~clk;

    // Waveform VCD dump setup
    initial begin
        $dumpfile("simulation/waveform.vcd");
        $dumpvars(0, tb_riscv_core);
    end

    // Cycle tracking & Pipeline monitor
    always @(posedge clk) begin
        if (rst_n) begin
            cycle_count <= cycle_count + 1;

            // Pipeline trace logger
            $display("[Cycle %3d] PC: 0x%08h | Fetch: 0x%08h | WB: [rd: x%02d <= 0x%08h (wr: %b)]",
                     cycle_count, current_pc, current_instr, wb_rd, wb_data, wb_reg_write);

            if (cycle_count >= MAX_CYCLES) begin
                $display("\n[SIMULATION TIMEOUT] Reached MAX_CYCLES = %0d.", MAX_CYCLES);
                check_results();
                $finish;
            end
        end
    end

    // Main Test Stimulus
    initial begin
        clk = 0;
        rst_n = 0;

        $display("===============================================================================");
        $display("               PROTOCOLX RISC-V 5-STAGE PROCESSOR VERIFICATION                 ");
        $display("===============================================================================");
        $display("Executing test program: testbench/programs/prog_arithmetic.hex");
        $display("-------------------------------------------------------------------------------");

        // Hold reset for 2 clock cycles
        #22;
        rst_n = 1;

        // Run until completion or timeout
        wait (cycle_count >= 25);
        #1;
        check_results();
        $finish;
    end

    // Verification Assertion Task
    task check_results;
        begin
            $display("\n===============================================================================");
            $display("                       POST-SIMULATION REGISTER AUDIT                          ");
            $display("===============================================================================");

            // Check x1: ADDI x1, x0, 10 -> 10
            assert_reg(5'd1, 32'd10, "x1 (ADDI 10)");
            // Check x2: ADDI x2, x0, 20 -> 20
            assert_reg(5'd2, 32'd20, "x2 (ADDI 20)");
            // Check x3: ADD x3, x1, x2 -> 30
            assert_reg(5'd3, 32'd30, "x3 (ADD 10+20)");
            // Check x4: SUB x4, x2, x1 -> 10
            assert_reg(5'd4, 32'd10, "x4 (SUB 20-10)");
            // Check x5: AND x5, x1, x2 -> 0
            assert_reg(5'd5, 32'd0, "x5 (AND 10&20)");
            // Check x6: OR x6, x1, x2 -> 30
            assert_reg(5'd6, 32'd30, "x6 (OR 10|20)");
            // Check x7: XOR x7, x1, x2 -> 30
            assert_reg(5'd7, 32'd30, "x7 (XOR 10^20)");
            // Check x8: SLLI x8, x1, 2 -> 40
            assert_reg(5'd8, 32'd40, "x8 (SLLI 10<<2)");
            // Check x9: SRLI x9, x2, 1 -> 10
            assert_reg(5'd9, 32'd10, "x9 (SRLI 20>>1)");
            // Check x10: SLT x10, x1, x2 -> 1
            assert_reg(5'd10, 32'd1, "x10 (SLT 10<20)");

            $display("-------------------------------------------------------------------------------");
            $display("Verification Summary: %0d Passed, %0d Failed", pass_count, fail_count);
            $display("===============================================================================");

            if (fail_count == 0) begin
                $display(">>> ALL ASSERTIONS PASSED! 5-STAGE PIPELINE FUNCTIONALITY VERIFIED. <<<");
            end else begin
                $display(">>> VERIFICATION FAILED WITH %0d ERRORS. <<<", fail_count);
            end
        end
    endtask

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
