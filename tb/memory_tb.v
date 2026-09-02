`timescale 1ns / 1ps

module memory_tb;

    reg         clk;
    reg  [31:0] imem_addr;
    wire [31:0] imem_rdata;

    reg         dmem_reset;
    reg         dmem_valid;
    reg         dmem_write;
    reg  [3:0]  dmem_wstrb;
    reg  [31:0] dmem_addr;
    reg  [31:0] dmem_wdata;
    wire [31:0] dmem_rdata;
    wire        dmem_ready;

    integer errors;

    imem #(
        .DEPTH(4),
        .INIT_FILE("stage2_imem_test.hex")
    ) dut_imem(
        .addr(imem_addr),
        .rdata(imem_rdata)
    );

    dmem #(
        .DEPTH(4),
        .INIT_FILE("")
    ) dut_dmem(
        .clk(clk),
        .reset(dmem_reset),
        .valid(dmem_valid),
        .write(dmem_write),
        .wstrb(dmem_wstrb),
        .addr(dmem_addr),
        .wdata(dmem_wdata),
        .rdata(dmem_rdata),
        .ready(dmem_ready)
    );

    always #5 clk = ~clk;

    task check_imem;
        input [31:0] address;
        input [31:0] expected;
        input [8*48-1:0] test_name;
        begin
            imem_addr = address;
            #1;
            if (imem_rdata !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s rdata=%h expected=%h", test_name, imem_rdata, expected);
            end else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    task write_dmem;
        input [31:0] address;
        input [31:0] data;
        input [3:0] strobes;
        begin
            @(negedge clk);
            dmem_valid = 1'b1;
            dmem_write = 1'b1;
            dmem_addr = address;
            dmem_wdata = data;
            dmem_wstrb = strobes;
            @(posedge clk);
            #1;
            dmem_valid = 1'b0;
            dmem_write = 1'b0;
            dmem_wstrb = 4'b0;
        end
    endtask

    task check_dmem;
        input [31:0] address;
        input [31:0] expected;
        input [8*48-1:0] test_name;
        begin
            dmem_valid = 1'b1;
            dmem_write = 1'b0;
            dmem_addr = address;
            #1;
            if (dmem_rdata !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s rdata=%h expected=%h", test_name, dmem_rdata, expected);
            end else begin
                $display("PASS: %0s", test_name);
            end
            dmem_valid = 1'b0;
            #1;
        end
    endtask

    initial begin
        clk = 1'b0;
        imem_addr = 32'b0;
        dmem_reset = 1'b0;
        dmem_valid = 1'b0;
        dmem_write = 1'b0;
        dmem_wstrb = 4'b0;
        dmem_addr = 32'b0;
        dmem_wdata = 32'b0;
        errors = 0;

        #1;
        if (dmem_ready !== 1'b1) begin
            errors = errors + 1;
            $display("FAIL: behavioral dmem ready must be one");
        end else begin
            $display("PASS: behavioral dmem ready is one");
        end

        check_imem(32'h0000_0000, 32'h0022_1820, "imem word 0: add");
        check_imem(32'h0000_0004, 32'h0061_2022, "imem word 1: sub");
        check_imem(32'h0000_0008, 32'h2405_ffff, "imem word 2: addiu");
        check_imem(32'h0000_000c, 32'h3c06_1234, "imem word 3: lui");
        check_imem(32'h0000_0010, 32'h0000_0000, "imem out-of-range returns NOP");

        write_dmem(32'h0000_0000, 32'hdead_beef, 4'b1111);
        check_dmem(32'h0000_0000, 32'hdead_beef, "dmem full-word write and read");

        write_dmem(32'h0000_0004, 32'haabb_ccdd, 4'b0011);
        check_dmem(32'h0000_0004, 32'h0000_ccdd, "dmem low-byte strobes");

        write_dmem(32'h0000_0004, 32'h1122_3344, 4'b1100);
        check_dmem(32'h0000_0004, 32'h1122_ccdd, "dmem high-byte strobes preserve low bytes");

        @(negedge clk);
        dmem_valid = 1'b0;
        dmem_write = 1'b1;
        dmem_wstrb = 4'b1111;
        dmem_addr = 32'h0000_0000;
        dmem_wdata = 32'h1234_5678;
        @(posedge clk);
        #1;
        dmem_write = 1'b0;
        check_dmem(32'h0000_0000, 32'hdead_beef, "invalid write has no effect");

        @(negedge clk);
        dmem_reset = 1'b1;
        dmem_valid = 1'b1;
        dmem_write = 1'b1;
        dmem_wstrb = 4'b1111;
        dmem_addr = 32'h0000_0008;
        dmem_wdata = 32'hffff_ffff;
        @(posedge clk);
        #1;
        dmem_reset = 1'b0;
        dmem_valid = 1'b0;
        dmem_write = 1'b0;
        check_dmem(32'h0000_0008, 32'h0000_0000, "reset suppresses writes");

        write_dmem(32'h0000_0010, 32'hffff_ffff, 4'b1111);
        check_dmem(32'h0000_0010, 32'h0000_0000, "out-of-range access is harmless");

        dmem_valid = 1'b0;
        dmem_write = 1'b0;
        dmem_addr = 32'h0000_0000;
        #1;
        if (dmem_rdata !== 32'b0) begin
            errors = errors + 1;
            $display("FAIL: inactive read must return zero, actual=%h", dmem_rdata);
        end else begin
            $display("PASS: inactive read returns zero");
        end

        if (errors == 0) begin
            $display("MEMORY_TB_PASS");
            $finish;
        end else begin
            $fatal(1, "MEMORY_TB_FAIL: %0d errors", errors);
        end
    end

endmodule

