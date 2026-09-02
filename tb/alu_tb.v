`timescale 1ns / 1ps

module alu_tb;

    localparam ALU_ADD  = 5'b00000;
    localparam ALU_SUB  = 5'b00001;
    localparam ALU_AND  = 5'b00010;
    localparam ALU_OR   = 5'b00011;
    localparam ALU_XOR  = 5'b00100;
    localparam ALU_NOR  = 5'b00101;
    localparam ALU_SLT  = 5'b00110;
    localparam ALU_SLTU = 5'b00111;
    localparam ALU_SLL  = 5'b01000;
    localparam ALU_SRL  = 5'b01001;
    localparam ALU_SRA  = 5'b01010;

    reg  [31:0] a;
    reg  [31:0] b;
    reg  [4:0]  shamt;
    reg  [4:0]  alu_control;
    reg         check_overflow;
    wire [31:0] result;
    wire        zero;
    wire        overflow;
    integer errors;

    alu dut(
        .a(a),
        .b(b),
        .shamt(shamt),
        .alu_control(alu_control),
        .check_overflow(check_overflow),
        .result(result),
        .zero(zero),
        .overflow(overflow)
    );

    task run_case;
        input [4:0] op;
        input [31:0] in_a;
        input [31:0] in_b;
        input [4:0] in_shamt;
        input in_check_overflow;
        input [31:0] expected_result;
        input expected_overflow;
        input [8*48-1:0] test_name;
        reg expected_zero;
        begin
            alu_control = op;
            a = in_a;
            b = in_b;
            shamt = in_shamt;
            check_overflow = in_check_overflow;
            expected_zero = (expected_result == 32'b0);
            #1;

            if ((result !== expected_result) ||
                (overflow !== expected_overflow) ||
                (zero !== expected_zero)) begin
                errors = errors + 1;
                $display("FAIL: %0s", test_name);
                $display("  result=%h expected=%h", result, expected_result);
                $display("  overflow=%b expected=%b", overflow, expected_overflow);
                $display("  zero=%b expected=%b", zero, expected_zero);
            end else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin
        errors = 0;
        a = 0;
        b = 0;
        shamt = 0;
        alu_control = 0;
        check_overflow = 0;

        run_case(ALU_ADD, 32'd7, 32'd5, 0, 1, 32'd12, 0, "signed add normal");
        run_case(ALU_ADD, 32'hffff_ffff, 32'd1, 0, 0, 32'd0, 0,
                 "unsigned-style add wraps without overflow check");
        run_case(ALU_ADD, 32'h7fff_ffff, 32'd1, 0, 1, 32'h8000_0000, 1,
                 "positive add overflow");
        run_case(ALU_ADD, 32'h8000_0000, 32'hffff_ffff, 0, 1, 32'h7fff_ffff, 1,
                 "negative add overflow");

        run_case(ALU_SUB, 32'd7, 32'd5, 0, 1, 32'd2, 0, "signed sub normal");
        run_case(ALU_SUB, 32'h8000_0000, 32'd1, 0, 1, 32'h7fff_ffff, 1,
                 "negative sub overflow");
        run_case(ALU_SUB, 32'd5, 32'd5, 0, 1, 32'd0, 0, "sub produces zero");

        run_case(ALU_AND, 32'hf0f0_55aa, 32'h0ff0_0f0f, 0, 0,
                 32'h00f0_050a, 0, "bitwise and");
        run_case(ALU_OR, 32'hf000_00aa, 32'h0f00_5500, 0, 0,
                 32'hff00_55aa, 0, "bitwise or");
        run_case(ALU_XOR, 32'hffff_0000, 32'h0f0f_0f0f, 0, 0,
                 32'hf0f0_0f0f, 0, "bitwise xor");
        run_case(ALU_NOR, 32'hffff_0000, 32'h0000_ffff, 0, 0,
                 32'h0000_0000, 0, "bitwise nor");

        run_case(ALU_SLT, 32'hffff_ffff, 32'd1, 0, 0, 32'd1, 0,
                 "signed less-than negative vs positive");
        run_case(ALU_SLT, 32'd5, 32'hffff_ffff, 0, 0, 32'd0, 0,
                 "signed less-than positive vs negative");
        run_case(ALU_SLTU, 32'hffff_ffff, 32'd1, 0, 0, 32'd0, 0,
                 "unsigned less-than large vs small");
        run_case(ALU_SLTU, 32'd1, 32'hffff_ffff, 0, 0, 32'd1, 0,
                 "unsigned less-than small vs large");

        run_case(ALU_SLL, 0, 32'h0000_0001, 5'd4, 0, 32'h0000_0010, 0,
                 "logical left shift");
        run_case(ALU_SRL, 0, 32'h8000_0000, 5'd4, 0, 32'h0800_0000, 0,
                 "logical right shift");
        run_case(ALU_SRA, 0, 32'h8000_0000, 5'd4, 0, 32'hf800_0000, 0,
                 "arithmetic right shift");

        run_case(5'b11111, 32'h1234_5678, 32'h8765_4321, 0, 0,
                 32'h0000_0000, 0, "unknown operation safe default");

        if (errors == 0) begin
            $display("ALU_TB_PASS");
            $finish;
        end else begin
            $fatal(1, "ALU_TB_FAIL: %0d errors", errors);
        end
    end

endmodule

