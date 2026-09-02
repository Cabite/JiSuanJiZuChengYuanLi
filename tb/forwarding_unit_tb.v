`timescale 1ns / 1ps

module forwarding_unit_tb;

    reg  [4:0] rs_e;
    reg  [4:0] rt_e;
    reg  [4:0] dest_m;
    reg  [4:0] dest_w;
    reg        reg_write_m;
    reg        reg_write_w;
    reg        result_ready_m;
    reg        valid_m;
    reg        valid_w;
    wire [1:0] forward_a;
    wire [1:0] forward_b;
    wire [1:0] forward_store;
    integer errors;

    forwarding_unit dut(
        .rs_e(rs_e), .rt_e(rt_e), .dest_m(dest_m), .dest_w(dest_w),
        .reg_write_m(reg_write_m), .reg_write_w(reg_write_w),
        .result_ready_m(result_ready_m), .valid_m(valid_m),
        .valid_w(valid_w), .forward_a(forward_a), .forward_b(forward_b),
        .forward_store(forward_store)
    );

    task run_case;
        input [4:0] in_rs_e;
        input [4:0] in_rt_e;
        input [4:0] in_dest_m;
        input [4:0] in_dest_w;
        input in_reg_write_m;
        input in_reg_write_w;
        input in_result_ready_m;
        input in_valid_m;
        input in_valid_w;
        input [1:0] expected_a;
        input [1:0] expected_b;
        input [1:0] expected_store;
        input [8*56-1:0] test_name;
        begin
            rs_e = in_rs_e;
            rt_e = in_rt_e;
            dest_m = in_dest_m;
            dest_w = in_dest_w;
            reg_write_m = in_reg_write_m;
            reg_write_w = in_reg_write_w;
            result_ready_m = in_result_ready_m;
            valid_m = in_valid_m;
            valid_w = in_valid_w;
            #1;

            if ((forward_a !== expected_a) ||
                (forward_b !== expected_b) ||
                (forward_store !== expected_store)) begin
                errors = errors + 1;
                $display("FAIL: %0s actual=%b/%b/%b expected=%b/%b/%b",
                         test_name, forward_a, forward_b, forward_store,
                         expected_a, expected_b, expected_store);
            end else begin
                $display("PASS: %0s = %b/%b/%b",
                         test_name, forward_a, forward_b, forward_store);
            end
        end
    endtask

    initial begin
        errors = 0;

        run_case(5'd1, 5'd2, 5'd3, 5'd4, 0, 0, 1, 1, 1,
                 2'b00, 2'b00, 2'b00, "no producer means no forwarding");

        run_case(5'd3, 5'd2, 5'd3, 5'd4, 1, 1, 1, 1, 1,
                 2'b10, 2'b00, 2'b00, "immediately previous ALU result forwards to A");

        run_case(5'd1, 5'd4, 5'd3, 5'd4, 1, 1, 1, 1, 1,
                 2'b00, 2'b01, 2'b01, "MEM/WB result forwards to rt and store");

        run_case(5'd5, 5'd2, 5'd5, 5'd5, 1, 1, 1, 1, 1,
                 2'b10, 2'b00, 2'b00, "EX/MEM wins simultaneous M and W match");

        run_case(5'd1, 5'd6, 5'd6, 5'd4, 1, 1, 1, 1, 1,
                 2'b00, 2'b10, 2'b10, "ALU result forwards immediately to store data");

        run_case(5'd0, 5'd0, 5'd0, 5'd0, 1, 1, 1, 1, 1,
                 2'b00, 2'b00, 2'b00, "destination register zero never forwards");

        run_case(5'd7, 5'd2, 5'd7, 5'd7, 1, 1, 0, 1, 1,
                 2'b01, 2'b00, 2'b00, "load address in M is blocked and W value is used");

        run_case(5'd8, 5'd9, 5'd8, 5'd9, 1, 1, 1, 0, 0,
                 2'b00, 2'b00, 2'b00, "invalid producer stages never forward");

        if (errors == 0) begin
            $display("FORWARDING_UNIT_TB_PASS");
            $finish;
        end else begin
            $fatal(1, "FORWARDING_UNIT_TB_FAIL: %0d errors", errors);
        end
    end

endmodule
