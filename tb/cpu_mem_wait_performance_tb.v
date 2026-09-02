`timescale 1ns / 1ps

// Integration check that a WB instruction held during a MEM wait retires once,
// while physical cycles and memory-wait cycles continue to be counted.
module cpu_mem_wait_performance_tb;
    reg clk;
    reg reset;
    reg count_enable;
    reg clear_overflow;
    reg dmem_ready;
    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;
    wire dmem_valid;
    wire dmem_write;
    wire [3:0] dmem_wstrb;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [31:0] dmem_rdata;
    wire overflow_status;
    wire [63:0] cycle_count;
    wire [63:0] retired_count;
    wire [63:0] branch_count;
    wire [63:0] mispredict_count;
    wire [63:0] load_stall_count;
    wire [63:0] mem_wait_count;
    wire [63:0] flush_count;
    integer errors;

    assign dmem_rdata = (dmem_valid && !dmem_write) ? 32'd9 : 32'd0;

    cpu_core #(.PRED_MODE(0)) dut(
        .clk(clk), .reset(reset), .count_enable(count_enable),
        .clear_overflow(clear_overflow), .imem_addr(imem_addr),
        .imem_rdata(imem_rdata), .dmem_valid(dmem_valid),
        .dmem_write(dmem_write), .dmem_wstrb(dmem_wstrb),
        .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata), .dmem_ready(dmem_ready),
        .overflow_status(overflow_status), .cycle_count(cycle_count),
        .retired_count(retired_count), .branch_count(branch_count),
        .mispredict_count(mispredict_count),
        .load_stall_count(load_stall_count),
        .mem_wait_count(mem_wait_count), .flush_count(flush_count)
    );

    imem #(.DEPTH(32), .INIT_FILE("stage9_memwait_test.hex")) u_imem(
        .addr(imem_addr), .rdata(imem_rdata)
    );

    always #5 clk = ~clk;

    task check32;
        input [31:0] actual;
        input [31:0] expected;
        input [8*60-1:0] test_name;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s actual=%h expected=%h",
                         test_name, actual, expected);
            end else
                $display("PASS: %0s = %h", test_name, actual);
        end
    endtask

    // Insert exactly three wait-state rising edges into the load transaction.
    initial begin
        dmem_ready = 1;
        wait (!reset && dmem_valid && !dmem_write);
        @(negedge clk); dmem_ready = 0;
        repeat (3) @(posedge clk);
        @(negedge clk); dmem_ready = 1;
    end

    initial begin
        clk=0; reset=1; count_enable=0; clear_overflow=0; errors=0;
        repeat (2) @(posedge clk);
        @(negedge clk); reset=0; count_enable=1;

        while (!(dut.valid_w && (dut.pc_w == 32'h0000_000c)))
            @(negedge clk);
        @(posedge clk);
        #1 count_enable=0;
        repeat (2) @(posedge clk);
        #1;

        check32(dut.u_regfile.regs[1],32'd1,"first instruction writes once");
        check32(dut.u_regfile.regs[2],32'd2,"WB value survives global freeze");
        check32(dut.u_regfile.regs[3],32'd9,"load completes after ready returns");
        check32(dut.u_regfile.regs[4],32'd4,"younger instruction resumes");
        check32(cycle_count[31:0],32'd11,"physical cycles include three waits");
        check32(retired_count[31:0],32'd4,"frozen WB instruction retires once");
        check32(mem_wait_count[31:0],32'd3,"memory wait cycle count");
        check32(load_stall_count[31:0],32'd0,"independent load consumer has no stall");
        check32(branch_count[31:0],32'd0,"memory benchmark branch count");
        check32(mispredict_count[31:0],32'd0,"memory benchmark misprediction count");
        check32(flush_count[31:0],32'd0,"memory benchmark flush count");

        $display("PERFORMANCE_RESULT_MEMWAIT: cycles=%0d retired=%0d CPI=%0.4f IPC=%0.4f mem_waits=%0d",
                 cycle_count, retired_count,
                 $itor(cycle_count[31:0]) / $itor(retired_count[31:0]),
                 $itor(retired_count[31:0]) / $itor(cycle_count[31:0]),
                 mem_wait_count);

        if (errors == 0) begin
            $display("CPU_MEM_WAIT_PERFORMANCE_TB_PASS");
            $finish;
        end else
            $fatal(1, "CPU_MEM_WAIT_PERFORMANCE_TB_FAIL: %0d errors", errors);
    end
endmodule
