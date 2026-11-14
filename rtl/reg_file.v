// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       reg_file.v
// Description: 32x32-bit General Purpose Register File with hardwired zero (x0),
//              dual asynchronous read ports, synchronous write port, and internal
//              write-to-read forwarding (bypass) for same-cycle hazard prevention.
// Developers:  Naveen Kumar (2401020041) - Primary RTL Developer
//              Aditya Raj   (2401010032) - Technical Lead
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module reg_file (
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      reg_write,
    input  wire [`REG_ADDR_WIDTH-1:0] read_addr1,
    input  wire [`REG_ADDR_WIDTH-1:0] read_addr2,
    input  wire [`REG_ADDR_WIDTH-1:0] write_addr,
    input  wire [`XLEN-1:0]          write_data,
    output wire [`XLEN-1:0]          read_data1,
    output wire [`XLEN-1:0]          read_data2
);

    reg [`XLEN-1:0] registers [0:`NUM_REGS-1];
    integer i;

    // Synchronous write port (x0 is read-only zero)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < `NUM_REGS; i = i + 1) begin
                registers[i] <= {`XLEN{1'b0}};
            end
        end else if (reg_write && (write_addr != 5'd0)) begin
            registers[write_addr] <= write_data;
        end
    end

    // Asynchronous read ports with write-through bypass for same-cycle WB/ID hazard
    assign read_data1 = (read_addr1 == 5'd0) ? {`XLEN{1'b0}} :
                        (reg_write && (read_addr1 == write_addr)) ? write_data :
                        registers[read_addr1];

    assign read_data2 = (read_addr2 == 5'd0) ? {`XLEN{1'b0}} :
                        (reg_write && (read_addr2 == write_addr)) ? write_data :
                        registers[read_addr2];

endmodule
