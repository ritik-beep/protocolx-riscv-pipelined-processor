// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       pipe_id_ex.v
// Description: ID/EX Pipeline Register. Latches decoded instruction control signals,
//              register operands, immediate, PC, and source/dest register indices.
//              Supports synchronous flush for branch mispredictions and stalls.
// Developers:  Naveen Kumar (2401020041) - Primary RTL Developer
//              Aditya Raj   (2401010032) - Pipeline Design
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module pipe_id_ex (
    input  wire                      clk,
    input  wire                      rst_n,
    input  wire                      flush,

    // Control Signals Input
    input  wire                      reg_write_in,
    input  wire [1:0]                mem_to_reg_in,
    input  wire                      mem_read_in,
    input  wire                      mem_write_in,
    input  wire                      alu_src_in,
    input  wire                      alu_src_a_in,
    input  wire                      branch_in,
    input  wire                      jump_in,
    input  wire                      is_jalr_in,
    input  wire [3:0]                alu_op_in,

    // Datapath Values Input
    input  wire [`XLEN-1:0]          pc_in,
    input  wire [`XLEN-1:0]          pc_plus4_in,
    input  wire [`XLEN-1:0]          read_data1_in,
    input  wire [`XLEN-1:0]          read_data2_in,
    input  wire [`XLEN-1:0]          immediate_in,
    input  wire [2:0]                funct3_in,
    input  wire [6:0]                funct7_in,
    input  wire [`REG_ADDR_WIDTH-1:0] rd_in,
    input  wire [`REG_ADDR_WIDTH-1:0] rs1_in,
    input  wire [`REG_ADDR_WIDTH-1:0] rs2_in,

    // Control Signals Output
    output reg                       reg_write_out,
    output reg  [1:0]                mem_to_reg_out,
    output reg                       mem_read_out,
    output reg                       mem_write_out,
    output reg                       alu_src_out,
    output reg                       alu_src_a_out,
    output reg                       branch_out,
    output reg                       jump_out,
    output reg                       is_jalr_out,
    output reg  [3:0]                alu_op_out,

    // Datapath Values Output
    output reg  [`XLEN-1:0]          pc_out,
    output reg  [`XLEN-1:0]          pc_plus4_out,
    output reg  [`XLEN-1:0]          read_data1_out,
    output reg  [`XLEN-1:0]          read_data2_out,
    output reg  [`XLEN-1:0]          immediate_out,
    output reg  [2:0]                funct3_out,
    output reg  [6:0]                funct7_out,
    output reg  [`REG_ADDR_WIDTH-1:0] rd_out,
    output reg  [`REG_ADDR_WIDTH-1:0] rs1_out,
    output reg  [`REG_ADDR_WIDTH-1:0] rs2_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 2'b00;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            alu_src_out    <= 1'b0;
            alu_src_a_out  <= 1'b0;
            branch_out     <= 1'b0;
            jump_out       <= 1'b0;
            is_jalr_out    <= 1'b0;
            alu_op_out     <= `ALU_ADD;

            pc_out         <= {`XLEN{1'b0}};
            pc_plus4_out   <= {`XLEN{1'b0}};
            read_data1_out <= {`XLEN{1'b0}};
            read_data2_out <= {`XLEN{1'b0}};
            immediate_out  <= {`XLEN{1'b0}};
            funct3_out     <= 3'b000;
            funct7_out     <= 7'b0000000;
            rd_out         <= 5'd0;
            rs1_out        <= 5'd0;
            rs2_out        <= 5'd0;
        end else begin
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            alu_src_out    <= alu_src_in;
            alu_src_a_out  <= alu_src_a_in;
            branch_out     <= branch_in;
            jump_out       <= jump_in;
            is_jalr_out    <= is_jalr_in;
            alu_op_out     <= alu_op_in;

            pc_out         <= pc_in;
            pc_plus4_out   <= pc_plus4_in;
            read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in;
            immediate_out  <= immediate_in;
            funct3_out     <= funct3_in;
            funct7_out     <= funct7_in;
            rd_out         <= rd_in;
            rs1_out        <= rs1_in;
            rs2_out        <= rs2_in;
        end
    end

endmodule
