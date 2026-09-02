`timescale 1ns / 1ps

module branch_predictor_static_tb;

    reg clk;
    reg reset;
    reg [31:0] query_pc;
    reg query_valid;
    reg update_enable;
    reg [31:0] update_pc;
    reg [5:0] update_index;
    reg actual_taken;
    reg [31:0] actual_target;
    wire pred_taken;
    wire [31:0] pred_target;
    wire [5:0] pred_index;
    wire btb_hit;
    integer errors;

    branch_predictor #(.PRED_MODE(0), .ENTRY_NUM(64)) dut(
        .clk(clk), .reset(reset), .query_pc(query_pc),
        .query_valid(query_valid), .pred_taken(pred_taken),
        .pred_target(pred_target), .pred_index(pred_index),
        .btb_hit(btb_hit), .update_enable(update_enable),
        .update_pc(update_pc), .update_index(update_index),
        .actual_taken(actual_taken), .actual_target(actual_target)
    );

    always #5 clk = ~clk;

    task check_query;
        input [31:0] pc;
        input [8*52-1:0] test_name;
        begin
            query_pc = pc;
            #1;
            if (pred_taken !== 1'b0 || btb_hit !== 1'b0 ||
                pred_target !== (pc + 32'd4) ||
                pred_index !== pc[7:2]) begin
                errors = errors + 1;
                $display("FAIL: %0s taken=%b hit=%b target=%h index=%h",
                         test_name, pred_taken, btb_hit,
                         pred_target, pred_index);
            end else
                $display("PASS: %0s", test_name);
        end
    endtask

    initial begin
        clk = 0; reset = 1; query_pc = 0; query_valid = 1;
        update_enable = 0; update_pc = 0; update_index = 0;
        actual_taken = 0; actual_target = 0; errors = 0;

        check_query(32'h0000_0000, "reset-time query predicts sequential PC");
        @(negedge clk); reset = 0;
        check_query(32'h1234_00FC, "static predictor uses PC bits 7 through 2 as index");

        // A taken update must not alter stage-7 static prediction.
        update_enable = 1; update_pc = 32'h1234_00FC;
        update_index = 6'h3F; actual_taken = 1;
        actual_target = 32'h1234_010C;
        @(posedge clk); #1; update_enable = 0;
        check_query(32'h1234_00FC, "taken update is ignored in static mode");

        if (errors == 0) begin
            $display("BRANCH_PREDICTOR_STATIC_TB_PASS");
            $finish;
        end else
            $fatal(1, "BRANCH_PREDICTOR_STATIC_TB_FAIL: %0d errors", errors);
    end

endmodule
