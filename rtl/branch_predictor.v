`timescale 1ns / 1ps

// Dynamic branch predictor with 64-entry BHT (2-bit saturating counters)
// and 64-entry direct-mapped BTB (tag + target).
// PRED_MODE = 0: static not-taken
// PRED_MODE = 1: dynamic (BHT + BTB)
module branch_predictor #(
    parameter PRED_MODE = 1,      // 0: static, 1: dynamic
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

    // ---------- BHT: 64 x 2-bit saturating counters ----------
    reg [1:0] bht [0:ENTRY_NUM-1];
    // BTB: 64 x {valid, tag[23:0], target[31:0]}
    reg       btb_valid [0:ENTRY_NUM-1];
    reg [23:0] btb_tag  [0:ENTRY_NUM-1];
    reg [31:0] btb_target [0:ENTRY_NUM-1];

    wire [5:0] index;
    wire [23:0] tag;
    wire btb_hit_comb;
    wire bht_taken_comb;
    wire dynamic_taken_comb;

    integer i;

    // Reset all tables to known state.
    // BHT: all entries to 2'b01 (weakly not-taken)
    // BTB: all invalid
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < ENTRY_NUM; i = i + 1) begin
                bht[i] <= 2'b01;
                btb_valid[i] <= 1'b0;
                btb_tag[i] <= 24'b0;
                btb_target[i] <= 32'b0;
            end
        end else if (update_enable) begin
            // Update BHT at the resolved index
            if (actual_taken) begin
                if (bht[update_index] != 2'b11)
                    bht[update_index] <= bht[update_index] + 2'b1;
            end else begin
                if (bht[update_index] != 2'b00)
                    bht[update_index] <= bht[update_index] - 2'b1;
            end

            // Update BTB: if taken, write/update target; if not taken, leave BTB unchanged
            if (actual_taken) begin
                btb_valid[update_index] <= 1'b1;
                btb_tag[update_index]   <= update_pc[31:8];
                btb_target[update_index] <= actual_target;
            end
            // If not taken, we do NOT clear BTB; keep old target for future use.
        end
    end

    // ---------- Combinational query path ----------
    assign index = query_pc[7:2];
    assign tag   = query_pc[31:8];

    assign btb_hit_comb = btb_valid[index] && (btb_tag[index] == tag);
    assign bht_taken_comb = bht[index][1];   // MSB = 1 means taken (WT or ST)
    assign dynamic_taken_comb = bht_taken_comb && btb_hit_comb;

    // Outputs
    assign pred_index = index;

    // Select between static and dynamic modes
    // The PC mux in cpu_core only honors pred_taken when the fetched instruction
    // is a real conditional branch (beq/bne).  The predictor itself has no view
    // of the instruction, so branch-type qualification is applied at that mux.
    assign pred_taken = (PRED_MODE == 1) ? dynamic_taken_comb : 1'b0;
    assign pred_target = (PRED_MODE == 1 && dynamic_taken_comb) ?
                         btb_target[index] : (query_pc + 32'd4);
    assign btb_hit = btb_hit_comb;

endmodule