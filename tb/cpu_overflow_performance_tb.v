`timescale 1ns / 1ps

module cpu_overflow_performance_tb;
    reg clk;
    reg reset;
    reg count_enable;
    reg clear_overflow;
    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;
    wire dmem_valid;
    wire dmem_write;
    wire [3:0] dmem_wstrb;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [31:0] dmem_rdata;
    wire dmem_ready;
    wire overflow_status;
    wire [63:0] cycle_count;
    wire [63:0] retired_count;
    wire [63:0] branch_count;
    wire [63:0] mispredict_count;
    wire [63:0] load_stall_count;
    wire [63:0] mem_wait_count;
    wire [63:0] flush_count;
    integer errors;
    integer overflow_events;
    integer read_transactions;

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

    imem #(.DEPTH(64), .INIT_FILE("stage9_overflow_test.hex")) u_imem(
        .addr(imem_addr), .rdata(imem_rdata)
    );

    dmem #(.DEPTH(64)) u_dmem(
        .clk(clk), .reset(reset), .valid(dmem_valid),
        .write(dmem_write), .wstrb(dmem_wstrb), .addr(dmem_addr),
        .wdata(dmem_wdata), .rdata(dmem_rdata), .ready(dmem_ready)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!reset) begin
            if (dut.set_overflow)
                overflow_events = overflow_events + 1;
            if (dmem_valid && dmem_ready && !dmem_write)
                read_transactions = read_transactions + 1;
        end
    end

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

    initial begin
        clk=0; reset=1; count_enable=0; clear_overflow=0;
        errors=0; overflow_events=0; read_transactions=0;
        #1;
        u_dmem.mem[0] = 32'h7fff_ffff;
        u_dmem.mem[1] = 32'h0000_0001;
        u_dmem.mem[2] = 32'h8000_0000;
        u_dmem.mem[3] = 32'h0000_0001;

        repeat (2) @(posedge clk);
        @(negedge clk); reset=0; count_enable=1;

        while (!(dut.valid_w && (dut.pc_w == 32'h0000_0024)))
            @(negedge clk);
        @(posedge clk);
        #1 count_enable=0;
        repeat (2) @(posedge clk);
        #1;

        check32(dut.u_regfile.regs[1], 32'h7fff_ffff, "load positive maximum");
        check32(dut.u_regfile.regs[2], 32'h0000_0001, "load positive one");
        check32(dut.u_regfile.regs[3], 32'h0000_0000, "overflowing ADD does not write back");
        check32(dut.u_regfile.regs[4], 32'h8000_0000, "ADDU wraps without trapping");
        check32(dut.u_regfile.regs[5], 32'h8000_0000, "load negative minimum");
        check32(dut.u_regfile.regs[6], 32'h0000_0001, "load subtraction operand one");
        check32(dut.u_regfile.regs[7], 32'h0000_0000, "overflowing SUB does not write back");
        check32(dut.u_regfile.regs[8], 32'h7fff_ffff, "SUBU wraps without trapping");
        check32(dut.u_regfile.regs[9], 32'h0000_0000, "overflowing ADDI does not write back");
        check32(dut.u_regfile.regs[10],32'h8000_0000, "ADDIU wraps without trapping");
        check32({31'b0,overflow_status},32'd1, "overflow status remains sticky");
        check32(overflow_events, 32'd3, "three signed overflow events retire");
        check32(read_transactions, 32'd4, "four load transactions complete");

        check32(cycle_count[31:0], 32'd16, "overflow benchmark cycle count");
        check32(retired_count[31:0], 32'd10, "overflow benchmark retired count");
        check32(load_stall_count[31:0], 32'd2, "overflow benchmark load stalls");
        check32(branch_count[31:0], 32'd0, "overflow benchmark branches");
        check32(mispredict_count[31:0], 32'd0, "overflow benchmark mispredictions");
        check32(mem_wait_count[31:0], 32'd0, "overflow benchmark memory waits");
        check32(flush_count[31:0], 32'd0, "overflow benchmark flushed instructions");

        $display("PERFORMANCE_RESULT_OVERFLOW: cycles=%0d retired=%0d CPI=%0.4f IPC=%0.4f load_stalls=%0d",
                 cycle_count, retired_count,
                 $itor(cycle_count[31:0]) / $itor(retired_count[31:0]),
                 $itor(retired_count[31:0]) / $itor(cycle_count[31:0]),
                 load_stall_count);

        @(negedge clk); clear_overflow=1;
        @(posedge clk); #1;
        check32({31'b0,overflow_status},32'd0, "explicit clear resets sticky status");
        @(negedge clk); clear_overflow=0;

        if (errors == 0) begin
            $display("CPU_OVERFLOW_PERFORMANCE_TB_PASS");
            $finish;
        end else
            $fatal(1, "CPU_OVERFLOW_PERFORMANCE_TB_FAIL: %0d errors", errors);
    end
endmodule
