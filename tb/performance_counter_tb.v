`timescale 1ns / 1ps

module performance_counter_tb;
    reg clk;
    reg reset;
    reg count_enable;
    reg retire_fire;
    reg branch_resolved;
    reg mispredict;
    reg load_use_stall;
    reg mem_wait;
    reg [1:0] flushed_valid_count;
    wire [63:0] cycle_count;
    wire [63:0] retired_count;
    wire [63:0] branch_count;
    wire [63:0] mispredict_count;
    wire [63:0] load_stall_count;
    wire [63:0] mem_wait_count;
    wire [63:0] flush_count;
    integer errors;

    performance_counter dut(
        .clk(clk), .reset(reset), .count_enable(count_enable),
        .retire_fire(retire_fire), .branch_resolved(branch_resolved),
        .mispredict(mispredict), .load_use_stall(load_use_stall),
        .mem_wait(mem_wait), .flushed_valid_count(flushed_valid_count),
        .cycle_count(cycle_count), .retired_count(retired_count),
        .branch_count(branch_count), .mispredict_count(mispredict_count),
        .load_stall_count(load_stall_count),
        .mem_wait_count(mem_wait_count), .flush_count(flush_count)
    );

    always #5 clk = ~clk;

    task check_all;
        input [63:0] cycles;
        input [63:0] retired;
        input [63:0] branches;
        input [63:0] misses;
        input [63:0] load_stalls;
        input [63:0] waits;
        input [63:0] flushes;
        input [8*64-1:0] test_name;
        begin
            #1;
            if ({cycle_count, retired_count, branch_count, mispredict_count,
                 load_stall_count, mem_wait_count, flush_count} !==
                {cycles, retired, branches, misses, load_stalls, waits,
                 flushes}) begin
                errors = errors + 1;
                $display("FAIL: %0s", test_name);
                $display(" actual c/r/b/m/l/w/f = %0d %0d %0d %0d %0d %0d %0d",
                    cycle_count, retired_count, branch_count,
                    mispredict_count, load_stall_count, mem_wait_count,
                    flush_count);
            end else
                $display("PASS: %0s", test_name);
        end
    endtask

    initial begin
        clk=0; reset=1; count_enable=0; retire_fire=0;
        branch_resolved=0; mispredict=0; load_use_stall=0;
        mem_wait=0; flushed_valid_count=0; errors=0;

        @(posedge clk); check_all(0,0,0,0,0,0,0, "reset clears all counters");
        @(negedge clk); reset=0;
        repeat (2) @(posedge clk);
        check_all(0,0,0,0,0,0,0, "disabled benchmark window holds counters");

        @(negedge clk);
        count_enable=1; retire_fire=1; branch_resolved=1;
        mispredict=1; load_use_stall=1; mem_wait=1;
        flushed_valid_count=2;
        @(posedge clk);
        check_all(1,1,1,1,1,1,2, "all enabled events count independently");

        @(negedge clk);
        retire_fire=0; branch_resolved=0; mispredict=0;
        load_use_stall=0; flushed_valid_count=0; mem_wait=1;
        repeat (3) @(posedge clk);
        check_all(4,1,1,1,1,4,2,
                  "physical cycles and waits count while retirement is frozen");

        @(negedge clk);
        count_enable=0; retire_fire=1; branch_resolved=1;
        mispredict=1; load_use_stall=1; mem_wait=1;
        flushed_valid_count=1;
        repeat (2) @(posedge clk);
        check_all(4,1,1,1,1,4,2,
                  "count_enable stops the complete benchmark snapshot");

        @(negedge clk); reset=1;
        @(posedge clk);
        check_all(0,0,0,0,0,0,0, "reset clears a completed snapshot");

        if (errors == 0) begin
            $display("PERFORMANCE_COUNTER_TB_PASS");
            $finish;
        end else
            $fatal(1, "PERFORMANCE_COUNTER_TB_FAIL: %0d errors", errors);
    end
endmodule
