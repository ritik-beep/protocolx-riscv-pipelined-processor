// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       imm_gen.v
// Description: Immediate Generator decoding and sign-extending I, S, B, U, and J
//              type immediate formats according to RISC-V RV32I specification.
// Developers:  Naveen Kumar (2401020041) - Primary RTL Developer
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module imm_gen (
    input  wire [`XLEN-1:0]  instruction,
    output reg  [`XLEN-1:0]  immediate
);

    wire [6:0] opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            // I-Type: Arithmetic Immediates, Loads, JALR
            `OPCODE_I_TYPE,
            `OPCODE_LOAD,
            `OPCODE_JALR: begin
                immediate = {{20{instruction[31]}}, instruction[31:20]};
            end

            // S-Type: Stores
            `OPCODE_STORE: begin
                immediate = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end

            // B-Type: Conditional Branches
            `OPCODE_BRANCH: begin
                immediate = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            end

            // U-Type: LUI, AUIPC
            `OPCODE_LUI,
            `OPCODE_AUIPC: begin
                immediate = {instruction[31:12], 12'b0};
            end

            // J-Type: JAL
            `OPCODE_JAL: begin
                immediate = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end

            default: begin
                immediate = {`XLEN{1'b0}};
            end
        endcase
    end

endmodule
