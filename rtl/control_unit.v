`timescale 1ns / 1ps
`include "cpu_defs.vh"

module control_unit(
    input  wire [5:0] opcode,
    input  wire [5:0] funct,
    input  wire       is_zero_inst,

    output reg        reg_write,
    output reg  [1:0] dest_sel,
    output reg        alu_src_b,
    output reg  [1:0] imm_mode,
    output reg  [4:0] alu_control,
    output reg        mem_read,
    output reg        mem_write,
    output reg  [1:0] result_src,
    output reg        branch_eq,
    output reg        branch_ne,
    output reg        jump_direct,
    output reg        jump_link,
    output reg        jump_reg,
    output reg        check_overflow,
    output reg        uses_rs,
    output reg        uses_rt,
    output reg        illegal
);

    always @(*) begin
        // 默认值：无副作用
        reg_write     = 1'b0;
        dest_sel      = `DEST_RD;
        alu_src_b     = 1'b0;
        imm_mode      = `IMM_SIGN;
        alu_control   = `ALU_ADD;
        mem_read      = 1'b0;
        mem_write     = 1'b0;
        result_src    = `RESULT_ALU;
        branch_eq     = 1'b0;
        branch_ne     = 1'b0;
        jump_direct   = 1'b0;
        jump_link     = 1'b0;
        jump_reg      = 1'b0;
        check_overflow = 1'b0;
        uses_rs       = 1'b0;
        uses_rt       = 1'b0;
        illegal       = 1'b1;

        if (is_zero_inst) begin
            illegal = 1'b0;
        end else begin
            case (opcode)
                `OP_RTYPE: begin
                    case (funct)
                        `FUNCT_ADD: begin
                            reg_write      = 1'b1;
                            dest_sel       = `DEST_RD;
                            alu_control    = `ALU_ADD;
                            result_src     = `RESULT_ALU;
                            check_overflow = 1'b1;
                            uses_rs        = 1'b1;
                            uses_rt        = 1'b1;
                            illegal        = 1'b0;
                        end
                        `FUNCT_ADDU: begin
                            reg_write      = 1'b1;
                            dest_sel       = `DEST_RD;
                            alu_control    = `ALU_ADD;
                            result_src     = `RESULT_ALU;
                            check_overflow = 1'b0;
                            uses_rs        = 1'b1;
                            uses_rt        = 1'b1;
                            illegal        = 1'b0;
                        end
                        `FUNCT_SUB: begin
                            reg_write      = 1'b1;
                            dest_sel       = `DEST_RD;
                            alu_control    = `ALU_SUB;
                            result_src     = `RESULT_ALU;
                            check_overflow = 1'b1;
                            uses_rs        = 1'b1;
                            uses_rt        = 1'b1;
                            illegal        = 1'b0;
                        end
                        `FUNCT_SUBU: begin
                            reg_write      = 1'b1;
                            dest_sel       = `DEST_RD;
                            alu_control    = `ALU_SUB;
                            result_src     = `RESULT_ALU;
                            check_overflow = 1'b0;
                            uses_rs        = 1'b1;
                            uses_rt        = 1'b1;
                            illegal        = 1'b0;
                        end
                        `FUNCT_AND: begin
                            reg_write      = 1'b1;
                            dest_sel       = `DEST_RD;
                            alu_control    = `ALU_AND;
                            result_src     = `RESULT_ALU;
                            uses_rs        = 1'b1;
                            uses_rt        = 1'b1;
                            illegal        = 1'b0;
                        end
                        `FUNCT_OR: begin
                            reg_write      = 1'b1;
                            dest_sel       = `DEST_RD;
                            alu_control    = `ALU_OR;
                            result_src     = `RESULT_ALU;
                            uses_rs        = 1'b1;
                            uses_rt        = 1'b1;
                            illegal        = 1'b0;
                        end
                        // 新增 R 型指令
                        `FUNCT_XOR: begin
                            reg_write      = 1'b1;
                            dest_sel       = `DEST_RD;
                            alu_control    = `ALU_XOR;
                            result_src     = `RESULT_ALU;
                            uses_rs        = 1'b1;
                            uses_rt        = 1'b1;
                            illegal        = 1'b0;
                        end
                        `FUNCT_NOR: begin
                            reg_write      = 1'b1;
                            dest_sel       = `DEST_RD;
                            alu_control    = `ALU_NOR;
                            result_src     = `RESULT_ALU;
                            uses_rs        = 1'b1;
                            uses_rt        = 1'b1;
                            illegal        = 1'b0;
                        end
                        `FUNCT_SLT: begin
                            reg_write      = 1'b1;
                            dest_sel       = `DEST_RD;
                            alu_control    = `ALU_SLT;
                            result_src     = `RESULT_ALU;
                            uses_rs        = 1'b1;
                            uses_rt        = 1'b1;
                            illegal        = 1'b0;
                        end
                        `FUNCT_SLTU: begin
                            reg_write      = 1'b1;
                            dest_sel       = `DEST_RD;
                            alu_control    = `ALU_SLTU;
                            result_src     = `RESULT_ALU;
                            uses_rs        = 1'b1;
                            uses_rt        = 1'b1;
                            illegal        = 1'b0;
                        end
                        `FUNCT_SLL: begin
                            reg_write      = 1'b1;
                            dest_sel       = `DEST_RD;
                            alu_control    = `ALU_SLL;
                            result_src     = `RESULT_ALU;
                            uses_rs        = 1'b0;
                            uses_rt        = 1'b1;
                            illegal        = 1'b0;
                        end
                        `FUNCT_SRL: begin
                            reg_write      = 1'b1;
                            dest_sel       = `DEST_RD;
                            alu_control    = `ALU_SRL;
                            result_src     = `RESULT_ALU;
                            uses_rs        = 1'b0;
                            uses_rt        = 1'b1;
                            illegal        = 1'b0;
                        end
                        `FUNCT_SRA: begin
                            reg_write      = 1'b1;
                            dest_sel       = `DEST_RD;
                            alu_control    = `ALU_SRA;
                            result_src     = `RESULT_ALU;
                            uses_rs        = 1'b0;
                            uses_rt        = 1'b1;
                            illegal        = 1'b0;
                        end
                        `FUNCT_JR: begin
                            jump_reg       = 1'b1;
                            uses_rs        = 1'b1;
                            uses_rt        = 1'b0;
                            illegal        = 1'b0;
                        end
                        default: begin
                            // 保留默认值
                        end
                    endcase
                end

                `OP_ADDI: begin
                    reg_write      = 1'b1;
                    dest_sel       = `DEST_RT;
                    alu_src_b      = 1'b1;
                    imm_mode       = `IMM_SIGN;
                    alu_control    = `ALU_ADD;
                    result_src     = `RESULT_ALU;
                    check_overflow = 1'b1;
                    uses_rs        = 1'b1;
                    uses_rt        = 1'b0;
                    illegal        = 1'b0;
                end

                `OP_ADDIU: begin
                    reg_write      = 1'b1;
                    dest_sel       = `DEST_RT;
                    alu_src_b      = 1'b1;
                    imm_mode       = `IMM_SIGN;
                    alu_control    = `ALU_ADD;
                    result_src     = `RESULT_ALU;
                    check_overflow = 1'b0;
                    uses_rs        = 1'b1;
                    uses_rt        = 1'b0;
                    illegal        = 1'b0;
                end

                // 新增 I 型指令
                `OP_ANDI: begin
                    reg_write      = 1'b1;
                    dest_sel       = `DEST_RT;
                    alu_src_b      = 1'b1;
                    imm_mode       = `IMM_ZERO;
                    alu_control    = `ALU_AND;
                    result_src     = `RESULT_ALU;
                    check_overflow = 1'b0;
                    uses_rs        = 1'b1;
                    uses_rt        = 1'b0;
                    illegal        = 1'b0;
                end
                `OP_ORI: begin
                    reg_write      = 1'b1;
                    dest_sel       = `DEST_RT;
                    alu_src_b      = 1'b1;
                    imm_mode       = `IMM_ZERO;
                    alu_control    = `ALU_OR;
                    result_src     = `RESULT_ALU;
                    check_overflow = 1'b0;
                    uses_rs        = 1'b1;
                    uses_rt        = 1'b0;
                    illegal        = 1'b0;
                end
                `OP_XORI: begin
                    reg_write      = 1'b1;
                    dest_sel       = `DEST_RT;
                    alu_src_b      = 1'b1;
                    imm_mode       = `IMM_ZERO;
                    alu_control    = `ALU_XOR;
                    result_src     = `RESULT_ALU;
                    check_overflow = 1'b0;
                    uses_rs        = 1'b1;
                    uses_rt        = 1'b0;
                    illegal        = 1'b0;
                end
                `OP_SLTI: begin
                    reg_write      = 1'b1;
                    dest_sel       = `DEST_RT;
                    alu_src_b      = 1'b1;
                    imm_mode       = `IMM_SIGN;
                    alu_control    = `ALU_SLT;
                    result_src     = `RESULT_ALU;
                    check_overflow = 1'b0;
                    uses_rs        = 1'b1;
                    uses_rt        = 1'b0;
                    illegal        = 1'b0;
                end
                `OP_SLTIU: begin
                    reg_write      = 1'b1;
                    dest_sel       = `DEST_RT;
                    alu_src_b      = 1'b1;
                    imm_mode       = `IMM_SIGN;
                    alu_control    = `ALU_SLTU;
                    result_src     = `RESULT_ALU;
                    check_overflow = 1'b0;
                    uses_rs        = 1'b1;
                    uses_rt        = 1'b0;
                    illegal        = 1'b0;
                end

                `OP_LUI: begin
                    reg_write      = 1'b1;
                    dest_sel       = `DEST_RT;
                    alu_src_b      = 1'b0;
                    imm_mode       = `IMM_UPPER;
                    alu_control    = `ALU_ADD;
                    result_src     = `RESULT_LUI;
                    check_overflow = 1'b0;
                    uses_rs        = 1'b0;
                    uses_rt        = 1'b0;
                    illegal        = 1'b0;
                end

                `OP_LW: begin
                    reg_write      = 1'b1;
                    dest_sel       = `DEST_RT;
                    alu_src_b      = 1'b1;
                    imm_mode       = `IMM_SIGN;
                    alu_control    = `ALU_ADD;
                    mem_read       = 1'b1;
                    result_src     = `RESULT_MEM;
                    check_overflow = 1'b0;
                    uses_rs        = 1'b1;
                    uses_rt        = 1'b0;
                    illegal        = 1'b0;
                end

                `OP_SW: begin
                    reg_write      = 1'b0;
                    dest_sel       = `DEST_RT;
                    alu_src_b      = 1'b1;
                    imm_mode       = `IMM_SIGN;
                    alu_control    = `ALU_ADD;
                    mem_write      = 1'b1;
                    result_src     = `RESULT_ALU;
                    check_overflow = 1'b0;
                    uses_rs        = 1'b1;
                    uses_rt        = 1'b1;
                    illegal        = 1'b0;
                end

                // 分支指令：显式清零 jump_direct
                `OP_BEQ: begin
                    alu_control = `ALU_SUB;
                    branch_eq   = 1'b1;
                    uses_rs     = 1'b1;
                    uses_rt     = 1'b1;
                    illegal     = 1'b0;
                    jump_direct = 1'b0;
                end

                `OP_BNE: begin
                    alu_control = `ALU_SUB;
                    branch_ne   = 1'b1;
                    uses_rs     = 1'b1;
                    uses_rt     = 1'b1;
                    illegal     = 1'b0;
                    jump_direct = 1'b0;
                end

                `OP_J: begin
                    jump_direct = 1'b1;
                    illegal     = 1'b0;
                end

                `OP_JAL: begin
                    reg_write   = 1'b1;
                    dest_sel    = `DEST_RA;
                    result_src  = `RESULT_PC4;
                    jump_direct = 1'b1;
                    jump_link   = 1'b1;
                    illegal     = 1'b0;
                end

                default: begin
                    // 保留默认值
                end
            endcase
        end
    end

endmodule