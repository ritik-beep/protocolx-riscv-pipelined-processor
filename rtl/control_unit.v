// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       control_unit.v
// Description: Main Control and ALU Decoder generating pipeline control signals
//              based on instruction opcode, funct3, and funct7.
// Developers:  Naveen Kumar (2401020041) - Primary RTL Developer
//              Aditya Raj   (2401010032) - Pipeline Architecture
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module control_unit (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        reg_write,
    output reg  [1:0] mem_to_reg,  // 2'b00: ALU result, 2'b01: Mem Data, 2'b10: PC+4
    output reg        mem_read,
    output reg        mem_write,
    output reg        alu_src,     // 0: Reg B, 1: Immediate
    output reg        alu_src_a,   // 0: Reg A, 1: PC (for AUIPC)
    output reg        branch,
    output reg        jump,
    output reg        is_jalr,
    output reg  [3:0] alu_op
);

    always @(*) begin
        // Default control settings (NOP behavior)
        reg_write  = 1'b0;
        mem_to_reg = 2'b00;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        alu_src    = 1'b0;
        alu_src_a  = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        is_jalr    = 1'b0;
        alu_op     = `ALU_ADD;

        case (opcode)
            `OPCODE_R_TYPE: begin
                reg_write  = 1'b1;
                mem_to_reg = 2'b00;
                alu_src    = 1'b0;
                alu_src_a  = 1'b0;
                case (funct3)
                    `FUNCT3_ADD_SUB: alu_op = (funct7 == `FUNCT7_ALT) ? `ALU_SUB : `ALU_ADD;
                    `FUNCT3_SLL:     alu_op = `ALU_SLL;
                    `FUNCT3_SLT:     alu_op = `ALU_SLT;
                    `FUNCT3_SLTU:    alu_op = `ALU_SLTU;
                    `FUNCT3_XOR:     alu_op = `ALU_XOR;
                    `FUNCT3_SRL_SRA: alu_op = (funct7 == `FUNCT7_ALT) ? `ALU_SRA : `ALU_SRL;
                    `FUNCT3_OR:      alu_op = `ALU_OR;
                    `FUNCT3_AND:     alu_op = `ALU_AND;
                    default:         alu_op = `ALU_ADD;
                endcase
            end

            `OPCODE_I_TYPE: begin
                reg_write  = 1'b1;
                mem_to_reg = 2'b00;
                alu_src    = 1'b1;
                alu_src_a  = 1'b0;
                case (funct3)
                    `FUNCT3_ADD_SUB: alu_op = `ALU_ADD;
                    `FUNCT3_SLT:     alu_op = `ALU_SLT;
                    `FUNCT3_SLTU:    alu_op = `ALU_SLTU;
                    `FUNCT3_XOR:     alu_op = `ALU_XOR;
                    `FUNCT3_OR:      alu_op = `ALU_OR;
                    `FUNCT3_AND:     alu_op = `ALU_AND;
                    `FUNCT3_SLL:     alu_op = `ALU_SLL;
                    `FUNCT3_SRL_SRA: alu_op = (funct7 == `FUNCT7_ALT) ? `ALU_SRA : `ALU_SRL;
                    default:         alu_op = `ALU_ADD;
                endcase
            end

            `OPCODE_LOAD: begin
                reg_write  = 1'b1;
                mem_to_reg = 2'b01; // Data from Memory
                mem_read   = 1'b1;
                alu_src    = 1'b1;
                alu_src_a  = 1'b0;
                alu_op     = `ALU_ADD; // Address calculation
            end

            `OPCODE_STORE: begin
                reg_write  = 1'b0;
                mem_write  = 1'b1;
                alu_src    = 1'b1;
                alu_src_a  = 1'b0;
                alu_op     = `ALU_ADD; // Address calculation
            end

            `OPCODE_BRANCH: begin
                branch     = 1'b1;
                alu_src    = 1'b0;
                alu_src_a  = 1'b0;
                alu_op     = `ALU_SUB; // Subtraction for comparison
            end

            `OPCODE_LUI: begin
                reg_write  = 1'b1;
                mem_to_reg = 2'b00;
                alu_src    = 1'b1;
                alu_op     = `ALU_PASS_B;
            end

            `OPCODE_AUIPC: begin
                reg_write  = 1'b1;
                mem_to_reg = 2'b00;
                alu_src    = 1'b1;
                alu_src_a  = 1'b1; // Add PC
                alu_op     = `ALU_ADD;
            end

            `OPCODE_JAL: begin
                reg_write  = 1'b1;
                mem_to_reg = 2'b10; // PC + 4 written to rd
                jump       = 1'b1;
                alu_op     = `ALU_ADD;
            end

            `OPCODE_JALR: begin
                reg_write  = 1'b1;
                mem_to_reg = 2'b10; // PC + 4 written to rd
                jump       = 1'b1;
                is_jalr    = 1'b1;
                alu_src    = 1'b1;
                alu_op     = `ALU_ADD; // Base + offset for target
            end

            default: begin
                // All defaults preserved
            end
        endcase
    end

endmodule
