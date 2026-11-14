// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       pipe_mem_wb.v
// Description: MEM/WB Pipeline Register. Latches write-back stage control signals,
//              memory read data, ALU result, PC+4, and destination register index.
// Developers:  Naveen Kumar (2401020041) - Primary RTL Developer
//              Aditya Raj   (2401010032) - Pipeline Design
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module pipe_mem_wb (
    input  wire                      clk,
    input  wire                      rst_n,

    // Control Signals Input
    input  wire                      reg_write_in,
    input  wire [1:0]                mem_to_reg_in,

    // Datapath Values Input
    input  wire [`XLEN-1:0]          pc_plus4_in,
    input  wire [`XLEN-1:0]          read_data_in,
    input  wire [`XLEN-1:0]          alu_result_in,
    input  wire [`REG_ADDR_WIDTH-1:0] rd_in,

    // Control Signals Output
    output reg                       reg_write_out,
    output reg  [1:0]                mem_to_reg_out,

    // Datapath Values Output
    output reg  [`XLEN-1:0]          pc_plus4_out,
    output reg  [`XLEN-1:0]          read_data_out,
    output reg  [`XLEN-1:0]          alu_result_out,
    output reg  [`REG_ADDR_WIDTH-1:0] rd_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 2'b00;

            pc_plus4_out   <= {`XLEN{1'b0}};
            read_data_out  <= {`XLEN{1'b0}};
            alu_result_out <= {`XLEN{1'b0}};
            rd_out         <= 5'd0;
        end else begin
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;

            pc_plus4_out   <= pc_plus4_in;
            read_data_out  <= read_data_in;
            alu_result_out <= alu_result_in;
            rd_out         <= rd_in;
        end
    end

endmodule
