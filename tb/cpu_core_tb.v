`timescale 1ns / 1ps

// Stage-4 integration test for the minimum five-stage CPU.
// Dependencies in stage4_cpu_test.hex are separated by three NOPs because
// forwarding and hazard detection are intentionally not implemented yet.
module cpu_core_tb;

    reg clk;
    reg reset;

    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;
    wire        dmem_valid;
    wire        dmem_write;
    wire [3:0]  dmem_wstrb;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [31:0] dmem_rdata;
    wire        dmem_ready;
    wire        overflow_status;
    wire [63:0] cycle_count;

    integer errors;
    integer read_transactions;
    integer write_transactions;

    cpu_core dut(
        .clk(clk),
        .reset(reset),
        .count_enable(1'b1),
        .clear_overflow(1'b0),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_valid(dmem_valid),
        .dmem_write(dmem_write),
        .dmem_wstrb(dmem_wstrb),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata),
        .dmem_ready(dmem_ready),
        .overflow_status(overflow_status),
        .cycle_count(cycle_count)
    );

    imem #(
        .DEPTH(64),
        .INIT_FILE("stage4_cpu_test.hex")
    ) u_imem(
        .addr(imem_addr),
        .rdata(imem_rdata)
    );

    dmem #(
        .DEPTH(64)
    ) u_dmem(
        .clk(clk),
        .reset(reset),
        .valid(dmem_valid),
        .write(dmem_write),
        .wstrb(dmem_wstrb),
        .addr(dmem_addr),
        .wdata(dmem_wdata),
        .rdata(dmem_rdata),
        .ready(dmem_ready)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (reset) begin
            read_transactions  <= 0;
            write_transactions <= 0;
        end else if (dmem_valid && dmem_ready) begin
            if (dmem_write)
                write_transactions <= write_transactions + 1;
            else
                read_transactions <= read_transactions + 1;
        end
    end

    task check32;
        input [31:0] actual;
        input [31:0] expected;
        input [8*56-1:0] test_name;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s actual=%h expected=%h", test_name, actual, expected);
            end else begin
                $display("PASS: %0s = %h", test_name, actual);
            end
        end
    endtask

    task check1;
        input actual;
        input expected;
        input [8*56-1:0] test_name;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s actual=%b expected=%b", test_name, actual, expected);
            end else begin
                $display("PASS: %0s = %b", test_name, actual);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        errors = 0;
        read_transactions = 0;
        write_transactions = 0;

        // Apply reset for two rising edges, then release on a falling edge.
        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 1'b0;

        // After four advancing edges, five different PCs occupy IF..WB.
        repeat (4) @(posedge clk);
        #1;
        check1(dut.valid_d, 1'b1, "ID stage is valid when pipeline is full");
        check1(dut.valid_e, 1'b1, "EX stage is valid when pipeline is full");
        check1(dut.valid_m, 1'b1, "MEM stage is valid when pipeline is full");
        check1(dut.valid_w, 1'b1, "WB stage is valid when pipeline is full");
        check32(dut.pc_f, 32'h0000_0010, "IF stage PC");
        check32(dut.pc_d, 32'h0000_000C, "ID stage PC");
        check32(dut.pc_e, 32'h0000_0008, "EX stage PC");
        check32(dut.pc_m, 32'h0000_0004, "MEM stage PC");
        check32(dut.pc_w, 32'h0000_0000, "WB stage PC");

        // Run long enough for the final lw to reach and commit in WB.
        repeat (36) @(posedge clk);
        #1;

        check32(dut.u_regfile.regs[0], 32'h0000_0000, "$0 remains hard-wired to zero");
        check32(dut.u_regfile.regs[1], 32'h0000_0005, "addiu writes $1 = 5");
        check32(dut.u_regfile.regs[2], 32'h0000_0003, "addiu writes $2 = 3");
        check32(dut.u_regfile.regs[3], 32'h0000_0008, "add writes $3 = 8");
        check32(dut.u_regfile.regs[4], 32'h0000_0002, "sub writes $4 = 2");
        check32(dut.u_regfile.regs[5], 32'h0000_0001, "and writes $5 = 1");
        check32(dut.u_regfile.regs[6], 32'h0000_0007, "or writes $6 = 7");
        check32(dut.u_regfile.regs[7], 32'h1234_0000, "lui writes upper immediate");
        check32(u_dmem.mem[0], 32'h0000_0008, "sw stores $3 into data RAM word 0");
        check32(dut.u_regfile.regs[8], 32'h0000_0008, "lw loads RAM word 0 into $8");
        check1(overflow_status, 1'b0, "normal test program has no overflow");

        if (write_transactions !== 1) begin
            errors = errors + 1;
            $display("FAIL: write transaction count actual=%0d expected=1", write_transactions);
        end else begin
            $display("PASS: exactly one data-memory write transaction");
        end

        if (read_transactions !== 1) begin
            errors = errors + 1;
            $display("FAIL: read transaction count actual=%0d expected=1", read_transactions);
        end else begin
            $display("PASS: exactly one data-memory read transaction");
        end

        if (errors == 0) begin
            $display("CPU_CORE_TB_PASS");
            $finish;
        end else begin
            $fatal(1, "CPU_CORE_TB_FAIL: %0d errors", errors);
        end
    end

endmodule
