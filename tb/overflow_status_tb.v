`timescale 1ns / 1ps

module overflow_status_tb;
    reg clk;
    reg reset;
    reg set_overflow;
    reg clear_overflow;
    wire status;
    integer errors;

    overflow_status dut(
        .clk(clk), .reset(reset), .set_overflow(set_overflow),
        .clear_overflow(clear_overflow), .overflow_status(status)
    );

    always #5 clk = ~clk;

    task check;
        input expected;
        input [8*52-1:0] test_name;
        begin
            #1;
            if (status !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s actual=%b expected=%b",
                         test_name, status, expected);
            end else
                $display("PASS: %0s = %b", test_name, status);
        end
    endtask

    initial begin
        clk = 0; reset = 1; set_overflow = 0; clear_overflow = 0;
        errors = 0;

        @(posedge clk); check(0, "reset clears status");
        @(negedge clk); reset = 0; set_overflow = 1;
        @(posedge clk); check(1, "overflow sets sticky status");
        @(negedge clk); set_overflow = 0;
        repeat (2) @(posedge clk);
        check(1, "status holds without another event");

        @(negedge clk); clear_overflow = 1; set_overflow = 1;
        @(posedge clk); check(0, "explicit clear has priority over set");
        @(negedge clk); clear_overflow = 0; set_overflow = 1;
        @(posedge clk); check(1, "status can be set again after clear");
        @(negedge clk); reset = 1; clear_overflow = 1;
        @(posedge clk); check(0, "reset has highest priority");

        if (errors == 0) begin
            $display("OVERFLOW_STATUS_TB_PASS");
            $finish;
        end else
            $fatal(1, "OVERFLOW_STATUS_TB_FAIL: %0d errors", errors);
    end
endmodule
