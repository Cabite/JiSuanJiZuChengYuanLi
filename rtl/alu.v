`timescale 1ns / 1ps
`include "cpu_defs.vh"

// Combinational arithmetic and logic unit.
module alu(
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [4:0]  shamt,
    input  wire [4:0]  alu_control,
    input  wire        check_overflow,
    output reg  [31:0] result,
    output wire        zero,
    output reg         overflow
);

    always @(*) begin
        result   = 32'b0;
        overflow = 1'b0;

        case (alu_control)
            `ALU_ADD: begin
                result = a + b;
                if (check_overflow)
                    overflow = (~(a[31] ^ b[31])) & (result[31] ^ a[31]);
            end

            `ALU_SUB: begin
                result = a - b;
                if (check_overflow)
                    overflow = (a[31] ^ b[31]) & (result[31] ^ a[31]);
            end

            `ALU_AND:  result = a & b;
            `ALU_OR:   result = a | b;
            `ALU_XOR:  result = a ^ b;
            `ALU_NOR:  result = ~(a | b);
            `ALU_SLT:  result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            `ALU_SLTU: result = (a < b) ? 32'd1 : 32'd0;
            `ALU_SLL:  result = b << shamt;
            `ALU_SRL:  result = b >> shamt;
            `ALU_SRA:  result = $signed(b) >>> shamt;
            default: begin
                result   = 32'b0;
                overflow = 1'b0;
            end
        endcase
    end

    assign zero = (result == 32'b0);

endmodule

