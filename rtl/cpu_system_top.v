`timescale 1ns / 1ps

// Standalone teaching system: CPU + independent instruction/data memories.
// Memories use combinational reads; this is NOT a synchronous-BRAM adapter.
// DEPTH parameters are word counts and should be powers of two >= 2.
module cpu_system_top #(
    parameter RESET_PC = 32'h0000_0000,
    parameter IMEM_DEPTH = 2048,
    parameter DMEM_DEPTH = 2048,
    parameter IMEM_INIT_FILE = "",
    parameter DMEM_INIT_FILE = ""
)(
    input  wire clk,
    input  wire reset,
    input  wire count_enable,
    input  wire clear_overflow,
    output wire overflow_led,
    output wire [31:0] debug_pc,
    output wire debug_write_enable,
    output wire [4:0] debug_write_addr,
    output wire [31:0] debug_write_data,
    output wire debug_retire,
    output wire [31:0] debug_wb_pc,
    output wire [63:0] cycle_count,
    output wire [63:0] retired_count,
    output wire [63:0] branch_count,
    output wire [63:0] mispredict_count,
    output wire [63:0] load_stall_count,
    output wire [63:0] mem_wait_count,
    output wire [63:0] flush_count
);
    wire [31:0] imem_addr, imem_rdata;
    wire dmem_valid, dmem_write, dmem_ready;
    wire [3:0] dmem_wstrb;
    wire [31:0] dmem_addr, dmem_wdata, dmem_rdata;

    assign debug_pc = imem_addr;

    // Prediction is deliberately fixed to the implemented static mode.
    cpu_core #(.RESET_PC(RESET_PC), .PRED_MODE(0)) u_cpu(
        .clk(clk), .reset(reset), .count_enable(count_enable),
        .clear_overflow(clear_overflow),
        .imem_addr(imem_addr), .imem_rdata(imem_rdata),
        .dmem_valid(dmem_valid), .dmem_write(dmem_write),
        .dmem_wstrb(dmem_wstrb), .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata), .dmem_rdata(dmem_rdata),
        .dmem_ready(dmem_ready), .overflow_status(overflow_led),
        .debug_write_enable(debug_write_enable),
        .debug_write_addr(debug_write_addr),
        .debug_write_data(debug_write_data), .debug_retire(debug_retire),
        .debug_wb_pc(debug_wb_pc), .cycle_count(cycle_count),
        .retired_count(retired_count), .branch_count(branch_count),
        .mispredict_count(mispredict_count),
        .load_stall_count(load_stall_count), .mem_wait_count(mem_wait_count),
        .flush_count(flush_count)
    );

    imem #(.DEPTH(IMEM_DEPTH), .INIT_FILE(IMEM_INIT_FILE)) u_imem(
        .addr(imem_addr), .rdata(imem_rdata)
    );

    // reset inhibits writes but preserves RAM contents, as defined by dmem.
    dmem #(.DEPTH(DMEM_DEPTH), .INIT_FILE(DMEM_INIT_FILE)) u_dmem(
        .clk(clk), .reset(reset), .valid(dmem_valid), .write(dmem_write),
        .wstrb(dmem_wstrb), .addr(dmem_addr), .wdata(dmem_wdata),
        .rdata(dmem_rdata), .ready(dmem_ready)
    );
endmodule
