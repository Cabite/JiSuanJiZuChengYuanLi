`timescale 1ns / 1ps
`include "cpu_defs.vh"

// Immediate-value generator for the selected MIPS subset.
module imm_extend(
    input  wire [15:0] imm16,
    input  wire [1:0]  imm_mode,
    output reg  [31:0] imm_ext,
    output wire [31:0] lui_value,
    output wire [31:0] branch_offset
);

    always @(*) begin
        case (imm_mode)
            `IMM_SIGN:  imm_ext = {{16{imm16[15]}}, imm16};
            `IMM_ZERO:  imm_ext = {16'b0, imm16};
            `IMM_UPPER: imm_ext = {imm16, 16'b0};
            default:    imm_ext = 32'b0;
        endcase
    end

    assign lui_value     = {imm16, 16'b0};
    assign branch_offset = {{14{imm16[15]}}, imm16, 2'b00};

endmodule

