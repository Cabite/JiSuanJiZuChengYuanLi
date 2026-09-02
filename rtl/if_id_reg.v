`timescale 1ns / 1ps

// IF/ID pipeline register.
// Synchronous control priority: reset > flush > enable > hold.
module if_id_reg(
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire        flush,

    input  wire        valid_f,
    input  wire [31:0] pc_f,
    input  wire [31:0] pc_plus4_f,
    input  wire [31:0] inst_f,
    input  wire        pred_taken_f,
    input  wire [31:0] pred_target_f,
    input  wire [5:0]  pred_index_f,

    output reg         valid_d,
    output reg  [31:0] pc_d,
    output reg  [31:0] pc_plus4_d,
    output reg  [31:0] inst_d,
    output reg         pred_taken_d,
    output reg  [31:0] pred_target_d,
    output reg  [5:0]  pred_index_d
);

    always @(posedge clk) begin
        if (reset) begin
            valid_d       <= 1'b0;
            pc_d          <= 32'b0;
            pc_plus4_d    <= 32'b0;
            inst_d        <= 32'b0;
            pred_taken_d  <= 1'b0;
            pred_target_d <= 32'b0;
            pred_index_d  <= 6'b0;
        end else if (flush) begin
            valid_d       <= 1'b0;
            pc_d          <= 32'b0;
            pc_plus4_d    <= 32'b0;
            inst_d        <= 32'b0;
            pred_taken_d  <= 1'b0;
            pred_target_d <= 32'b0;
            pred_index_d  <= 6'b0;
        end else if (enable) begin
            valid_d       <= valid_f;
            pc_d          <= pc_f;
            pc_plus4_d    <= pc_plus4_f;
            inst_d        <= inst_f;
            pred_taken_d  <= pred_taken_f;
            pred_target_d <= pred_target_f;
            pred_index_d  <= pred_index_f;
        end
    end

endmodule
