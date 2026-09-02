`timescale 1ns / 1ps

module control_unit_tb;

    localparam [1:0] DEST_RD = 2'b00;
    localparam [1:0] DEST_RT = 2'b01;
    localparam [1:0] DEST_RA = 2'b10;
    localparam [1:0] IMM_SIGN = 2'b00;
    localparam [1:0] IMM_UPPER = 2'b10;
    localparam [1:0] RESULT_ALU = 2'b00;
    localparam [1:0] RESULT_MEM = 2'b01;
    localparam [1:0] RESULT_PC4 = 2'b10;
    localparam [1:0] RESULT_LUI = 2'b11;
    localparam [4:0] ALU_ADD = 5'b00000;
    localparam [4:0] ALU_SUB = 5'b00001;
    localparam [4:0] ALU_AND = 5'b00010;
    localparam [4:0] ALU_OR  = 5'b00011;

    reg  [5:0] opcode;
    reg  [5:0] funct;
    reg        is_zero_inst;
    wire       reg_write;
    wire [1:0] dest_sel;
    wire       alu_src_b;
    wire [1:0] imm_mode;
    wire [4:0] alu_control;
    wire       mem_read;
    wire       mem_write;
    wire [1:0] result_src;
    wire       branch_eq;
    wire       branch_ne;
    wire       jump_direct;
    wire       jump_link;
    wire       jump_reg;
    wire       check_overflow;
    wire       uses_rs;
    wire       uses_rt;
    wire       illegal;

    wire [23:0] actual_controls;
    integer errors;

    assign actual_controls = {
        reg_write,
        dest_sel,
        alu_src_b,
        imm_mode,
        alu_control,
        mem_read,
        mem_write,
        result_src,
        branch_eq,
        branch_ne,
        jump_direct,
        jump_link,
        jump_reg,
        check_overflow,
        uses_rs,
        uses_rt,
        illegal
    };

    control_unit dut(
        .opcode(opcode),
        .funct(funct),
        .is_zero_inst(is_zero_inst),
        .reg_write(reg_write),
        .dest_sel(dest_sel),
        .alu_src_b(alu_src_b),
        .imm_mode(imm_mode),
        .alu_control(alu_control),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .result_src(result_src),
        .branch_eq(branch_eq),
        .branch_ne(branch_ne),
        .jump_direct(jump_direct),
        .jump_link(jump_link),
        .jump_reg(jump_reg),
        .check_overflow(check_overflow),
        .uses_rs(uses_rs),
        .uses_rt(uses_rt),
        .illegal(illegal)
    );

    task run_decode_case;
        input [5:0] in_opcode;
        input [5:0] in_funct;
        input in_is_zero;
        input [23:0] expected_controls;
        input [8*48-1:0] test_name;
        begin
            opcode = in_opcode;
            funct = in_funct;
            is_zero_inst = in_is_zero;
            #1;

            if (actual_controls !== expected_controls) begin
                errors = errors + 1;
                $display("FAIL: %0s", test_name);
                $display("  actual  = %b", actual_controls);
                $display("  expected= %b", expected_controls);
            end else begin
                $display("PASS: %0s", test_name);
            end
        end
    endtask

    initial begin
        errors = 0;
        opcode = 0;
        funct = 0;
        is_zero_inst = 0;

        run_decode_case(
            6'b000000, 6'b100000, 1'b0,
            {1'b1, DEST_RD, 1'b0, IMM_SIGN, ALU_ADD,
             1'b0, 1'b0, RESULT_ALU,
             1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
             1'b1, 1'b1, 1'b1, 1'b0},
            "add control vector"
        );

        run_decode_case(
            6'b000000, 6'b100001, 1'b0,
            {1'b1, DEST_RD, 1'b0, IMM_SIGN, ALU_ADD,
             1'b0, 1'b0, RESULT_ALU,
             1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
             1'b0, 1'b1, 1'b1, 1'b0},
            "addu control vector"
        );

        run_decode_case(
            6'b000000, 6'b100010, 1'b0,
            {1'b1, DEST_RD, 1'b0, IMM_SIGN, ALU_SUB,
             1'b0, 1'b0, RESULT_ALU,
             1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
             1'b1, 1'b1, 1'b1, 1'b0},
            "sub control vector"
        );

        run_decode_case(
            6'b000000, 6'b100011, 1'b0,
            {1'b1, DEST_RD, 1'b0, IMM_SIGN, ALU_SUB,
             1'b0, 1'b0, RESULT_ALU,
             1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
             1'b0, 1'b1, 1'b1, 1'b0},
            "subu control vector"
        );

        run_decode_case(
            6'b000000, 6'b100100, 1'b0,
            {1'b1, DEST_RD, 1'b0, IMM_SIGN, ALU_AND,
             1'b0, 1'b0, RESULT_ALU,
             1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
             1'b0, 1'b1, 1'b1, 1'b0},
            "and control vector"
        );

        run_decode_case(
            6'b000000, 6'b100101, 1'b0,
            {1'b1, DEST_RD, 1'b0, IMM_SIGN, ALU_OR,
             1'b0, 1'b0, RESULT_ALU,
             1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
             1'b0, 1'b1, 1'b1, 1'b0},
            "or control vector"
        );

        run_decode_case(
            6'b001001, 6'b000000, 1'b0,
            {1'b1, DEST_RT, 1'b1, IMM_SIGN, ALU_ADD,
             1'b0, 1'b0, RESULT_ALU,
             1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
             1'b0, 1'b1, 1'b0, 1'b0},
            "addiu control vector"
        );

        run_decode_case(
            6'b001000, 6'b000000, 1'b0,
            {1'b1, DEST_RT, 1'b1, IMM_SIGN, ALU_ADD,
             1'b0, 1'b0, RESULT_ALU,
             1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
             1'b1, 1'b1, 1'b0, 1'b0},
            "addi control vector"
        );

        run_decode_case(
            6'b001111, 6'b000000, 1'b0,
            {1'b1, DEST_RT, 1'b0, IMM_UPPER, ALU_ADD,
             1'b0, 1'b0, RESULT_LUI,
             1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
             1'b0, 1'b0, 1'b0, 1'b0},
            "lui control vector"
        );

        run_decode_case(
            6'b100011, 6'b000000, 1'b0,
            {1'b1, DEST_RT, 1'b1, IMM_SIGN, ALU_ADD,
             1'b1, 1'b0, RESULT_MEM,
             1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
             1'b0, 1'b1, 1'b0, 1'b0},
            "lw control vector"
        );

        run_decode_case(
            6'b101011, 6'b000000, 1'b0,
            {1'b0, DEST_RT, 1'b1, IMM_SIGN, ALU_ADD,
             1'b0, 1'b1, RESULT_ALU,
             1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
             1'b0, 1'b1, 1'b1, 1'b0},
            "sw control vector"
        );

        run_decode_case(
            6'b000100, 6'b000000, 1'b0,
            {1'b0, DEST_RD, 1'b0, IMM_SIGN, ALU_SUB,
             1'b0, 1'b0, RESULT_ALU,
             1'b1, 1'b0, 1'b0, 1'b0, 1'b0,
             1'b0, 1'b1, 1'b1, 1'b0},
            "beq control vector"
        );

        run_decode_case(
            6'b000101, 6'b000000, 1'b0,
            {1'b0, DEST_RD, 1'b0, IMM_SIGN, ALU_SUB,
             1'b0, 1'b0, RESULT_ALU,
             1'b0, 1'b1, 1'b0, 1'b0, 1'b0,
             1'b0, 1'b1, 1'b1, 1'b0},
            "bne control vector"
        );

        run_decode_case(
            6'b000010, 6'b000000, 1'b0,
            {1'b0, DEST_RD, 1'b0, IMM_SIGN, ALU_ADD,
             1'b0, 1'b0, RESULT_ALU,
             1'b0, 1'b0, 1'b1, 1'b0, 1'b0,
             1'b0, 1'b0, 1'b0, 1'b0},
            "j control vector"
        );

        run_decode_case(
            6'b000011, 6'b000000, 1'b0,
            {1'b1, DEST_RA, 1'b0, IMM_SIGN, ALU_ADD,
             1'b0, 1'b0, RESULT_PC4,
             1'b0, 1'b0, 1'b1, 1'b1, 1'b0,
             1'b0, 1'b0, 1'b0, 1'b0},
            "jal control vector"
        );

        run_decode_case(
            6'b000000, 6'b001000, 1'b0,
            {1'b0, DEST_RD, 1'b0, IMM_SIGN, ALU_ADD,
             1'b0, 1'b0, RESULT_ALU,
             1'b0, 1'b0, 1'b0, 1'b0, 1'b1,
             1'b0, 1'b1, 1'b0, 1'b0},
            "jr control vector"
        );

        run_decode_case(
            6'b000000, 6'b000000, 1'b1,
            24'b0,
            "all-zero instruction is a legal NOP"
        );

        run_decode_case(
            6'b000000, 6'b111111, 1'b0,
            {1'b0, DEST_RD, 1'b0, IMM_SIGN, ALU_ADD,
             1'b0, 1'b0, RESULT_ALU,
             1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
             1'b0, 1'b0, 1'b0, 1'b1},
            "unsupported R-type function is safe and illegal"
        );

        run_decode_case(
            6'b111111, 6'b000000, 1'b0,
            {1'b0, DEST_RD, 1'b0, IMM_SIGN, ALU_ADD,
             1'b0, 1'b0, RESULT_ALU,
             1'b0, 1'b0, 1'b0, 1'b0, 1'b0,
             1'b0, 1'b0, 1'b0, 1'b1},
            "unsupported opcode is safe and illegal"
        );

        if (errors == 0) begin
            $display("CONTROL_UNIT_TB_PASS");
            $finish;
        end else begin
            $fatal(1, "CONTROL_UNIT_TB_FAIL: %0d errors", errors);
        end
    end

endmodule
