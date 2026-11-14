// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       alu.v
// Description: Arithmetic Logic Unit executing 32-bit integer arithmetic,
//              logical, shift, and comparison operations.
// Developers:  Naveen Kumar (2401020041) - Primary RTL Developer
//              Aditya Raj   (2401010032) - Pipeline Verification
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module alu (
    input  wire [3:0]        alu_op,
    input  wire [`XLEN-1:0]  a,
    input  wire [`XLEN-1:0]  b,
    output reg  [`XLEN-1:0]  result,
    output wire              zero,
    output wire              less_than,
    output wire              less_than_unsigned
);

    wire [4:0] shamt = b[4:0];

    // Signed and unsigned comparisons
    assign less_than          = ($signed(a) < $signed(b)) ? 1'b1 : 1'b0;
    assign less_than_unsigned = (a < b) ? 1'b1 : 1'b0;
    assign zero               = (result == {`XLEN{1'b0}});

    always @(*) begin
        case (alu_op)
            `ALU_ADD:    result = a + b;
            `ALU_SUB:    result = a - b;
            `ALU_AND:    result = a & b;
            `ALU_OR:     result = a | b;
            `ALU_XOR:    result = a ^ b;
            `ALU_SLT:    result = {31'b0, less_than};
            `ALU_SLTU:   result = {31'b0, less_than_unsigned};
            `ALU_SLL:    result = a << shamt;
            `ALU_SRL:    result = a >> shamt;
            `ALU_SRA:    result = $signed(a) >>> shamt;
            `ALU_PASS_B: result = b;
            default:     result = {`XLEN{1'b0}};
        endcase
    end

endmodule
