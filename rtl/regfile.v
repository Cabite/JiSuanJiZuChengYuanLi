`timescale 1ns / 1ps

// 32 x 32-bit MIPS register file with two asynchronous read ports and
// one synchronous write port. Register zero is hard-wired to zero.
module regfile(
    input  wire        clk,
    input  wire        reset,
    input  wire [4:0]  raddr1,
    input  wire [4:0]  raddr2,
    output wire [31:0] rdata1,
    output wire [31:0] rdata2,
    input  wire        write_enable,
    input  wire [4:0]  write_addr,
    input  wire [31:0] write_data
);

    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else if (write_enable && (write_addr != 5'd0)) begin
            regs[write_addr] <= write_data;
        end
    end

    assign rdata1 = (raddr1 == 5'd0) ? 32'b0 : regs[raddr1];
    assign rdata2 = (raddr2 == 5'd0) ? 32'b0 : regs[raddr2];

endmodule

