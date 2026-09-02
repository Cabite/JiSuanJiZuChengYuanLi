`timescale 1ns / 1ps

module performance_counter(
    input  wire        clk,
    input  wire        reset,
    input  wire        count_enable,
    input  wire        retire_fire,
    input  wire        branch_resolved,
    input  wire        mispredict,
    input  wire        load_use_stall,
    input  wire        mem_wait,
    input  wire [1:0]  flushed_valid_count,

    output reg  [63:0] cycle_count,
    output reg  [63:0] retired_count,
    output reg  [63:0] branch_count,
    output reg  [63:0] mispredict_count,
    output reg  [63:0] load_stall_count,
    output reg  [63:0] mem_wait_count,
    output reg  [63:0] flush_count
);

    always @(posedge clk) begin
        if (reset) begin
            cycle_count      <= 64'b0;
            retired_count    <= 64'b0;
            branch_count     <= 64'b0;
            mispredict_count <= 64'b0;
            load_stall_count <= 64'b0;
            mem_wait_count   <= 64'b0;
            flush_count      <= 64'b0;
        end else if (count_enable) begin
            cycle_count <= cycle_count + 64'd1;

            if (retire_fire)
                retired_count <= retired_count + 64'd1;
            if (branch_resolved)
                branch_count <= branch_count + 64'd1;
            if (mispredict)
                mispredict_count <= mispredict_count + 64'd1;
            if (load_use_stall)
                load_stall_count <= load_stall_count + 64'd1;
            if (mem_wait)
                mem_wait_count <= mem_wait_count + 64'd1;
            if (flushed_valid_count != 2'b00)
                flush_count <= flush_count + flushed_valid_count;
        end
    end

endmodule
