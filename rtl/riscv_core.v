// =============================================================================
// Project:    ProtocolX RISC-V 5-Stage Pipelined Processor
// File:       riscv_core.v
// Description: Top-Level 5-Stage Pipelined RV32I Processor Core.
//              Integrates IF, ID, EX, MEM, and WB stages with hazard detection,
//              data forwarding, and pipeline registers.
// Developers:  Naveen Kumar (2401020041) - Project Lead & Primary RTL Developer
//              Aditya Raj   (2401010032) - Technical Lead, Pipeline Design & Verification
// =============================================================================

`timescale 1ns / 1ps
`include "riscv_defines.vh"

module riscv_core #(
    parameter IMEM_DEPTH = 1024,
    parameter DMEM_DEPTH = 1024,
    parameter INIT_FILE  = ""
)(
    input  wire                      clk,
    input  wire                      rst_n,

    // Probe signals for verification / monitoring
    output wire [`XLEN-1:0]          current_pc,
    output wire [`XLEN-1:0]          current_instr,
    output wire [`XLEN-1:0]          wb_data_out,
    output wire [`REG_ADDR_WIDTH-1:0] wb_rd_out,
    output wire                      wb_reg_write_out
);

    // =========================================================================
    // 1. INSTRUCTION FETCH (IF) STAGE
    // =========================================================================
    reg  [`XLEN-1:0] pc_reg;
    wire [`XLEN-1:0] pc_next;
    wire [`XLEN-1:0] pc_plus4;
    wire [`XLEN-1:0] instruction_raw;

    // Hazard control wires
    wire pc_write;
    wire if_id_write;
    wire if_id_flush;
    wire id_ex_flush;
    wire branch_taken_ex;
    wire [`XLEN-1:0] target_pc_ex;

    assign pc_plus4 = pc_reg + 32'd4;
    assign pc_next  = branch_taken_ex ? target_pc_ex : pc_plus4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_reg <= {`XLEN{1'b0}};
        end else if (pc_write) begin
            pc_reg <= pc_next;
        end
    end

    // Instruction Memory Instance
    instruction_memory #(
        .MEM_DEPTH(IMEM_DEPTH),
        .INIT_FILE(INIT_FILE)
    ) u_imem (
        .address(pc_reg),
        .instruction(instruction_raw)
    );

    // =========================================================================
    // PIPELINE REGISTER: IF / ID
    // =========================================================================
    wire [`XLEN-1:0] pc_id;
    wire [`XLEN-1:0] pc_plus4_id;
    wire [`XLEN-1:0] instr_id;

    pipe_if_id u_pipe_if_id (
        .clk(clk),
        .rst_n(rst_n),
        .enable(if_id_write),
        .flush(if_id_flush),
        .pc_in(pc_reg),
        .pc_plus4_in(pc_plus4),
        .instruction_in(instruction_raw),
        .pc_out(pc_id),
        .pc_plus4_out(pc_plus4_id),
        .instruction_out(instr_id)
    );

    // =========================================================================
    // 2. INSTRUCTION DECODE (ID) STAGE
    // =========================================================================
    wire [6:0] opcode_id   = instr_id[6:0];
    wire [2:0] funct3_id   = instr_id[14:12];
    wire [6:0] funct7_id   = instr_id[31:25];
    wire [4:0] rd_id       = instr_id[11:7];
    wire [4:0] rs1_id      = instr_id[19:15];
    wire [4:0] rs2_id      = instr_id[24:20];

    // Control Unit signals
    wire       ctrl_reg_write_id;
    wire [1:0] ctrl_mem_to_reg_id;
    wire       ctrl_mem_read_id;
    wire       ctrl_mem_write_id;
    wire       ctrl_alu_src_id;
    wire       ctrl_alu_src_a_id;
    wire       ctrl_branch_id;
    wire       ctrl_jump_id;
    wire       ctrl_is_jalr_id;
    wire [3:0] ctrl_alu_op_id;

    control_unit u_control_unit (
        .opcode(opcode_id),
        .funct3(funct3_id),
        .funct7(funct7_id),
        .reg_write(ctrl_reg_write_id),
        .mem_to_reg(ctrl_mem_to_reg_id),
        .mem_read(ctrl_mem_read_id),
        .mem_write(ctrl_mem_write_id),
        .alu_src(ctrl_alu_src_id),
        .alu_src_a(ctrl_alu_src_a_id),
        .branch(ctrl_branch_id),
        .jump(ctrl_jump_id),
        .is_jalr(ctrl_is_jalr_id),
        .alu_op(ctrl_alu_op_id)
    );

    // Register File
    wire [`XLEN-1:0] reg_read_data1_id;
    wire [`XLEN-1:0] reg_read_data2_id;
    wire [`XLEN-1:0] wb_data;
    wire [`REG_ADDR_WIDTH-1:0] rd_wb;
    wire             reg_write_wb;

    reg_file u_reg_file (
        .clk(clk),
        .rst_n(rst_n),
        .reg_write(reg_write_wb),
        .read_addr1(rs1_id),
        .read_addr2(rs2_id),
        .write_addr(rd_wb),
        .write_data(wb_data),
        .read_data1(reg_read_data1_id),
        .read_data2(reg_read_data2_id)
    );

    // Immediate Generator
    wire [`XLEN-1:0] imm_id;
    imm_gen u_imm_gen (
        .instruction(instr_id),
        .immediate(imm_id)
    );

    // =========================================================================
    // PIPELINE REGISTER: ID / EX
    // =========================================================================
    wire        reg_write_ex;
    wire [1:0]  mem_to_reg_ex;
    wire        mem_read_ex;
    wire        mem_write_ex;
    wire        alu_src_ex;
    wire        alu_src_a_ex;
    wire        branch_ex;
    wire        jump_ex;
    wire        is_jalr_ex;
    wire [3:0]  alu_op_ex;

    wire [`XLEN-1:0] pc_ex;
    wire [`XLEN-1:0] pc_plus4_ex;
    wire [`XLEN-1:0] read_data1_ex;
    wire [`XLEN-1:0] read_data2_ex;
    wire [`XLEN-1:0] imm_ex;
    wire [2:0]       funct3_ex;
    wire [6:0]       funct7_ex;
    wire [4:0]       rd_ex;
    wire [4:0]       rs1_ex;
    wire [4:0]       rs2_ex;

    pipe_id_ex u_pipe_id_ex (
        .clk(clk),
        .rst_n(rst_n),
        .flush(id_ex_flush),

        .reg_write_in(ctrl_reg_write_id),
        .mem_to_reg_in(ctrl_mem_to_reg_id),
        .mem_read_in(ctrl_mem_read_id),
        .mem_write_in(ctrl_mem_write_id),
        .alu_src_in(ctrl_alu_src_id),
        .alu_src_a_in(ctrl_alu_src_a_id),
        .branch_in(ctrl_branch_id),
        .jump_in(ctrl_jump_id),
        .is_jalr_in(ctrl_is_jalr_id),
        .alu_op_in(ctrl_alu_op_id),

        .pc_in(pc_id),
        .pc_plus4_in(pc_plus4_id),
        .read_data1_in(reg_read_data1_id),
        .read_data2_in(reg_read_data2_id),
        .immediate_in(imm_id),
        .funct3_in(funct3_id),
        .funct7_in(funct7_id),
        .rd_in(rd_id),
        .rs1_in(rs1_id),
        .rs2_in(rs2_id),

        .reg_write_out(reg_write_ex),
        .mem_to_reg_out(mem_to_reg_ex),
        .mem_read_out(mem_read_ex),
        .mem_write_out(mem_write_ex),
        .alu_src_out(alu_src_ex),
        .alu_src_a_out(alu_src_a_ex),
        .branch_out(branch_ex),
        .jump_out(jump_ex),
        .is_jalr_out(is_jalr_ex),
        .alu_op_out(alu_op_ex),

        .pc_out(pc_ex),
        .pc_plus4_out(pc_plus4_ex),
        .read_data1_out(read_data1_ex),
        .read_data2_out(read_data2_ex),
        .immediate_out(imm_ex),
        .funct3_out(funct3_ex),
        .funct7_out(funct7_ex),
        .rd_out(rd_ex),
        .rs1_out(rs1_ex),
        .rs2_out(rs2_ex)
    );

    // =========================================================================
    // 3. EXECUTION (EX) STAGE & FORWARDING
    // =========================================================================
    wire [1:0] forward_a;
    wire [1:0] forward_b;
    wire [`XLEN-1:0] alu_result_ex;
    wire [`XLEN-1:0] write_data_mem_ex;

    // From EX/MEM stage
    wire [`XLEN-1:0] alu_result_mem;
    wire [`REG_ADDR_WIDTH-1:0] rd_mem;
    wire reg_write_mem;

    execution_unit u_execution_unit (
        .pc(pc_ex),
        .read_data1(read_data1_ex),
        .read_data2(read_data2_ex),
        .immediate(imm_ex),
        .funct3(funct3_ex),
        .alu_op(alu_op_ex),
        .alu_src(alu_src_ex),
        .alu_src_a(alu_src_a_ex),
        .branch(branch_ex),
        .jump(jump_ex),
        .is_jalr(is_jalr_ex),

        .forward_a(forward_a),
        .forward_b(forward_b),
        .forward_data_mem(alu_result_mem),
        .forward_data_wb(wb_data),

        .alu_result(alu_result_ex),
        .write_data_mem(write_data_mem_ex),
        .branch_taken(branch_taken_ex),
        .target_pc(target_pc_ex)
    );

    // =========================================================================
    // PIPELINE REGISTER: EX / MEM
    // =========================================================================
    wire [1:0] mem_to_reg_mem;
    wire       mem_read_mem;
    wire       mem_write_mem;
    wire [`XLEN-1:0] pc_plus4_mem;
    wire [`XLEN-1:0] write_data_mem;

    pipe_ex_mem u_pipe_ex_mem (
        .clk(clk),
        .rst_n(rst_n),

        .reg_write_in(reg_write_ex),
        .mem_to_reg_in(mem_to_reg_ex),
        .mem_read_in(mem_read_ex),
        .mem_write_in(mem_write_ex),

        .pc_plus4_in(pc_plus4_ex),
        .alu_result_in(alu_result_ex),
        .write_data_in(write_data_mem_ex),
        .rd_in(rd_ex),

        .reg_write_out(reg_write_mem),
        .mem_to_reg_out(mem_to_reg_mem),
        .mem_read_out(mem_read_mem),
        .mem_write_out(mem_write_mem),

        .pc_plus4_out(pc_plus4_mem),
        .alu_result_out(alu_result_mem),
        .write_data_out(write_data_mem),
        .rd_out(rd_mem)
    );

    // =========================================================================
    // 4. MEMORY ACCESS (MEM) STAGE
    // =========================================================================
    wire [`XLEN-1:0] mem_read_data_raw;

    data_memory #(
        .MEM_DEPTH(DMEM_DEPTH)
    ) u_dmem (
        .clk(clk),
        .rst_n(rst_n),
        .mem_read(mem_read_mem),
        .mem_write(mem_write_mem),
        .address(alu_result_mem),
        .write_data(write_data_mem),
        .read_data(mem_read_data_raw)
    );

    // =========================================================================
    // PIPELINE REGISTER: MEM / WB
    // =========================================================================
    wire [1:0]       mem_to_reg_wb;
    wire [`XLEN-1:0] pc_plus4_wb;
    wire [`XLEN-1:0] mem_read_data_wb;
    wire [`XLEN-1:0] alu_result_wb;

    pipe_mem_wb u_pipe_mem_wb (
        .clk(clk),
        .rst_n(rst_n),

        .reg_write_in(reg_write_mem),
        .mem_to_reg_in(mem_to_reg_mem),

        .pc_plus4_in(pc_plus4_mem),
        .read_data_in(mem_read_data_raw),
        .alu_result_in(alu_result_mem),
        .rd_in(rd_mem),

        .reg_write_out(reg_write_wb),
        .mem_to_reg_out(mem_to_reg_wb),

        .pc_plus4_out(pc_plus4_wb),
        .read_data_out(mem_read_data_wb),
        .alu_result_out(alu_result_wb),
        .rd_out(rd_wb)
    );

    // =========================================================================
    // 5. WRITE-BACK (WB) STAGE
    // =========================================================================
    assign wb_data = (mem_to_reg_wb == 2'b01) ? mem_read_data_wb :
                     (mem_to_reg_wb == 2'b10) ? pc_plus4_wb      :
                     alu_result_wb;

    // Verification probe outputs
    assign current_pc       = pc_reg;
    assign current_instr    = instruction_raw;
    assign wb_data_out      = wb_data;
    assign wb_rd_out        = rd_wb;
    assign wb_reg_write_out = reg_write_wb;

    // =========================================================================
    // HAZARD DETECTION & FORWARDING UNIT
    // =========================================================================
    hazard_unit u_hazard_unit (
        .rs1_id(rs1_id),
        .rs2_id(rs2_id),
        .rd_ex(rd_ex),
        .mem_read_ex(mem_read_ex),

        .rs1_ex(rs1_ex),
        .rs2_ex(rs2_ex),
        .rd_mem(rd_mem),
        .reg_write_mem(reg_write_mem),
        .rd_wb(rd_wb),
        .reg_write_wb(reg_write_wb),

        .branch_taken_ex(branch_taken_ex),
        .jump_ex(jump_ex),

        .pc_write(pc_write),
        .if_id_write(if_id_write),
        .if_id_flush(if_id_flush),
        .id_ex_flush(id_ex_flush),

        .forward_a(forward_a),
        .forward_b(forward_b)
    );

endmodule
