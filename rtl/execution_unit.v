// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       execution_unit.v
// Description: Execution Stage (EX) combining Forwarding Multiplexers,
//              ALU instance, Branch Condition Evaluator, and Target Address Generator.
// Developers:  Naveen Kumar (2401020041) - Primary RTL Developer
//              Aditya Raj   (2401010032) - Technical Lead
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module execution_unit (
    input  wire [`XLEN-1:0]  pc,
    input  wire [`XLEN-1:0]  read_data1,
    input  wire [`XLEN-1:0]  read_data2,
    input  wire [`XLEN-1:0]  immediate,
    input  wire [2:0]        funct3,
    input  wire [3:0]        alu_op,
    input  wire              alu_src,
    input  wire              alu_src_a,
    input  wire              branch,
    input  wire              jump,
    input  wire              is_jalr,

    // Forwarding inputs
    input  wire [1:0]        forward_a,
    input  wire [1:0]        forward_b,
    input  wire [`XLEN-1:0]  forward_data_mem, // From EX/MEM stage
    input  wire [`XLEN-1:0]  forward_data_wb,  // From MEM/WB stage

    // Outputs
    output wire [`XLEN-1:0]  alu_result,
    output wire [`XLEN-1:0]  write_data_mem,   // Store data forwarded to MEM stage
    output wire              branch_taken,
    output wire [`XLEN-1:0]  target_pc
);

    // Forwarding Multiplexers
    wire [`XLEN-1:0] fwd_operand_a = (forward_a == `FWD_MEM_STAGE) ? forward_data_mem :
                                     (forward_a == `FWD_WB_STAGE)  ? forward_data_wb  :
                                     read_data1;

    wire [`XLEN-1:0] fwd_operand_b = (forward_b == `FWD_MEM_STAGE) ? forward_data_mem :
                                     (forward_b == `FWD_WB_STAGE)  ? forward_data_wb  :
                                     read_data2;

    assign write_data_mem = fwd_operand_b;

    // ALU input multiplexers
    wire [`XLEN-1:0] alu_input_a = alu_src_a ? pc : fwd_operand_a;
    wire [`XLEN-1:0] alu_input_b = alu_src ? immediate : fwd_operand_b;

    // ALU Instance
    alu u_alu (
        .alu_op(alu_op),
        .a(alu_input_a),
        .b(alu_input_b),
        .result(alu_result),
        .zero(),
        .less_than(),
        .less_than_unsigned()
    );

    // Branch Condition Evaluation
    reg branch_condition_met;
    always @(*) begin
        case (funct3)
            `FUNCT3_BEQ:  branch_condition_met = (fwd_operand_a == fwd_operand_b);
            `FUNCT3_BNE:  branch_condition_met = (fwd_operand_a != fwd_operand_b);
            `FUNCT3_BLT:  branch_condition_met = ($signed(fwd_operand_a) < $signed(fwd_operand_b));
            `FUNCT3_BGE:  branch_condition_met = ($signed(fwd_operand_a) >= $signed(fwd_operand_b));
            `FUNCT3_BLTU: branch_condition_met = (fwd_operand_a < fwd_operand_b);
            `FUNCT3_BGEU: branch_condition_met = (fwd_operand_a >= fwd_operand_b);
            default:      branch_condition_met = 1'b0;
        endcase
    end

    assign branch_taken = (branch && branch_condition_met) || jump;

    // Target PC calculation
    wire [`XLEN-1:0] base_address = is_jalr ? fwd_operand_a : pc;
    wire [`XLEN-1:0] raw_target   = base_address + immediate;
    assign target_pc = is_jalr ? (raw_target & ~32'd1) : raw_target;

endmodule
