`timescale 1ns / 1ps

module hazard_unit_tb;

    reg reset;
    reg mem_wait;
    reg redirect_e;
    reg jump_direct_d;
    reg mem_read_e;
    reg [4:0] dest_e;
    reg [4:0] rs_d;
    reg [4:0] rt_d;
    reg uses_rs_d;
    reg uses_rt_d;
    reg valid_d;
    reg valid_e;

    wire load_use_stall;
    wire pc_enable;
    wire if_id_enable;
    wire id_ex_enable;
    wire ex_mem_enable;
    wire mem_wb_enable;
    wire if_id_flush;
    wire id_ex_flush;
    wire global_advance;

    integer errors;

    hazard_unit dut(
        .reset(reset), .mem_wait(mem_wait), .redirect_e(redirect_e),
        .jump_direct_d(jump_direct_d), .mem_read_e(mem_read_e),
        .dest_e(dest_e), .rs_d(rs_d), .rt_d(rt_d),
        .uses_rs_d(uses_rs_d), .uses_rt_d(uses_rt_d),
        .valid_d(valid_d), .valid_e(valid_e),
        .load_use_stall(load_use_stall), .pc_enable(pc_enable),
        .if_id_enable(if_id_enable), .id_ex_enable(id_ex_enable),
        .ex_mem_enable(ex_mem_enable), .mem_wb_enable(mem_wb_enable),
        .if_id_flush(if_id_flush), .id_ex_flush(id_ex_flush),
        .global_advance(global_advance)
    );

    task defaults;
        begin
            reset         = 1'b0;
            mem_wait      = 1'b0;
            redirect_e    = 1'b0;
            jump_direct_d = 1'b0;
            mem_read_e    = 1'b0;
            dest_e        = 5'd0;
            rs_d          = 5'd0;
            rt_d          = 5'd0;
            uses_rs_d     = 1'b0;
            uses_rt_d     = 1'b0;
            valid_d       = 1'b1;
            valid_e       = 1'b1;
        end
    endtask

    task check_outputs;
        input expected_stall;
        input expected_pc_en;
        input expected_ifid_en;
        input expected_idex_en;
        input expected_exmem_en;
        input expected_memwb_en;
        input expected_ifid_flush;
        input expected_idex_flush;
        input expected_advance;
        input [8*56-1:0] test_name;
        begin
            #1;
            if ({load_use_stall, pc_enable, if_id_enable, id_ex_enable,
                 ex_mem_enable, mem_wb_enable, if_id_flush, id_ex_flush,
                 global_advance} !==
                {expected_stall, expected_pc_en, expected_ifid_en,
                 expected_idex_en, expected_exmem_en, expected_memwb_en,
                 expected_ifid_flush, expected_idex_flush,
                 expected_advance}) begin
                errors = errors + 1;
                $display("FAIL: %0s outputs=%b%b%b%b%b%b%b%b%b expected=%b%b%b%b%b%b%b%b%b",
                    test_name, load_use_stall, pc_enable, if_id_enable,
                    id_ex_enable, ex_mem_enable, mem_wb_enable, if_id_flush,
                    id_ex_flush, global_advance, expected_stall,
                    expected_pc_en, expected_ifid_en, expected_idex_en,
                    expected_exmem_en, expected_memwb_en, expected_ifid_flush,
                    expected_idex_flush, expected_advance);
            end else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin
        errors = 0;

        defaults();
        check_outputs(0,1,1,1,1,1,0,0,1, "normal pipeline advance");

        defaults();
        mem_read_e = 1; dest_e = 5; rs_d = 5; uses_rs_d = 1;
        check_outputs(1,0,0,1,1,1,0,1,1, "load-use through rs inserts one bubble");

        defaults();
        mem_read_e = 1; dest_e = 7; rt_d = 7; uses_rt_d = 1;
        check_outputs(1,0,0,1,1,1,0,1,1, "load-use through rt covers store data or branch");

        defaults();
        mem_read_e = 1; dest_e = 7; rt_d = 7; uses_rt_d = 0;
        check_outputs(0,1,1,1,1,1,0,0,1, "I-type destination rt is not a false source");

        defaults();
        mem_read_e = 1; dest_e = 0; rs_d = 0; uses_rs_d = 1;
        check_outputs(0,1,1,1,1,1,0,0,1, "load destination zero never stalls");

        defaults();
        mem_read_e = 1; dest_e = 3; rs_d = 3; uses_rs_d = 1; valid_d = 0;
        check_outputs(0,1,1,1,1,1,0,0,1, "invalid decode bubble never stalls");

        defaults();
        mem_read_e = 1; dest_e = 3; rs_d = 3; uses_rs_d = 1; valid_e = 0;
        check_outputs(0,1,1,1,1,1,0,0,1, "invalid execute bubble never stalls");

        defaults();
        // This models a branch, which genuinely reads both rs and rt.
        mem_read_e = 1; dest_e = 9; rt_d = 9;
        uses_rs_d = 1; uses_rt_d = 1;
        check_outputs(1,0,0,1,1,1,0,1,1, "load followed by branch operand stalls");

        defaults();
        redirect_e = 1;
        check_outputs(0,1,1,1,1,1,1,1,1, "EX redirect flushes younger stages");

        defaults();
        jump_direct_d = 1;
        check_outputs(0,1,1,1,1,1,1,0,1, "ID direct jump flushes fetched instruction");

        defaults();
        mem_wait = 1; redirect_e = 1; jump_direct_d = 1;
        mem_read_e = 1; dest_e = 2; rs_d = 2; uses_rs_d = 1;
        check_outputs(1,0,0,0,0,0,0,0,0, "memory wait has priority and freezes all stages");

        defaults();
        reset = 1;
        check_outputs(0,0,0,0,0,0,0,0,0, "reset gives deterministic disabled controls");

        if (errors == 0) begin
            $display("HAZARD_UNIT_TB_PASS");
            $finish;
        end else begin
            $fatal(1, "HAZARD_UNIT_TB_FAIL: %0d errors", errors);
        end
    end

endmodule
