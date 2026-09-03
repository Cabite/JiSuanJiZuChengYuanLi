`timescale 1ns / 1ps
`include "cpu_defs.vh"

// Minimum five-stage CPU core.
// Supported instructions: add, addu, sub, subu, and, or, addi, addiu, lui,
// lw, sw, beq, bne, j, jal and jr.  Control transfers have no delay slot.
module cpu_core #(
    parameter RESET_PC = 32'h0000_0000,
    parameter PRED_MODE = 0
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        count_enable,
    input  wire        clear_overflow,

    output wire [31:0] imem_addr,
    input  wire [31:0] imem_rdata,

    output wire        dmem_valid,
    output wire        dmem_write,
    output wire [3:0]  dmem_wstrb,
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    input  wire [31:0] dmem_rdata,
    input  wire        dmem_ready,

    output wire        overflow_status,
    output wire [63:0] cycle_count,
    output wire [63:0] retired_count,
    output wire [63:0] branch_count,
    output wire [63:0] mispredict_count,
    output wire [63:0] load_stall_count,
    output wire [63:0] mem_wait_count,
    output wire [63:0] flush_count,

    // Observation-only ports: values apply at the upcoming rising edge.
    output wire        debug_write_enable,
    output wire [4:0]  debug_write_addr,
    output wire [31:0] debug_write_data,
    output wire        debug_retire,
    output wire [31:0] debug_wb_pc
);

    // Centralized pipeline-control signals.
    wire mem_wait;
    wire load_use_stall;
    wire pc_enable;
    wire if_id_enable;
    wire id_ex_enable;
    wire ex_mem_enable;
    wire mem_wb_enable;
    wire if_id_flush;
    wire id_ex_flush;
    wire global_advance;
    wire retire_fire;
    wire set_overflow;
    wire branch_resolved_event;
    wire mispredict_event;
    wire effective_load_stall;
    wire [1:0] flushed_valid_count;

    // IF stage.
    wire [31:0] pc_f;
    wire [31:0] pc_plus4_f;
    wire [31:0] next_pc_f;
    wire        pred_taken_f;
    wire [31:0] pred_target_f;
    wire [5:0]  pred_index_f;
    wire        btb_hit_f;

    // IF/ID outputs.
    wire        valid_d;
    wire [31:0] pc_d;
    wire [31:0] pc_plus4_d;
    wire [31:0] inst_d;
    wire        pred_taken_d;
    wire [31:0] pred_target_d;
    wire [5:0]  pred_index_d;

    // ID stage instruction fields and decoded controls.
    wire [5:0]  opcode_d;
    wire [5:0]  funct_d;
    wire [4:0]  rs_d;
    wire [4:0]  rt_d;
    wire [4:0]  rd_d;
    wire [4:0]  shamt_d;
    wire [15:0] imm16_d;
    wire [31:0] rs_value_d;
    wire [31:0] rt_value_d;
    wire [31:0] rs_decode_value_d;
    wire [31:0] rt_decode_value_d;
    wire [31:0] imm_ext_d;
    wire [31:0] lui_value_d;
    wire [31:0] branch_offset_d;
    wire        reg_write_d;
    wire [1:0]  dest_sel_d;
    wire        alu_src_b_d;
    wire [1:0]  imm_mode_d;
    wire [4:0]  alu_control_d;
    wire        mem_read_d;
    wire        mem_write_d;
    wire [1:0]  result_src_d;
    wire        branch_eq_d;
    wire        branch_ne_d;
    wire        jump_direct_d;
    wire        jump_link_d;
    wire        jump_reg_d;
    wire        check_overflow_d;
    wire        uses_rs_d;
    wire        uses_rt_d;
    wire        illegal_d;
    reg  [4:0]  dest_d;
    wire [31:0] jump_target_d;
    wire        jump_direct_event_d;

    // ID/EX outputs.
    wire        valid_e;
    wire [31:0] pc_e;
    wire [31:0] pc_plus4_e;
    wire [31:0] rs_value_e;
    wire [31:0] rt_value_e;
    wire [4:0]  rs_e;
    wire [4:0]  rt_e;
    wire [4:0]  dest_e;
    wire [31:0] imm_ext_e;
    wire [31:0] branch_offset_e;
    wire [31:0] lui_value_e;
    wire [4:0]  shamt_e;
    wire        alu_src_b_e;
    wire [4:0]  alu_control_e;
    wire        reg_write_e;
    wire        mem_read_e;
    wire        mem_write_e;
    wire [1:0]  result_src_e;
    wire        branch_eq_e;
    wire        branch_ne_e;
    wire        jump_reg_e;
    wire        check_overflow_e;
    wire        pred_taken_e;
    wire [31:0] pred_target_e;
    wire [5:0]  pred_index_e;

    // EX stage.
    wire [31:0] alu_b_e;
    wire [31:0] rs_forwarded_e;
    wire [31:0] rt_forwarded_e;
    wire [31:0] store_data_e;
    wire [31:0] alu_result_e;
    wire        alu_zero_e;
    wire        alu_overflow_e;
    wire        overflow_e;
    wire [1:0]  forward_a_e;
    wire [1:0]  forward_b_e;
    wire [1:0]  forward_store_e;
    wire        is_control_e;
    wire        is_cond_branch_e;
    wire        actual_taken_e;
    wire [31:0] actual_target_e;
    wire        mispredict_e;
    wire        redirect_e;
    wire [31:0] correct_pc_e;
    wire        branch_update_enable;

    // EX/MEM outputs.
    wire        valid_m;
    wire [31:0] pc_m;
    wire [31:0] pc_plus4_m;
    wire [31:0] alu_result_m;
    wire [31:0] store_data_m;
    wire [31:0] lui_value_m;
    wire [4:0]  dest_m;
    wire        reg_write_m;
    wire        mem_read_m;
    wire        mem_write_m;
    wire [1:0]  result_src_m;
    wire        overflow_m;
    reg  [31:0] forward_value_m;
    wire        result_ready_m;

    // MEM/WB outputs and WB stage.
    wire        valid_w;
    wire [31:0] pc_w;
    wire [31:0] pc_plus4_w;
    wire [31:0] alu_result_w;
    wire [31:0] mem_rdata_w;
    wire [31:0] lui_value_w;
    wire [4:0]  dest_w;
    wire        reg_write_w;
    wire [1:0]  result_src_w;
    wire        overflow_w;
    reg  [31:0] write_data_w;
    wire        write_enable_w;

    assign imem_addr = pc_f;
    assign debug_write_enable = write_enable_w;
    assign debug_write_addr = dest_w;
    assign debug_write_data = write_data_w;
    assign debug_retire = retire_fire;
    assign debug_wb_pc = pc_w;
    assign pc_plus4_f = pc_f + 32'd4;
    assign jump_target_d = {pc_plus4_d[31:28], inst_d[25:0], 2'b00};
    assign jump_direct_event_d = valid_d && !illegal_d && jump_direct_d;

    // Oldest control event wins.  Static prediction keeps pred_taken_f low;
    // the predictor inputs already make the PC path ready for stage 8.
    assign next_pc_f = redirect_e ? correct_pc_e :
                       jump_direct_event_d ? jump_target_d :
                       pred_taken_f ? pred_target_f : pc_plus4_f;

    assign dmem_valid = valid_m && !overflow_m &&
                        (mem_read_m || mem_write_m);
    assign dmem_write = dmem_valid && mem_write_m;
    assign dmem_wstrb = dmem_write ? 4'b1111 : 4'b0000;
    assign dmem_addr  = alu_result_m;
    assign dmem_wdata = store_data_m;

    assign mem_wait = dmem_valid && !dmem_ready;

    assign write_enable_w = global_advance && valid_w && reg_write_w &&
                            !overflow_w && (dest_w != 5'd0);

    assign opcode_d = inst_d[31:26];
    assign rs_d     = inst_d[25:21];
    assign rt_d     = inst_d[20:16];
    assign rd_d     = inst_d[15:11];
    assign shamt_d  = inst_d[10:6];
    assign funct_d  = inst_d[5:0];
    assign imm16_d  = inst_d[15:0];

    // WB-to-ID bypass handles a read in the same cycle that WB commits.
    assign rs_decode_value_d = (write_enable_w && (dest_w == rs_d) &&
                                (rs_d != 5'd0)) ? write_data_w : rs_value_d;
    assign rt_decode_value_d = (write_enable_w && (dest_w == rt_d) &&
                                (rt_d != 5'd0)) ? write_data_w : rt_value_d;

    assign alu_b_e = alu_src_b_e ? imm_ext_e : rt_forwarded_e;
    assign overflow_e = valid_e && alu_overflow_e;
    assign result_ready_m = (result_src_m != `RESULT_MEM);
    assign branch_update_enable = is_cond_branch_e && ex_mem_enable;
    assign retire_fire = valid_w && global_advance;
    assign set_overflow = retire_fire && overflow_w;
    assign branch_resolved_event = is_cond_branch_e && ex_mem_enable;
    assign mispredict_event = mispredict_e && ex_mem_enable;
    assign effective_load_stall = load_use_stall && !mem_wait &&
                                  !redirect_e && !jump_direct_event_d;

    // Count instructions actually discarded by a control redirect.  The
    // ID/EX bubble used for load-use does not discard its held consumer.
    assign flushed_valid_count = (!reset && !mem_wait && redirect_e) ?
                                  (2'd1 + {1'b0, valid_d}) :
                                  ((!reset && !mem_wait &&
                                    jump_direct_event_d) ? 2'd1 : 2'd0);

    always @(*) begin
        case (dest_sel_d)
            `DEST_RD: dest_d = rd_d;
            `DEST_RT: dest_d = rt_d;
            `DEST_RA: dest_d = 5'd31;
            default:  dest_d = 5'd0;
        endcase

        case (result_src_w)
            `RESULT_ALU: write_data_w = alu_result_w;
            `RESULT_MEM: write_data_w = mem_rdata_w;
            `RESULT_PC4: write_data_w = pc_plus4_w;
            `RESULT_LUI: write_data_w = lui_value_w;
            default:     write_data_w = 32'b0;
        endcase

        case (result_src_m)
            `RESULT_ALU: forward_value_m = alu_result_m;
            `RESULT_PC4: forward_value_m = pc_plus4_m;
            `RESULT_LUI: forward_value_m = lui_value_m;
            default:     forward_value_m = alu_result_m;
        endcase
    end

    overflow_status u_overflow_status(
        .clk(clk), .reset(reset), .set_overflow(set_overflow),
        .clear_overflow(clear_overflow),
        .overflow_status(overflow_status)
    );

    performance_counter u_performance_counter(
        .clk(clk), .reset(reset), .count_enable(count_enable),
        .retire_fire(retire_fire),
        .branch_resolved(branch_resolved_event),
        .mispredict(mispredict_event),
        .load_use_stall(effective_load_stall), .mem_wait(mem_wait),
        .flushed_valid_count(flushed_valid_count),
        .cycle_count(cycle_count), .retired_count(retired_count),
        .branch_count(branch_count),
        .mispredict_count(mispredict_count),
        .load_stall_count(load_stall_count),
        .mem_wait_count(mem_wait_count), .flush_count(flush_count)
    );

    hazard_unit u_hazard(
        .reset(reset), .mem_wait(mem_wait),
        .redirect_e(redirect_e), .jump_direct_d(jump_direct_event_d),
        .mem_read_e(mem_read_e), .dest_e(dest_e),
        .rs_d(rs_d), .rt_d(rt_d), .uses_rs_d(uses_rs_d),
        .uses_rt_d(uses_rt_d), .valid_d(valid_d && !illegal_d),
        .valid_e(valid_e), .load_use_stall(load_use_stall),
        .pc_enable(pc_enable), .if_id_enable(if_id_enable),
        .id_ex_enable(id_ex_enable), .ex_mem_enable(ex_mem_enable),
        .mem_wb_enable(mem_wb_enable), .if_id_flush(if_id_flush),
        .id_ex_flush(id_ex_flush), .global_advance(global_advance)
    );

    pc_reg #(.RESET_PC(RESET_PC)) u_pc(
        .clk(clk), .reset(reset), .enable(pc_enable),
        .next_pc(next_pc_f), .pc(pc_f)
    );

    if_id_reg u_if_id(
        .clk(clk), .reset(reset), .enable(if_id_enable), .flush(if_id_flush),
        .valid_f(!reset), .pc_f(pc_f), .pc_plus4_f(pc_plus4_f),
        .inst_f(imem_rdata), .pred_taken_f(pred_taken_f),
        .pred_target_f(pred_target_f), .pred_index_f(pred_index_f),
        .valid_d(valid_d), .pc_d(pc_d), .pc_plus4_d(pc_plus4_d),
        .inst_d(inst_d), .pred_taken_d(pred_taken_d),
        .pred_target_d(pred_target_d), .pred_index_d(pred_index_d)
    );

    control_unit u_control(
        .opcode(opcode_d), .funct(funct_d), .is_zero_inst(inst_d == 32'b0),
        .reg_write(reg_write_d), .dest_sel(dest_sel_d),
        .alu_src_b(alu_src_b_d), .imm_mode(imm_mode_d),
        .alu_control(alu_control_d), .mem_read(mem_read_d),
        .mem_write(mem_write_d), .result_src(result_src_d),
        .branch_eq(branch_eq_d), .branch_ne(branch_ne_d),
        .jump_direct(jump_direct_d), .jump_link(jump_link_d),
        .jump_reg(jump_reg_d), .check_overflow(check_overflow_d),
        .uses_rs(uses_rs_d), .uses_rt(uses_rt_d), .illegal(illegal_d)
    );

    regfile u_regfile(
        .clk(clk), .reset(reset), .raddr1(rs_d), .raddr2(rt_d),
        .rdata1(rs_value_d), .rdata2(rt_value_d),
        .write_enable(write_enable_w), .write_addr(dest_w),
        .write_data(write_data_w)
    );

    imm_extend u_imm_extend(
        .imm16(imm16_d), .imm_mode(imm_mode_d), .imm_ext(imm_ext_d),
        .lui_value(lui_value_d), .branch_offset(branch_offset_d)
    );

    branch_predictor #(.PRED_MODE(PRED_MODE), .ENTRY_NUM(64)) u_predictor(
        .clk(clk), .reset(reset), .query_pc(pc_f),
        .query_valid(!reset), .pred_taken(pred_taken_f),
        .pred_target(pred_target_f), .pred_index(pred_index_f),
        .btb_hit(btb_hit_f), .update_enable(branch_update_enable),
        .update_pc(pc_e), .update_index(pred_index_e),
        .actual_taken(actual_taken_e), .actual_target(actual_target_e)
    );

    id_ex_reg u_id_ex(
        .clk(clk), .reset(reset), .enable(id_ex_enable), .flush(id_ex_flush),
        .valid_d(valid_d && !illegal_d), .pc_d(pc_d),
        .pc_plus4_d(pc_plus4_d), .rs_value_d(rs_decode_value_d),
        .rt_value_d(rt_decode_value_d), .rs_d(rs_d), .rt_d(rt_d),
        .dest_d(dest_d), .imm_ext_d(imm_ext_d),
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

    forwarding_unit u_forwarding(
        .rs_e(rs_e), .rt_e(rt_e), .dest_m(dest_m), .dest_w(dest_w),
        .reg_write_m(reg_write_m && !overflow_m),
        .reg_write_w(reg_write_w && !overflow_w),
        .result_ready_m(result_ready_m), .valid_m(valid_m),
        .valid_w(valid_w), .forward_a(forward_a_e),
        .forward_b(forward_b_e), .forward_store(forward_store_e)
    );

    mux3 #(.WIDTH(32)) u_forward_a_mux(
        .a(rs_value_e), .b(write_data_w), .c(forward_value_m),
        .sel(forward_a_e), .y(rs_forwarded_e)
    );

    mux3 #(.WIDTH(32)) u_forward_b_mux(
        .a(rt_value_e), .b(write_data_w), .c(forward_value_m),
        .sel(forward_b_e), .y(rt_forwarded_e)
    );

    mux3 #(.WIDTH(32)) u_forward_store_mux(
        .a(rt_value_e), .b(write_data_w), .c(forward_value_m),
        .sel(forward_store_e), .y(store_data_e)
    );

    branch_unit u_branch(
        .valid_e(valid_e), .pc_e(pc_e), .pc_plus4_e(pc_plus4_e),
        .rs_value_e(rs_forwarded_e), .rt_value_e(rt_forwarded_e),
        .branch_offset_e(branch_offset_e), .branch_eq_e(branch_eq_e),
        .branch_ne_e(branch_ne_e), .jump_reg_e(jump_reg_e),
        .pred_taken_e(pred_taken_e), .pred_target_e(pred_target_e),
        .is_control_e(is_control_e),
        .is_cond_branch_e(is_cond_branch_e),
        .actual_taken_e(actual_taken_e),
        .actual_target_e(actual_target_e), .mispredict_e(mispredict_e),
        .redirect_e(redirect_e), .correct_pc_e(correct_pc_e)
    );

    alu u_alu(
        .a(rs_forwarded_e), .b(alu_b_e), .shamt(shamt_e),
        .alu_control(alu_control_e), .check_overflow(check_overflow_e),
        .result(alu_result_e), .zero(alu_zero_e),
        .overflow(alu_overflow_e)
    );

    ex_mem_reg u_ex_mem(
        .clk(clk), .reset(reset), .enable(ex_mem_enable), .flush(1'b0),
        .valid_e(valid_e), .pc_e(pc_e), .pc_plus4_e(pc_plus4_e),
        .alu_result_e(alu_result_e), .store_data_e(store_data_e),
        .lui_value_e(lui_value_e), .dest_e(dest_e),
        .reg_write_e(reg_write_e), .mem_read_e(mem_read_e),
        .mem_write_e(mem_write_e), .result_src_e(result_src_e),
        .overflow_e(overflow_e), .valid_m(valid_m), .pc_m(pc_m),
        .pc_plus4_m(pc_plus4_m), .alu_result_m(alu_result_m),
        .store_data_m(store_data_m), .lui_value_m(lui_value_m),
        .dest_m(dest_m), .reg_write_m(reg_write_m),
        .mem_read_m(mem_read_m), .mem_write_m(mem_write_m),
        .result_src_m(result_src_m), .overflow_m(overflow_m)
    );

    mem_wb_reg u_mem_wb(
        .clk(clk), .reset(reset), .enable(mem_wb_enable), .flush(1'b0),
        .valid_m(valid_m), .pc_m(pc_m), .pc_plus4_m(pc_plus4_m),
        .alu_result_m(alu_result_m), .mem_rdata_m(dmem_rdata),
        .lui_value_m(lui_value_m), .dest_m(dest_m),
        .reg_write_m(reg_write_m), .result_src_m(result_src_m),
        .overflow_m(overflow_m), .valid_w(valid_w), .pc_w(pc_w),
        .pc_plus4_w(pc_plus4_w), .alu_result_w(alu_result_w),
        .mem_rdata_w(mem_rdata_w), .lui_value_w(lui_value_w),
        .dest_w(dest_w), .reg_write_w(reg_write_w),
        .result_src_w(result_src_w), .overflow_w(overflow_w)
    );

endmodule
