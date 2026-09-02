`timescale 1ns / 1ps

// Stage-6 integration test.  The program contains no hand-written NOP between
// each lw and its immediate consumer; the hardware must insert the bubbles.
module cpu_hazard_tb;

    reg clk;
    reg reset;
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

    integer errors;
    integer stall_count;
    integer read_transactions;
    integer write_transactions;
    integer bubbles_checked;
    integer false_rt_case_seen;
    reg [31:0] held_pc;
    reg [31:0] held_inst;
    reg [4:0] advancing_load_dest;

    cpu_core dut(
        .clk(clk), .reset(reset), .count_enable(1'b1),
        .clear_overflow(1'b0), .imem_addr(imem_addr),
        .imem_rdata(imem_rdata), .dmem_valid(dmem_valid),
        .dmem_write(dmem_write), .dmem_wstrb(dmem_wstrb),
        .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata), .dmem_ready(dmem_ready),
        .overflow_status(overflow_status), .cycle_count(cycle_count)
    );

    imem #(
        .DEPTH(64),
        .INIT_FILE("stage6_hazard_test.hex")
    ) u_imem(
        .addr(imem_addr), .rdata(imem_rdata)
    );

    dmem #(.DEPTH(64)) u_dmem(
        .clk(clk), .reset(reset), .valid(dmem_valid),
        .write(dmem_write), .wstrb(dmem_wstrb), .addr(dmem_addr),
        .wdata(dmem_wdata), .rdata(dmem_rdata), .ready(dmem_ready)
    );

    always #5 clk = ~clk;

    // Check the controls immediately before a rising edge and their registered
    // effect immediately after it.
    always @(posedge clk) begin
        if (!reset) begin
            if (dmem_valid && dmem_ready) begin
                if (dmem_write)
                    write_transactions = write_transactions + 1;
                else
                    read_transactions = read_transactions + 1;
            end

            if (dut.valid_e && dut.mem_read_e && (dut.dest_e == 5'd3) &&
                dut.valid_d && (dut.inst_d == 32'h2403_0007)) begin
                false_rt_case_seen = false_rt_case_seen + 1;
                if (dut.load_use_stall !== 1'b0) begin
                    errors = errors + 1;
                    $display("FAIL: addiu rt field caused a false load-use stall");
                end
            end

            if (dut.load_use_stall) begin
                stall_count = stall_count + 1;
                held_pc = dut.pc_f;
                held_inst = dut.inst_d;
                advancing_load_dest = dut.dest_e;
                #1;
                if (dut.pc_f !== held_pc || dut.inst_d !== held_inst) begin
                    errors = errors + 1;
                    $display("FAIL: PC or IF/ID changed during load-use stall");
                end
                if (dut.valid_e !== 1'b0) begin
                    errors = errors + 1;
                    $display("FAIL: ID/EX did not become a bubble after stall");
                end
                if (!(dut.valid_m && dut.mem_read_m &&
                      (dut.dest_m == advancing_load_dest))) begin
                    errors = errors + 1;
                    $display("FAIL: stalled load did not continue into MEM");
                end
                bubbles_checked = bubbles_checked + 1;
            end
        end
    end

    task check32;
        input [31:0] actual;
        input [31:0] expected;
        input [8*60-1:0] test_name;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s actual=%h expected=%h", test_name, actual, expected);
            end else begin
                $display("PASS: %0s = %h", test_name, actual);
            end
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        errors = 0;
        stall_count = 0;
        read_transactions = 0;
        write_transactions = 0;
        bubbles_checked = 0;
        false_rt_case_seen = 0;

        // lw instructions read 8 from byte address zero.
        #1 u_dmem.mem[0] = 32'd8;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        repeat (30) @(posedge clk);
        #2;

        check32(dut.u_regfile.regs[1], 32'd8,  "first lw writes $1");
        check32(dut.u_regfile.regs[2], 32'd16, "immediate add receives loaded $1 twice");
        check32(dut.u_regfile.regs[3], 32'd7,  "addiu after lw is not falsely stalled");
        check32(dut.u_regfile.regs[4], 32'd8,  "load for store-data dependency completes");
        check32(dut.u_regfile.regs[5], 32'd8,  "load for store-base dependency completes");
        check32(dut.u_regfile.regs[6], 32'd8,  "instruction after hazards executes normally");
        check32(u_dmem.mem[1],          32'd8,  "load data forwards to immediate sw data");
        check32(u_dmem.mem[2],          32'd16, "loaded base drives immediate sw address");
        check32({31'b0, overflow_status}, 32'd0, "hazard program has no overflow");

        if (stall_count !== 3) begin
            errors = errors + 1;
            $display("FAIL: load-use stall count actual=%0d expected=3", stall_count);
        end else
            $display("PASS: exactly three real load-use stalls");

        if (bubbles_checked !== 3) begin
            errors = errors + 1;
            $display("FAIL: checked bubbles actual=%0d expected=3", bubbles_checked);
        end else
            $display("PASS: every stall held IF and inserted an EX bubble");

        if (false_rt_case_seen !== 1) begin
            errors = errors + 1;
            $display("FAIL: false-rt scenario observations=%0d expected=1", false_rt_case_seen);
        end else
            $display("PASS: I-type rt false dependency was tested");

        if (read_transactions !== 4 || write_transactions !== 2) begin
            errors = errors + 1;
            $display("FAIL: transactions reads=%0d/4 writes=%0d/2",
                     read_transactions, write_transactions);
        end else
            $display("PASS: memory transactions reads=4 writes=2");

        if (errors == 0) begin
            $display("CPU_HAZARD_TB_PASS");
            $finish;
        end else begin
            $fatal(1, "CPU_HAZARD_TB_FAIL: %0d errors", errors);
        end
    end

endmodule
