`timescale 1ns / 1ps

// ID/EX pipeline register.
// Synchronous control priority: reset > flush > enable > hold.
module id_ex_reg(
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire        flush,

    input  wire        valid_d,
    input  wire [31:0] pc_d,
    input  wire [31:0] pc_plus4_d,
    input  wire [31:0] rs_value_d,
    input  wire [31:0] rt_value_d,
    input  wire [4:0]  rs_d,
    input  wire [4:0]  rt_d,
    input  wire [4:0]  dest_d,
    input  wire [31:0] imm_ext_d,
    input  wire [31:0] branch_offset_d,
    input  wire [31:0] lui_value_d,
    input  wire [4:0]  shamt_d,
    input  wire        alu_src_b_d,
    input  wire [4:0]  alu_control_d,
    input  wire        reg_write_d,
    input  wire        mem_read_d,
    input  wire        mem_write_d,
    input  wire [1:0]  result_src_d,
    input  wire        branch_eq_d,
    input  wire        branch_ne_d,
    input  wire        jump_reg_d,
    input  wire        check_overflow_d,
    input  wire        pred_taken_d,
    input  wire [31:0] pred_target_d,
    input  wire [5:0]  pred_index_d,

    output reg         valid_e,
    output reg  [31:0] pc_e,
    output reg  [31:0] pc_plus4_e,
    output reg  [31:0] rs_value_e,
    output reg  [31:0] rt_value_e,
    output reg  [4:0]  rs_e,
    output reg  [4:0]  rt_e,
    output reg  [4:0]  dest_e,
    output reg  [31:0] imm_ext_e,
    output reg  [31:0] branch_offset_e,
    output reg  [31:0] lui_value_e,
    output reg  [4:0]  shamt_e,
    output reg         alu_src_b_e,
    output reg  [4:0]  alu_control_e,
    output reg         reg_write_e,
    output reg         mem_read_e,
    output reg         mem_write_e,
    output reg  [1:0]  result_src_e,
    output reg         branch_eq_e,
    output reg         branch_ne_e,
    output reg         jump_reg_e,
    output reg         check_overflow_e,
    output reg         pred_taken_e,
    output reg  [31:0] pred_target_e,
    output reg  [5:0]  pred_index_e
);

    always @(posedge clk) begin
        if (reset) begin
            valid_e          <= 1'b0;
            pc_e             <= 32'b0;
            pc_plus4_e       <= 32'b0;
            rs_value_e       <= 32'b0;
            rt_value_e       <= 32'b0;
            rs_e             <= 5'b0;
            rt_e             <= 5'b0;
            dest_e           <= 5'b0;
            imm_ext_e        <= 32'b0;
            branch_offset_e  <= 32'b0;
            lui_value_e      <= 32'b0;
            shamt_e          <= 5'b0;
            alu_src_b_e      <= 1'b0;
            alu_control_e    <= 5'b0;
            reg_write_e      <= 1'b0;
            mem_read_e       <= 1'b0;
            mem_write_e      <= 1'b0;
            result_src_e     <= 2'b0;
            branch_eq_e      <= 1'b0;
            branch_ne_e      <= 1'b0;
            jump_reg_e       <= 1'b0;
            check_overflow_e <= 1'b0;
            pred_taken_e     <= 1'b0;
            pred_target_e    <= 32'b0;
            pred_index_e     <= 6'b0;
        end else if (flush) begin
            valid_e          <= 1'b0;
            pc_e             <= 32'b0;
            pc_plus4_e       <= 32'b0;
            rs_value_e       <= 32'b0;
            rt_value_e       <= 32'b0;
            rs_e             <= 5'b0;
            rt_e             <= 5'b0;
            dest_e           <= 5'b0;
            imm_ext_e        <= 32'b0;
            branch_offset_e  <= 32'b0;
            lui_value_e      <= 32'b0;
            shamt_e          <= 5'b0;
            alu_src_b_e      <= 1'b0;
            alu_control_e    <= 5'b0;
            reg_write_e      <= 1'b0;
            mem_read_e       <= 1'b0;
            mem_write_e      <= 1'b0;
            result_src_e     <= 2'b0;
            branch_eq_e      <= 1'b0;
            branch_ne_e      <= 1'b0;
            jump_reg_e       <= 1'b0;
            check_overflow_e <= 1'b0;
            pred_taken_e     <= 1'b0;
            pred_target_e    <= 32'b0;
            pred_index_e     <= 6'b0;
        end else if (enable) begin
            valid_e          <= valid_d;
            pc_e             <= pc_d;
            pc_plus4_e       <= pc_plus4_d;
            rs_value_e       <= rs_value_d;
            rt_value_e       <= rt_value_d;
            rs_e             <= rs_d;
            rt_e             <= rt_d;
            dest_e           <= dest_d;
            imm_ext_e        <= imm_ext_d;
            branch_offset_e  <= branch_offset_d;
            lui_value_e      <= lui_value_d;
            shamt_e          <= shamt_d;
            alu_src_b_e      <= alu_src_b_d;
            alu_control_e    <= alu_control_d;
            reg_write_e      <= reg_write_d;
            mem_read_e       <= mem_read_d;
            mem_write_e      <= mem_write_d;
            result_src_e     <= result_src_d;
            branch_eq_e      <= branch_eq_d;
            branch_ne_e      <= branch_ne_d;
            jump_reg_e       <= jump_reg_d;
            check_overflow_e <= check_overflow_d;
            pred_taken_e     <= pred_taken_d;
            pred_target_e    <= pred_target_d;
            pred_index_e     <= pred_index_d;
        end
    end

endmodule
