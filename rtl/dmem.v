`timescale 1ns / 1ps

// Behavioral data memory with combinational read and synchronous byte writes.
// The current CPU subset will use wstrb=4'b1111 for aligned 32-bit accesses.
module dmem #(
    parameter DEPTH = 2048,
    parameter INIT_FILE = ""
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        valid,
    input  wire        write,
    input  wire [3:0]  wstrb,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata,
    output wire        ready
);

    localparam MEM_BYTES = DEPTH * 4;
    localparam ADDR_WIDTH = $clog2(DEPTH);
    reg [31:0] mem [0:DEPTH-1];
    integer i;

    wire in_range;
    wire read_enable;
    wire [ADDR_WIDTH-1:0] word_index;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'b0;

        if (INIT_FILE != "")
            $readmemh(INIT_FILE, mem);
    end

    assign word_index  = addr[ADDR_WIDTH+1:2];
    assign in_range   = (addr < MEM_BYTES);
    assign read_enable = valid && !write && in_range;
    assign rdata      = read_enable ? mem[word_index] : 32'b0;
    assign ready      = 1'b1;

    always @(posedge clk) begin
        if (!reset && valid && write && in_range) begin
            if (wstrb[0]) mem[word_index][7:0]   <= wdata[7:0];
            if (wstrb[1]) mem[word_index][15:8]  <= wdata[15:8];
            if (wstrb[2]) mem[word_index][23:16] <= wdata[23:16];
            if (wstrb[3]) mem[word_index][31:24] <= wdata[31:24];
        end
    end

endmodule
