// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       hazard_unit.v
// Description: Hazard Detection & Forwarding Unit.
//              - Resolves RAW data hazards via EX/MEM and MEM/WB operand forwarding.
//              - Detects load-use data hazards and inserts 1-cycle pipeline stalls.
//              - Handles control hazards on taken branches/jumps with pipeline flushes.
// Developers:  Aditya Raj   (2401010032) - Technical Lead & Pipeline Design
//              Naveen Kumar (2401020041) - RTL Developer
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module hazard_unit (
    // Hazard detection inputs
    input  wire [`REG_ADDR_WIDTH-1:0] rs1_id,
    input  wire [`REG_ADDR_WIDTH-1:0] rs2_id,
    input  wire [`REG_ADDR_WIDTH-1:0] rd_ex,
    input  wire                       mem_read_ex,

    // Forwarding inputs
    input  wire [`REG_ADDR_WIDTH-1:0] rs1_ex,
    input  wire [`REG_ADDR_WIDTH-1:0] rs2_ex,
    input  wire [`REG_ADDR_WIDTH-1:0] rd_mem,
    input  wire                       reg_write_mem,
    input  wire [`REG_ADDR_WIDTH-1:0] rd_wb,
    input  wire                       reg_write_wb,

    // Branch/Jump resolution inputs from EX stage
    input  wire                       branch_taken_ex,
    input  wire                       jump_ex,

    // Pipeline stall and flush outputs
    output reg                        pc_write,
    output reg                        if_id_write,
    output reg                        if_id_flush,
    output reg                        id_ex_flush,

    // Forwarding control outputs (00: ID/EX, 10: EX/MEM, 01: MEM/WB)
    output reg  [1:0]                 forward_a,
    output reg  [1:0]                 forward_b
);

    // -------------------------------------------------------------------------
    // 1. Data Forwarding Unit
    // -------------------------------------------------------------------------
    // Forwarding Priority Truth Table:
    // 1. EX/MEM Hazard (Priority 1):
    //    if (reg_write_mem && (rd_mem != 0) && (rd_mem == rs_ex))
    //       Forward = 2'b10 (Forward ALU result from EX/MEM pipeline register)
    // 2. MEM/WB Hazard (Priority 2):
    //    if (reg_write_wb && (rd_wb != 0) && (rd_wb == rs_ex))
    //       Forward = 2'b01 (Forward writeback data from MEM/WB pipeline register)
    // 3. No Hazard:
    //    Forward = 2'b00 (Use register value read during ID stage)
    // -------------------------------------------------------------------------
    always @(*) begin
        // Forward A Logic
        if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs1_ex)) begin
            forward_a = `FWD_MEM_STAGE; // 2'b10: Forward from EX/MEM
        end else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs1_ex)) begin
            forward_a = `FWD_WB_STAGE;  // 2'b01: Forward from MEM/WB
        end else begin
            forward_a = `FWD_NONE;      // 2'b00: Normal register read
        end

        // Forward B Logic
        if (reg_write_mem && (rd_mem != 5'd0) && (rd_mem == rs2_ex)) begin
            forward_b = `FWD_MEM_STAGE; // 2'b10: Forward from EX/MEM
        end else if (reg_write_wb && (rd_wb != 5'd0) && (rd_wb == rs2_ex)) begin
            forward_b = `FWD_WB_STAGE;  // 2'b01: Forward from MEM/WB
        end else begin
            forward_b = `FWD_NONE;      // 2'b00: Normal register read
        end
    end

    // -------------------------------------------------------------------------
    // 2. Load-Use Hazard Detection & Control Hazard Flushing
    // -------------------------------------------------------------------------
    always @(*) begin
        // Default normal execution
        pc_write    = 1'b1;
        if_id_write = 1'b1;
        if_id_flush = 1'b0;
        id_ex_flush = 1'b0;

        // Check for control hazards (branch or jump taken in EX stage)
        if (branch_taken_ex || jump_ex) begin
            // Flush instructions fetched along speculative fall-through path
            if_id_flush = 1'b1;
            id_ex_flush = 1'b1;
        end
        // Check for Load-Use Data Hazard
        else if (mem_read_ex && (rd_ex != 5'd0) && ((rd_ex == rs1_id) || (rd_ex == rs2_id))) begin
            // Stall: hold PC and IF/ID; inject bubble into ID/EX
            pc_write    = 1'b0;
            if_id_write = 1'b0;
            id_ex_flush = 1'b1;
        end
    end

endmodule
