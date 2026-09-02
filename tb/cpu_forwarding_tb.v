`timescale 1ns / 1ps

// Integration test: dependent instructions execute without ALU NOP spacing.
// One independent instruction remains between lw and its consumer because
// immediate load-use stalling belongs to stage 6.
module cpu_forwarding_tb;

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
    integer read_transactions;
    integer write_transactions;
    integer seen_m_forward;
    integer seen_w_forward;
    integer seen_store_forward;

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
        .INIT_FILE("stage5_forwarding_test.hex")
    ) u_imem(
        .addr(imem_addr), .rdata(imem_rdata)
    );

    dmem #(.DEPTH(64)) u_dmem(
        .clk(clk), .reset(reset), .valid(dmem_valid),
        .write(dmem_write), .wstrb(dmem_wstrb), .addr(dmem_addr),
        .wdata(dmem_wdata), .rdata(dmem_rdata), .ready(dmem_ready)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (reset) begin
            read_transactions  <= 0;
            write_transactions <= 0;
            seen_m_forward     <= 0;
            seen_w_forward     <= 0;
            seen_store_forward <= 0;
        end else begin
            if (dmem_valid && dmem_ready) begin
                if (dmem_write)
                    write_transactions <= write_transactions + 1;
                else
                    read_transactions <= read_transactions + 1;
            end

            if (dut.valid_e && ((dut.forward_a_e == 2'b10) ||
                                (dut.forward_b_e == 2'b10)))
                seen_m_forward <= seen_m_forward + 1;
            if (dut.valid_e && ((dut.forward_a_e == 2'b01) ||
                                (dut.forward_b_e == 2'b01)))
                seen_w_forward <= seen_w_forward + 1;
            if (dut.valid_e && dut.mem_write_e &&
                (dut.forward_store_e != 2'b00))
                seen_store_forward <= seen_store_forward + 1;
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

    task check_seen;
        input integer actual;
        input [8*56-1:0] test_name;
        begin
            if (actual <= 0) begin
                errors = errors + 1;
                $display("FAIL: %0s was never observed", test_name);
            end else begin
                $display("PASS: %0s observed %0d time(s)", test_name, actual);
            end
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        errors = 0;
        read_transactions = 0;
        write_transactions = 0;
        seen_m_forward = 0;
        seen_w_forward = 0;
        seen_store_forward = 0;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;

        repeat (26) @(posedge clk);
        #1;

        check32(dut.u_regfile.regs[0],  32'h0000_0000, "$0 rejects writes and false forwarding");
        check32(dut.u_regfile.regs[1],  32'h0000_0006, "dependent addiu chain writes $1");
        check32(dut.u_regfile.regs[2],  32'h0000_0008, "M priority produces $2 = 8");
        check32(dut.u_regfile.regs[3],  32'h0000_000E, "add uses M and W forwarding");
        check32(dut.u_regfile.regs[4],  32'h0000_0008, "sub uses immediately previous result");
        check32(dut.u_regfile.regs[5],  32'h0000_0008, "and uses forwarded operands");
        check32(dut.u_regfile.regs[6],  32'h0000_0008, "or uses forwarded operands");
        check32(dut.u_regfile.regs[7],  32'h1234_0000, "lui result is preserved");
        check32(dut.u_regfile.regs[8],  32'h1234_0001, "LUI forwards from M to addiu");
        check32(u_dmem.mem[0],           32'h1234_0001, "store receives immediate M forwarding");
        check32(dut.u_regfile.regs[9],  32'h1234_0001, "lw reads stored value");
        check32(dut.u_regfile.regs[10], 32'h0000_0007, "independent instruction after lw");
        check32(dut.u_regfile.regs[11], 32'h1234_0008, "load value forwards from W");
        check32(dut.u_regfile.regs[12], 32'h0000_0004, "destination zero does not forward");
        check32({31'b0, overflow_status}, 32'h0000_0000, "forwarding program has no overflow");

        check_seen(seen_m_forward, "EX/MEM forwarding");
        check_seen(seen_w_forward, "MEM/WB forwarding");
        check_seen(seen_store_forward, "store-data forwarding");

        if (write_transactions !== 1) begin
            errors = errors + 1;
            $display("FAIL: write transaction count actual=%0d expected=1", write_transactions);
        end else begin
            $display("PASS: exactly one store transaction");
        end
        if (read_transactions !== 1) begin
            errors = errors + 1;
            $display("FAIL: read transaction count actual=%0d expected=1", read_transactions);
        end else begin
            $display("PASS: exactly one load transaction");
        end

        if (errors == 0) begin
            $display("CPU_FORWARDING_TB_PASS");
            $finish;
        end else begin
            $fatal(1, "CPU_FORWARDING_TB_FAIL: %0d errors", errors);
        end
    end

endmodule
