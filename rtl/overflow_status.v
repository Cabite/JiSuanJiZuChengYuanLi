`timescale 1ns / 1ps

// Sticky arithmetic-overflow status.
// Priority: reset > explicit clear > new overflow > hold.
module overflow_status(
    input  wire clk,
    input  wire reset,
    input  wire set_overflow,
    input  wire clear_overflow,
    output reg  overflow_status
);

    always @(posedge clk) begin
        if (reset)
            overflow_status <= 1'b0;
        else if (clear_overflow)
            overflow_status <= 1'b0;
        else if (set_overflow)
            overflow_status <= 1'b1;
    end

endmodule
