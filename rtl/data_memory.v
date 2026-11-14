// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       data_memory.v
// Description: Synchronous Data Memory (RAM) for Load and Store instructions.
//              Synchronous write on posedge clk, asynchronous read access.
// Developers:  Naveen Kumar (2401020041) - Primary RTL Developer
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module data_memory #(
    parameter MEM_DEPTH = 1024
)(
    input  wire              clk,
    input  wire              rst_n,
    input  wire              mem_read,
    input  wire              mem_write,
    input  wire [`XLEN-1:0]  address,
    input  wire [`XLEN-1:0]  write_data,
    output wire [`XLEN-1:0]  read_data
);

    reg [`XLEN-1:0] memory [0:MEM_DEPTH-1];
    integer i;

    // Word-aligned addressing
    wire [$clog2(MEM_DEPTH)-1:0] word_addr = address[$clog2(MEM_DEPTH)+1:2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < MEM_DEPTH; i = i + 1) begin
                memory[i] <= {`XLEN{1'b0}};
            end
        end else if (mem_write && (address < (MEM_DEPTH * 4))) begin
            memory[word_addr] <= write_data;
        end
    end

    assign read_data = (mem_read && (address < (MEM_DEPTH * 4))) ? memory[word_addr] : {`XLEN{1'b0}};

endmodule
