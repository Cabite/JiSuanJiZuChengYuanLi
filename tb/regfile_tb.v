`timescale 1ns / 1ps

module regfile_tb;

    reg         clk;
    reg         reset;
    reg  [4:0]  raddr1;
    reg  [4:0]  raddr2;
    wire [31:0] rdata1;
    wire [31:0] rdata2;
    reg         write_enable;
    reg  [4:0]  write_addr;
    reg  [31:0] write_data;
    integer errors;

    regfile dut(
        .clk(clk),
        .reset(reset),
        .raddr1(raddr1),
        .raddr2(raddr2),
        .rdata1(rdata1),
        .rdata2(rdata2),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data)
    );

    always #5 clk = ~clk;

    task write_register;
        input [4:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);
            write_enable = 1'b1;
            write_addr = addr;
            write_data = data;
            @(posedge clk);
            #1 write_enable = 1'b0;
        end
    endtask

    task check_ports;
        input [4:0] addr1;
        input [31:0] expected1;
        input [4:0] addr2;
        input [31:0] expected2;
        input [8*48-1:0] test_name;
        begin
            raddr1 = addr1;
            raddr2 = addr2;
            #1;
            if ((rdata1 !== expected1) || (rdata2 !== expected2)) begin
                errors = errors + 1;
                $display("FAIL: %0s", test_name);
                $display("  port1 r%0d=%h expected=%h", addr1, rdata1, expected1);
                $display("  port2 r%0d=%h expected=%h", addr2, rdata2, expected2);
            end else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        raddr1 = 5'd0;
        raddr2 = 5'd0;
        write_enable = 1'b0;
        write_addr = 5'd0;
        write_data = 32'b0;
        errors = 0;

        @(posedge clk);
        #1 reset = 1'b0;
        check_ports(5'd0, 32'b0, 5'd31, 32'b0, "reset clears registers and r0 is zero");

        write_register(5'd1, 32'h1234_5678);
        check_ports(5'd1, 32'h1234_5678, 5'd0, 32'b0, "write and asynchronous read r1");

        write_register(5'd2, 32'h89ab_cdef);
        check_ports(5'd1, 32'h1234_5678, 5'd2, 32'h89ab_cdef, "two independent read ports");

        write_register(5'd0, 32'hffff_ffff);
        check_ports(5'd0, 32'b0, 5'd1, 32'h1234_5678, "writes to r0 are ignored");

        @(negedge clk);
        write_enable = 1'b0;
        write_addr = 5'd1;
        write_data = 32'hdead_beef;
        @(posedge clk);
        #1;
        check_ports(5'd1, 32'h1234_5678, 5'd2, 32'h89ab_cdef,
                    "write_enable zero preserves registers");

        @(negedge clk);
        reset = 1'b1;
        write_enable = 1'b1;
        write_addr = 5'd3;
        write_data = 32'hffff_0000;
        @(posedge clk);
        #1 reset = 1'b0;
        write_enable = 1'b0;
        check_ports(5'd1, 32'b0, 5'd2, 32'b0, "reset has priority over write");
        check_ports(5'd3, 32'b0, 5'd31, 32'b0, "reset clears all tested registers");

        if (errors == 0) begin
            $display("REGFILE_TB_PASS");
            $finish;
        end else begin
            $fatal(1, "REGFILE_TB_FAIL: %0d errors", errors);
        end
    end

endmodule

