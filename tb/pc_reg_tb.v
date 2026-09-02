`timescale 1ns / 1ps

module pc_reg_tb;

    reg         clk;
    reg         reset;
    reg         enable;
    reg  [31:0] next_pc;
    wire [31:0] pc;
    integer errors;

    pc_reg #(
        .RESET_PC(32'h0000_0000)
    ) dut(
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .next_pc(next_pc),
        .pc(pc)
    );

    always #5 clk = ~clk;

    task check_pc;
        input [31:0] expected;
        input [8*48-1:0] test_name;
        begin
            if (pc !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s pc=%h expected=%h", test_name, pc, expected);
            end else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        enable = 1'b0;
        next_pc = 32'h1234_5678;
        errors = 0;

        @(posedge clk);
        #1 check_pc(32'h0000_0000, "synchronous reset");

        @(negedge clk);
        reset = 1'b0;
        enable = 1'b1;
        next_pc = 32'h0000_0004;
        @(posedge clk);
        #1 check_pc(32'h0000_0004, "enabled update");

        @(negedge clk);
        enable = 1'b0;
        next_pc = 32'h0000_0100;
        @(posedge clk);
        #1 check_pc(32'h0000_0004, "hold when enable is zero");

        @(negedge clk);
        enable = 1'b1;
        next_pc = 32'h0000_0008;
        @(posedge clk);
        #1 check_pc(32'h0000_0008, "second enabled update");

        @(negedge clk);
        reset = 1'b1;
        enable = 1'b1;
        next_pc = 32'hffff_ffff;
        @(posedge clk);
        #1 check_pc(32'h0000_0000, "reset has priority over enable");

        if (errors == 0) begin
            $display("PC_REG_TB_PASS");
            $finish;
        end else begin
            $fatal(1, "PC_REG_TB_FAIL: %0d errors", errors);
        end
    end

endmodule

