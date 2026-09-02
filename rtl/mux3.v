`timescale 1ns / 1ps

// Parameterized three-input multiplexer.
// 00 selects a, 01 selects b, 10 selects c.
// 11 is reserved and safely falls back to a.
module mux3 #(
    parameter WIDTH = 32
)(
    input  wire [WIDTH-1:0] a,
    input  wire [WIDTH-1:0] b,
    input  wire [WIDTH-1:0] c,
    input  wire [1:0]       sel,
    output reg  [WIDTH-1:0] y
);

    always @(*) begin
        case (sel)
            2'b00: y = a;
            2'b01: y = b;
            2'b10: y = c;
            default: y = a;
        endcase
    end

endmodule

