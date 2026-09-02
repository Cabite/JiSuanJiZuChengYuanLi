`timescale 1ns / 1ps

module branch_unit_tb;

    reg valid_e;
    reg [31:0] pc_e;
    reg [31:0] pc_plus4_e;
    reg [31:0] rs_value_e;
    reg [31:0] rt_value_e;
    reg [31:0] branch_offset_e;
    reg branch_eq_e;
    reg branch_ne_e;
    reg jump_reg_e;
    reg pred_taken_e;
    reg [31:0] pred_target_e;

    wire is_control_e;
    wire is_cond_branch_e;
    wire actual_taken_e;
    wire [31:0] actual_target_e;
    wire mispredict_e;
    wire redirect_e;
    wire [31:0] correct_pc_e;

    integer errors;

    branch_unit dut(
        .valid_e(valid_e), .pc_e(pc_e), .pc_plus4_e(pc_plus4_e),
        .rs_value_e(rs_value_e), .rt_value_e(rt_value_e),
        .branch_offset_e(branch_offset_e), .branch_eq_e(branch_eq_e),
        .branch_ne_e(branch_ne_e), .jump_reg_e(jump_reg_e),
        .pred_taken_e(pred_taken_e), .pred_target_e(pred_target_e),
        .is_control_e(is_control_e),
        .is_cond_branch_e(is_cond_branch_e),
        .actual_taken_e(actual_taken_e),
        .actual_target_e(actual_target_e), .mispredict_e(mispredict_e),
        .redirect_e(redirect_e), .correct_pc_e(correct_pc_e)
    );

    task defaults;
        begin
            valid_e = 1;
            pc_e = 32'h0000_0100;
            pc_plus4_e = 32'h0000_0104;
            rs_value_e = 32'd5;
            rt_value_e = 32'd5;
            branch_offset_e = 32'h0000_000C;
            branch_eq_e = 0;
            branch_ne_e = 0;
            jump_reg_e = 0;
            pred_taken_e = 0;
            pred_target_e = 0;
        end
    endtask

    task check;
        input expected_control;
        input expected_cond;
        input expected_taken;
        input [31:0] expected_target;
        input expected_mispredict;
        input expected_redirect;
        input [31:0] expected_correct_pc;
        input [8*72-1:0] test_name;
        begin
            #1;
            if ({is_control_e, is_cond_branch_e, actual_taken_e,
                 actual_target_e, mispredict_e, redirect_e, correct_pc_e} !==
                {expected_control, expected_cond, expected_taken,
                 expected_target, expected_mispredict, expected_redirect,
                 expected_correct_pc}) begin
                errors = errors + 1;
                $display("FAIL: %0s", test_name);
                $display(" actual ctrl/cond/taken/target/mis/redir/pc = %b %b %b %h %b %b %h",
                         is_control_e, is_cond_branch_e, actual_taken_e,
                         actual_target_e, mispredict_e, redirect_e, correct_pc_e);
            end else
                $display("PASS: %0s", test_name);
        end
    endtask

    initial begin
        errors = 0;

        defaults(); valid_e = 0; branch_eq_e = 1;
        check(0,0,0,32'h0000_0110,0,0,32'h0000_0104,
              "invalid branch has no control effect");

        defaults(); branch_eq_e = 1;
        check(1,1,1,32'h0000_0110,1,1,32'h0000_0110,
              "static-not-taken BEQ taken redirects to exact target");

        defaults(); branch_eq_e = 1; rt_value_e = 6;
        check(1,1,0,32'h0000_0110,0,0,32'h0000_0104,
              "BEQ not taken follows PC plus four");

        defaults(); branch_ne_e = 1; rt_value_e = 6;
        check(1,1,1,32'h0000_0110,1,1,32'h0000_0110,
              "BNE taken redirects");

        defaults(); branch_ne_e = 1;
        check(1,1,0,32'h0000_0110,0,0,32'h0000_0104,
              "BNE not taken does not redirect");

        defaults(); branch_eq_e = 1;
        pred_taken_e = 1; pred_target_e = 32'h0000_0110;
        check(1,1,1,32'h0000_0110,0,0,32'h0000_0110,
              "correct taken prediction needs no redirect");

        defaults(); branch_eq_e = 1;
        pred_taken_e = 1; pred_target_e = 32'h0000_0200;
        check(1,1,1,32'h0000_0110,1,1,32'h0000_0110,
              "wrong predicted target redirects");

        defaults(); branch_eq_e = 1; rt_value_e = 6;
        pred_taken_e = 1; pred_target_e = 32'h0000_0110;
        check(1,1,0,32'h0000_0110,1,1,32'h0000_0104,
              "predicted taken but actually not taken corrects to PC plus four");

        defaults(); jump_reg_e = 1; rs_value_e = 32'h1234_5678;
        check(1,0,1,32'h1234_5678,0,1,32'h1234_5678,
              "JR always redirects to forwarded rs value");

        if (errors == 0) begin
            $display("BRANCH_UNIT_TB_PASS");
            $finish;
        end else
            $fatal(1, "BRANCH_UNIT_TB_FAIL: %0d errors", errors);
    end

endmodule
