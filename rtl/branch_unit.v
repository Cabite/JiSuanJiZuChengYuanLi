`timescale 1ns / 1ps

// EX-stage resolution for conditional branches and register jumps.
// rs_value_e and rt_value_e must already include forwarding.
module branch_unit(
    input  wire        valid_e,
    input  wire [31:0] pc_e,
    input  wire [31:0] pc_plus4_e,
    input  wire [31:0] rs_value_e,
    input  wire [31:0] rt_value_e,
    input  wire [31:0] branch_offset_e,
    input  wire        branch_eq_e,
    input  wire        branch_ne_e,
    input  wire        jump_reg_e,
    input  wire        pred_taken_e,
    input  wire [31:0] pred_target_e,

    output wire        is_control_e,
    output wire        is_cond_branch_e,
    output wire        actual_taken_e,
    output wire [31:0] actual_target_e,
    output wire        mispredict_e,
    output wire        redirect_e,
    output wire [31:0] correct_pc_e
);

    wire operands_equal;
    wire conditional_taken;
    wire predicted_wrong_direction;
    wire predicted_wrong_target;

    assign operands_equal = (rs_value_e == rt_value_e);
    assign is_cond_branch_e = valid_e && (branch_eq_e || branch_ne_e);
    assign is_control_e = valid_e &&
                          (branch_eq_e || branch_ne_e || jump_reg_e);

    assign conditional_taken = (branch_eq_e && operands_equal) ||
                               (branch_ne_e && !operands_equal);
    assign actual_taken_e = is_control_e &&
                            (jump_reg_e || conditional_taken);
    assign actual_target_e = jump_reg_e ? rs_value_e :
                             (pc_plus4_e + branch_offset_e);

    assign predicted_wrong_direction = (pred_taken_e != actual_taken_e);
    assign predicted_wrong_target = actual_taken_e && pred_taken_e &&
                                    (pred_target_e != actual_target_e);
    assign mispredict_e = is_cond_branch_e &&
                          (predicted_wrong_direction ||
                           predicted_wrong_target);

    // JR has no IF-stage target prediction in stage 7, so it always redirects.
    assign redirect_e = (valid_e && jump_reg_e) || mispredict_e;
    assign correct_pc_e = actual_taken_e ? actual_target_e : pc_plus4_e;

    // pc_e remains in the interface for debug and later performance accounting;
    // branch target calculation deliberately uses pc_plus4_e, not pc_e.

endmodule
