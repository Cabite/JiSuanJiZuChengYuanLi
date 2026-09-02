`timescale 1ns / 1ps

// EX/MEM pipeline register.
// Synchronous control priority: reset > flush > enable > hold.
module ex_mem_reg(
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    input  wire        flush,

    input  wire        valid_e,
    input  wire [31:0] pc_e,
    input  wire [31:0] pc_plus4_e,
    input  wire [31:0] alu_result_e,
    input  wire [31:0] store_data_e,
    input  wire [31:0] lui_value_e,
    input  wire [4:0]  dest_e,
    input  wire        reg_write_e,
    input  wire        mem_read_e,
    input  wire        mem_write_e,
    input  wire [1:0]  result_src_e,
    input  wire        overflow_e,

    output reg         valid_m,
    output reg  [31:0] pc_m,
    output reg  [31:0] pc_plus4_m,
    output reg  [31:0] alu_result_m,
    output reg  [31:0] store_data_m,
    output reg  [31:0] lui_value_m,
    output reg  [4:0]  dest_m,
    output reg         reg_write_m,
    output reg         mem_read_m,
    output reg         mem_write_m,
    output reg  [1:0]  result_src_m,
    output reg         overflow_m
);

    always @(posedge clk) begin
        if (reset) begin
            valid_m       <= 1'b0;
            pc_m          <= 32'b0;
            pc_plus4_m    <= 32'b0;
            alu_result_m  <= 32'b0;
            store_data_m  <= 32'b0;
            lui_value_m   <= 32'b0;
            dest_m        <= 5'b0;
            reg_write_m   <= 1'b0;
            mem_read_m    <= 1'b0;
            mem_write_m   <= 1'b0;
            result_src_m  <= 2'b0;
            overflow_m    <= 1'b0;
        end else if (flush) begin
            valid_m       <= 1'b0;
            pc_m          <= 32'b0;
            pc_plus4_m    <= 32'b0;
            alu_result_m  <= 32'b0;
            store_data_m  <= 32'b0;
            lui_value_m   <= 32'b0;
            dest_m        <= 5'b0;
            reg_write_m   <= 1'b0;
            mem_read_m    <= 1'b0;
            mem_write_m   <= 1'b0;
            result_src_m  <= 2'b0;
            overflow_m    <= 1'b0;
        end else if (enable) begin
            valid_m       <= valid_e;
            pc_m          <= pc_e;
            pc_plus4_m    <= pc_plus4_e;
            alu_result_m  <= alu_result_e;
            store_data_m  <= store_data_e;
            lui_value_m   <= lui_value_e;
            dest_m        <= dest_e;
            reg_write_m   <= reg_write_e;
            mem_read_m    <= mem_read_e;
            mem_write_m   <= mem_write_e;
            result_src_m  <= result_src_e;
            overflow_m    <= overflow_e;
        end
    end

endmodule
