`timescale 1ns / 1ps

module mux_tb;

    reg  [31:0] a32;
    reg  [31:0] b32;
    reg  [31:0] c32;
    reg         sel2;
    reg  [1:0]  sel3;
    wire [31:0] y2_32;
    wire [31:0] y3_32;

    reg  [4:0] a5;
    reg  [4:0] b5;
    reg        sel5;
    wire [4:0] y2_5;

    integer errors;

    mux2 #(32) dut_mux2_32(
        .a(a32),
        .b(b32),
        .sel(sel2),
        .y(y2_32)
    );

    mux3 #(32) dut_mux3_32(
        .a(a32),
        .b(b32),
        .c(c32),
        .sel(sel3),
        .y(y3_32)
    );

    mux2 #(5) dut_mux2_5(
        .a(a5),
        .b(b5),
        .sel(sel5),
        .y(y2_5)
    );

    task check32;
        input [31:0] actual;
        input [31:0] expected;
        input [8*48-1:0] test_name;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s actual=%h expected=%h", test_name, actual, expected);
            end else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    task check5;
        input [4:0] actual;
        input [4:0] expected;
        input [8*48-1:0] test_name;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s actual=%b expected=%b", test_name, actual, expected);
            end else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin
        errors = 0;
        a32 = 32'h1234_5678;
        b32 = 32'h89ab_cdef;
        c32 = 32'h0f0f_f0f0;

        sel2 = 1'b0;
        #1 check32(y2_32, a32, "mux2 width32 sel=0");
        sel2 = 1'b1;
        #1 check32(y2_32, b32, "mux2 width32 sel=1");

        sel3 = 2'b00;
        #1 check32(y3_32, a32, "mux3 sel=00");
        sel3 = 2'b01;
        #1 check32(y3_32, b32, "mux3 sel=01");
        sel3 = 2'b10;
        #1 check32(y3_32, c32, "mux3 sel=10");
        sel3 = 2'b11;
        #1 check32(y3_32, a32, "mux3 reserved sel=11 falls back to a");

        a5 = 5'b00101;
        b5 = 5'b11010;
        sel5 = 1'b0;
        #1 check5(y2_5, a5, "mux2 width5 sel=0");
        sel5 = 1'b1;
        #1 check5(y2_5, b5, "mux2 width5 sel=1");

        if (errors == 0) begin
            $display("MUX_TB_PASS");
            $finish;
        end else begin
            $fatal(1, "MUX_TB_FAIL: %0d errors", errors);
        end
    end

endmodule

