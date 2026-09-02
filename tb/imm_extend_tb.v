`timescale 1ns / 1ps

module imm_extend_tb;

    localparam IMM_SIGN  = 2'b00;
    localparam IMM_ZERO  = 2'b01;
    localparam IMM_UPPER = 2'b10;

    reg  [15:0] imm16;
    reg  [1:0]  imm_mode;
    wire [31:0] imm_ext;
    wire [31:0] lui_value;
    wire [31:0] branch_offset;
    integer errors;

    imm_extend dut(
        .imm16(imm16),
        .imm_mode(imm_mode),
        .imm_ext(imm_ext),
        .lui_value(lui_value),
        .branch_offset(branch_offset)
    );

    task check_outputs;
        input [31:0] expected_ext;
        input [31:0] expected_lui;
        input [31:0] expected_branch;
        input [8*48-1:0] test_name;
        begin
            if ((imm_ext !== expected_ext) ||
                (lui_value !== expected_lui) ||
                (branch_offset !== expected_branch)) begin
                errors = errors + 1;
                $display("FAIL: %0s", test_name);
                $display("  imm_ext=%h expected=%h", imm_ext, expected_ext);
                $display("  lui=%h expected=%h", lui_value, expected_lui);
                $display("  branch=%h expected=%h", branch_offset, expected_branch);
            end else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin
        errors = 0;

        imm16 = 16'h0001;
        imm_mode = IMM_SIGN;
        #1 check_outputs(32'h0000_0001, 32'h0001_0000, 32'h0000_0004,
                         "positive sign extension");

        imm16 = 16'h7fff;
        imm_mode = IMM_SIGN;
        #1 check_outputs(32'h0000_7fff, 32'h7fff_0000, 32'h0001_fffc,
                         "largest positive immediate");

        imm16 = 16'h8000;
        imm_mode = IMM_SIGN;
        #1 check_outputs(32'hffff_8000, 32'h8000_0000, 32'hfffe_0000,
                         "negative sign extension");

        imm16 = 16'hffff;
        imm_mode = IMM_ZERO;
        #1 check_outputs(32'h0000_ffff, 32'hffff_0000, 32'hffff_fffc,
                         "zero extension and negative branch offset");

        imm16 = 16'h1234;
        imm_mode = IMM_UPPER;
        #1 check_outputs(32'h1234_0000, 32'h1234_0000, 32'h0000_48d0,
                         "upper immediate mode");

        imm16 = 16'habcd;
        imm_mode = 2'b11;
        #1 check_outputs(32'h0000_0000, 32'habcd_0000, 32'hfffe_af34,
                         "reserved mode has safe default");

        if (errors == 0) begin
            $display("IMM_EXTEND_TB_PASS");
            $finish;
        end else begin
            $fatal(1, "IMM_EXTEND_TB_FAIL: %0d errors", errors);
        end
    end

endmodule

