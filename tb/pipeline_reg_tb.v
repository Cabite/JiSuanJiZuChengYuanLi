`timescale 1ns / 1ps

// Self-checking testbench for all four stage-3 pipeline registers.
module pipeline_reg_tb;

    reg clk;
    reg reset;
    reg enable;
    reg flush;
    integer errors;

    // IF/ID inputs and outputs.
    reg valid_f, pred_taken_f;
    reg [31:0] pc_f, pc_plus4_f, inst_f, pred_target_f;
    reg [5:0] pred_index_f;
    wire valid_d_if, pred_taken_d_if;
    wire [31:0] pc_d_if, pc_plus4_d_if, inst_d_if, pred_target_d_if;
    wire [5:0] pred_index_d_if;

    // ID/EX inputs and outputs.
    reg valid_d, alu_src_b_d, reg_write_d, mem_read_d, mem_write_d;
    reg branch_eq_d, branch_ne_d, jump_reg_d, check_overflow_d, pred_taken_d;
    reg [31:0] pc_d, pc_plus4_d, rs_value_d, rt_value_d;
    reg [31:0] imm_ext_d, branch_offset_d, lui_value_d, pred_target_d;
    reg [4:0] rs_d, rt_d, dest_d, shamt_d, alu_control_d;
    reg [1:0] result_src_d;
    reg [5:0] pred_index_d;
    wire valid_e, alu_src_b_e, reg_write_e, mem_read_e, mem_write_e;
    wire branch_eq_e, branch_ne_e, jump_reg_e, check_overflow_e, pred_taken_e;
    wire [31:0] pc_e, pc_plus4_e, rs_value_e, rt_value_e;
    wire [31:0] imm_ext_e, branch_offset_e, lui_value_e, pred_target_e;
    wire [4:0] rs_e, rt_e, dest_e, shamt_e, alu_control_e;
    wire [1:0] result_src_e;
    wire [5:0] pred_index_e;

    // EX/MEM inputs and outputs.
    reg valid_e_in, reg_write_e_in, mem_read_e_in, mem_write_e_in, overflow_e_in;
    reg [31:0] pc_e_in, pc_plus4_e_in, alu_result_e_in, store_data_e_in, lui_value_e_in;
    reg [4:0] dest_e_in;
    reg [1:0] result_src_e_in;
    wire valid_m, reg_write_m, mem_read_m, mem_write_m, overflow_m;
    wire [31:0] pc_m, pc_plus4_m, alu_result_m, store_data_m, lui_value_m;
    wire [4:0] dest_m;
    wire [1:0] result_src_m;

    // MEM/WB inputs and outputs.
    reg valid_m_in, reg_write_m_in, overflow_m_in;
    reg [31:0] pc_m_in, pc_plus4_m_in, alu_result_m_in, mem_rdata_m_in, lui_value_m_in;
    reg [4:0] dest_m_in;
    reg [1:0] result_src_m_in;
    wire valid_w, reg_write_w, overflow_w;
    wire [31:0] pc_w, pc_plus4_w, alu_result_w, mem_rdata_w, lui_value_w;
    wire [4:0] dest_w;
    wire [1:0] result_src_w;

    wire [135:0] if_id_actual = {
        valid_d_if, pc_d_if, pc_plus4_d_if, inst_d_if,
        pred_taken_d_if, pred_target_d_if, pred_index_d_if
    };
    wire [298:0] id_ex_actual = {
        valid_e, pc_e, pc_plus4_e, rs_value_e, rt_value_e,
        rs_e, rt_e, dest_e, imm_ext_e, branch_offset_e, lui_value_e,
        shamt_e, alu_src_b_e, alu_control_e, reg_write_e, mem_read_e,
        mem_write_e, result_src_e, branch_eq_e, branch_ne_e, jump_reg_e,
        check_overflow_e, pred_taken_e, pred_target_e, pred_index_e
    };
    wire [171:0] ex_mem_actual = {
        valid_m, pc_m, pc_plus4_m, alu_result_m, store_data_m,
        lui_value_m, dest_m, reg_write_m, mem_read_m, mem_write_m,
        result_src_m, overflow_m
    };
    wire [169:0] mem_wb_actual = {
        valid_w, pc_w, pc_plus4_w, alu_result_w, mem_rdata_w,
        lui_value_w, dest_w, reg_write_w, result_src_w, overflow_w
    };

    wire [135:0] if_id_input = {
        valid_f, pc_f, pc_plus4_f, inst_f,
        pred_taken_f, pred_target_f, pred_index_f
    };
    wire [298:0] id_ex_input = {
        valid_d, pc_d, pc_plus4_d, rs_value_d, rt_value_d,
        rs_d, rt_d, dest_d, imm_ext_d, branch_offset_d, lui_value_d,
        shamt_d, alu_src_b_d, alu_control_d, reg_write_d, mem_read_d,
        mem_write_d, result_src_d, branch_eq_d, branch_ne_d, jump_reg_d,
        check_overflow_d, pred_taken_d, pred_target_d, pred_index_d
    };
    wire [171:0] ex_mem_input = {
        valid_e_in, pc_e_in, pc_plus4_e_in, alu_result_e_in, store_data_e_in,
        lui_value_e_in, dest_e_in, reg_write_e_in, mem_read_e_in,
        mem_write_e_in, result_src_e_in, overflow_e_in
    };
    wire [169:0] mem_wb_input = {
        valid_m_in, pc_m_in, pc_plus4_m_in, alu_result_m_in, mem_rdata_m_in,
        lui_value_m_in, dest_m_in, reg_write_m_in, result_src_m_in,
        overflow_m_in
    };

    if_id_reg dut_if_id(
        .clk(clk), .reset(reset), .enable(enable), .flush(flush),
        .valid_f(valid_f), .pc_f(pc_f), .pc_plus4_f(pc_plus4_f),
        .inst_f(inst_f), .pred_taken_f(pred_taken_f),
        .pred_target_f(pred_target_f), .pred_index_f(pred_index_f),
        .valid_d(valid_d_if), .pc_d(pc_d_if), .pc_plus4_d(pc_plus4_d_if),
        .inst_d(inst_d_if), .pred_taken_d(pred_taken_d_if),
        .pred_target_d(pred_target_d_if), .pred_index_d(pred_index_d_if)
    );

    id_ex_reg dut_id_ex(
        .clk(clk), .reset(reset), .enable(enable), .flush(flush),
        .valid_d(valid_d), .pc_d(pc_d), .pc_plus4_d(pc_plus4_d),
        .rs_value_d(rs_value_d), .rt_value_d(rt_value_d), .rs_d(rs_d),
        .rt_d(rt_d), .dest_d(dest_d), .imm_ext_d(imm_ext_d),
        .branch_offset_d(branch_offset_d), .lui_value_d(lui_value_d),
        .shamt_d(shamt_d), .alu_src_b_d(alu_src_b_d),
        .alu_control_d(alu_control_d), .reg_write_d(reg_write_d),
        .mem_read_d(mem_read_d), .mem_write_d(mem_write_d),
        .result_src_d(result_src_d), .branch_eq_d(branch_eq_d),
        .branch_ne_d(branch_ne_d), .jump_reg_d(jump_reg_d),
        .check_overflow_d(check_overflow_d), .pred_taken_d(pred_taken_d),
        .pred_target_d(pred_target_d), .pred_index_d(pred_index_d),
        .valid_e(valid_e), .pc_e(pc_e), .pc_plus4_e(pc_plus4_e),
        .rs_value_e(rs_value_e), .rt_value_e(rt_value_e), .rs_e(rs_e),
        .rt_e(rt_e), .dest_e(dest_e), .imm_ext_e(imm_ext_e),
        .branch_offset_e(branch_offset_e), .lui_value_e(lui_value_e),
        .shamt_e(shamt_e), .alu_src_b_e(alu_src_b_e),
        .alu_control_e(alu_control_e), .reg_write_e(reg_write_e),
        .mem_read_e(mem_read_e), .mem_write_e(mem_write_e),
        .result_src_e(result_src_e), .branch_eq_e(branch_eq_e),
        .branch_ne_e(branch_ne_e), .jump_reg_e(jump_reg_e),
        .check_overflow_e(check_overflow_e), .pred_taken_e(pred_taken_e),
        .pred_target_e(pred_target_e), .pred_index_e(pred_index_e)
    );

    ex_mem_reg dut_ex_mem(
        .clk(clk), .reset(reset), .enable(enable), .flush(flush),
        .valid_e(valid_e_in), .pc_e(pc_e_in), .pc_plus4_e(pc_plus4_e_in),
        .alu_result_e(alu_result_e_in), .store_data_e(store_data_e_in),
        .lui_value_e(lui_value_e_in), .dest_e(dest_e_in),
        .reg_write_e(reg_write_e_in), .mem_read_e(mem_read_e_in),
        .mem_write_e(mem_write_e_in), .result_src_e(result_src_e_in),
        .overflow_e(overflow_e_in), .valid_m(valid_m), .pc_m(pc_m),
        .pc_plus4_m(pc_plus4_m), .alu_result_m(alu_result_m),
        .store_data_m(store_data_m), .lui_value_m(lui_value_m),
        .dest_m(dest_m), .reg_write_m(reg_write_m), .mem_read_m(mem_read_m),
        .mem_write_m(mem_write_m), .result_src_m(result_src_m),
        .overflow_m(overflow_m)
    );

    mem_wb_reg dut_mem_wb(
        .clk(clk), .reset(reset), .enable(enable), .flush(flush),
        .valid_m(valid_m_in), .pc_m(pc_m_in), .pc_plus4_m(pc_plus4_m_in),
        .alu_result_m(alu_result_m_in), .mem_rdata_m(mem_rdata_m_in),
        .lui_value_m(lui_value_m_in), .dest_m(dest_m_in),
        .reg_write_m(reg_write_m_in), .result_src_m(result_src_m_in),
        .overflow_m(overflow_m_in), .valid_w(valid_w), .pc_w(pc_w),
        .pc_plus4_w(pc_plus4_w), .alu_result_w(alu_result_w),
        .mem_rdata_w(mem_rdata_w), .lui_value_w(lui_value_w),
        .dest_w(dest_w), .reg_write_w(reg_write_w),
        .result_src_w(result_src_w), .overflow_w(overflow_w)
    );

    always #5 clk = ~clk;

    task check_all;
        input [135:0] expected_if_id;
        input [298:0] expected_id_ex;
        input [171:0] expected_ex_mem;
        input [169:0] expected_mem_wb;
        input [8*40-1:0] test_name;
        begin
            if ((if_id_actual !== expected_if_id) ||
                (id_ex_actual !== expected_id_ex) ||
                (ex_mem_actual !== expected_ex_mem) ||
                (mem_wb_actual !== expected_mem_wb)) begin
                errors = errors + 1;
                $display("FAIL: %0s", test_name);
                if (if_id_actual !== expected_if_id) $display("  IF/ID mismatch");
                if (id_ex_actual !== expected_id_ex) $display("  ID/EX mismatch");
                if (ex_mem_actual !== expected_ex_mem) $display("  EX/MEM mismatch");
                if (mem_wb_actual !== expected_mem_wb) $display("  MEM/WB mismatch");
            end else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    task set_pattern_a;
        begin
            valid_f = 1; pc_f = 32'h0000_0100; pc_plus4_f = 32'h0000_0104;
            inst_f = 32'h2402_0004; pred_taken_f = 1; pred_target_f = 32'h0000_0200; pred_index_f = 6'h15;

            valid_d = 1; pc_d = 32'h1111_0000; pc_plus4_d = 32'h1111_0004;
            rs_value_d = 32'hAAAA_0001; rt_value_d = 32'hBBBB_0002;
            rs_d = 5'd3; rt_d = 5'd4; dest_d = 5'd5; imm_ext_d = 32'hFFFF_FFF8;
            branch_offset_d = 32'hFFFF_FFE0; lui_value_d = 32'h1234_0000;
            shamt_d = 5'd7; alu_src_b_d = 1; alu_control_d = 5'h0A;
            reg_write_d = 1; mem_read_d = 1; mem_write_d = 0; result_src_d = 2'b01;
            branch_eq_d = 1; branch_ne_d = 0; jump_reg_d = 1; check_overflow_d = 1;
            pred_taken_d = 1; pred_target_d = 32'h2222_0000; pred_index_d = 6'h2A;

            valid_e_in = 1; pc_e_in = 32'h3333_0000; pc_plus4_e_in = 32'h3333_0004;
            alu_result_e_in = 32'hDEAD_BEEF; store_data_e_in = 32'hCAFE_BABE;
            lui_value_e_in = 32'h5678_0000; dest_e_in = 5'd9; reg_write_e_in = 1;
            mem_read_e_in = 0; mem_write_e_in = 1; result_src_e_in = 2'b10; overflow_e_in = 1;

            valid_m_in = 1; pc_m_in = 32'h4444_0000; pc_plus4_m_in = 32'h4444_0004;
            alu_result_m_in = 32'h0102_0304; mem_rdata_m_in = 32'hA0B0_C0D0;
            lui_value_m_in = 32'h9ABC_0000; dest_m_in = 5'd12; reg_write_m_in = 1;
            result_src_m_in = 2'b11; overflow_m_in = 1;
        end
    endtask

    task set_pattern_b;
        begin
            valid_f = 1; pc_f = 32'h8000_0000; pc_plus4_f = 32'h8000_0004;
            inst_f = 32'h3C03_1234; pred_taken_f = 0; pred_target_f = 32'h0000_0000; pred_index_f = 6'h3F;

            valid_d = 1; pc_d = 32'h5555_0000; pc_plus4_d = 32'h5555_0004;
            rs_value_d = 32'h0000_000A; rt_value_d = 32'h0000_0014;
            rs_d = 5'd10; rt_d = 5'd11; dest_d = 5'd12; imm_ext_d = 32'h0000_0020;
            branch_offset_d = 32'h0000_0080; lui_value_d = 32'hABCD_0000;
            shamt_d = 5'd2; alu_src_b_d = 0; alu_control_d = 5'h03;
            reg_write_d = 0; mem_read_d = 0; mem_write_d = 1; result_src_d = 2'b10;
            branch_eq_d = 0; branch_ne_d = 1; jump_reg_d = 0; check_overflow_d = 0;
            pred_taken_d = 0; pred_target_d = 32'h6666_0000; pred_index_d = 6'h11;

            valid_e_in = 1; pc_e_in = 32'h7777_0000; pc_plus4_e_in = 32'h7777_0004;
            alu_result_e_in = 32'h1111_2222; store_data_e_in = 32'h3333_4444;
            lui_value_e_in = 32'h5555_0000; dest_e_in = 5'd20; reg_write_e_in = 0;
            mem_read_e_in = 1; mem_write_e_in = 0; result_src_e_in = 2'b01; overflow_e_in = 0;

            valid_m_in = 1; pc_m_in = 32'h8888_0000; pc_plus4_m_in = 32'h8888_0004;
            alu_result_m_in = 32'h9999_AAAA; mem_rdata_m_in = 32'hBBBB_CCCC;
            lui_value_m_in = 32'hDDDD_0000; dest_m_in = 5'd21; reg_write_m_in = 0;
            result_src_m_in = 2'b01; overflow_m_in = 0;
        end
    endtask

    reg [135:0] saved_if_id;
    reg [298:0] saved_id_ex;
    reg [171:0] saved_ex_mem;
    reg [169:0] saved_mem_wb;

    initial begin
        clk = 0;
        reset = 1;
        enable = 1;
        flush = 1;
        errors = 0;
        set_pattern_a;

        // reset must dominate simultaneous flush and enable.
        @(posedge clk); #1;
        check_all(136'b0, 299'b0, 172'b0, 170'b0, "reset clears every field");

        // A normal enabled edge transfers every input field.
        @(negedge clk); reset = 0; flush = 0; enable = 1;
        @(posedge clk); #1;
        check_all(if_id_input, id_ex_input, ex_mem_input, mem_wb_input,
                  "enable transfers every field");
        saved_if_id = if_id_actual;
        saved_id_ex = id_ex_actual;
        saved_ex_mem = ex_mem_actual;
        saved_mem_wb = mem_wb_actual;

        // Disable and change all inputs: outputs must keep pattern A.
        @(negedge clk); enable = 0; set_pattern_b;
        @(posedge clk); #1;
        check_all(saved_if_id, saved_id_ex, saved_ex_mem, saved_mem_wb,
                  "enable zero holds every field");

        // flush must dominate enable=0 and create a side-effect-free bubble.
        @(negedge clk); flush = 1; enable = 0;
        @(posedge clk); #1;
        check_all(136'b0, 299'b0, 172'b0, 170'b0,
                  "flush dominates hold and clears bubble");

        // Reload pattern B after the flush.
        @(negedge clk); flush = 0; enable = 1;
        @(posedge clk); #1;
        check_all(if_id_input, id_ex_input, ex_mem_input, mem_wb_input,
                  "pipeline reloads after flush");

        // flush must also dominate enable=1.
        @(negedge clk); flush = 1; enable = 1; set_pattern_a;
        @(posedge clk); #1;
        check_all(136'b0, 299'b0, 172'b0, 170'b0,
                  "flush dominates enabled transfer");

        if (errors == 0) begin
            $display("PIPELINE_REG_TB_PASS");
            $finish;
        end else begin
            $fatal(1, "PIPELINE_REG_TB_FAIL: %0d errors", errors);
        end
    end

endmodule
