`timescale 1ns / 1ps

// MEM/WB pipeline register.
// Synchronous control priority: reset > flush > enable > hold.
module mem_wb_reg(
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire        flush,

    input  wire        valid_m,
    input  wire [31:0] pc_m,
    input  wire [31:0] pc_plus4_m,
    input  wire [31:0] alu_result_m,
    input  wire [31:0] mem_rdata_m,
    input  wire [31:0] lui_value_m,
    input  wire [4:0]  dest_m,
    input  wire        reg_write_m,
    input  wire [1:0]  result_src_m,
    input  wire        overflow_m,

    output reg         valid_w,
    output reg  [31:0] pc_w,
    output reg  [31:0] pc_plus4_w,
    output reg  [31:0] alu_result_w,
    output reg  [31:0] mem_rdata_w,
    output reg  [31:0] lui_value_w,
    output reg  [4:0]  dest_w,
    output reg         reg_write_w,
    output reg  [1:0]  result_src_w,
    output reg         overflow_w
);

    always @(posedge clk) begin
        if (reset) begin
            valid_w       <= 1'b0;
            pc_w          <= 32'b0;
            pc_plus4_w    <= 32'b0;
            alu_result_w  <= 32'b0;
            mem_rdata_w   <= 32'b0;
            lui_value_w   <= 32'b0;
            dest_w        <= 5'b0;
            reg_write_w   <= 1'b0;
            result_src_w  <= 2'b0;
            overflow_w    <= 1'b0;
        end else if (flush) begin
            valid_w       <= 1'b0;
            pc_w          <= 32'b0;
            pc_plus4_w    <= 32'b0;
            alu_result_w  <= 32'b0;
            mem_rdata_w   <= 32'b0;
            lui_value_w   <= 32'b0;
            dest_w        <= 5'b0;
            reg_write_w   <= 1'b0;
            result_src_w  <= 2'b0;
            overflow_w    <= 1'b0;
        end else if (enable) begin
            valid_w       <= valid_m;
            pc_w          <= pc_m;
            pc_plus4_w    <= pc_plus4_m;
            alu_result_w  <= alu_result_m;
            mem_rdata_w   <= mem_rdata_m;
            lui_value_w   <= lui_value_m;
            dest_w        <= dest_m;
            reg_write_w   <= reg_write_m;
            result_src_w  <= result_src_m;
            overflow_w    <= overflow_m;
        end
    end

endmodule
