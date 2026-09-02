`timescale 1ns / 1ps

// Stage-7 static predictor: every conditional branch is predicted not taken.
// The update interface and PRED_MODE parameter are reserved for the stage-8
// 64-entry BHT+BTB implementation.
module branch_predictor #(
    parameter PRED_MODE = 0,
    parameter ENTRY_NUM = 64
)(
    input  wire        clk,
    input  wire        reset,
    input  wire [31:0] query_pc,
    input  wire        query_valid,
    output wire        pred_taken,
    output wire [31:0] pred_target,
    output wire [5:0]  pred_index,
    output wire        btb_hit,

    input  wire        update_enable,
    input  wire [31:0] update_pc,
    input  wire [5:0]  update_index,
    input  wire        actual_taken,
    input  wire [31:0] actual_target
);

    assign pred_taken  = 1'b0;
    assign pred_target = query_pc + 32'd4;
    assign pred_index  = query_pc[7:2];
    assign btb_hit     = 1'b0;

    // Stage 7 deliberately ignores the update ports.  Stage 8 will use them
    // when PRED_MODE selects the dynamic BHT+BTB implementation.

endmodule
