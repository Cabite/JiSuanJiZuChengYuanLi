`timescale 1ns / 1ps

// Behavioral instruction memory with combinational read.
// Addresses are byte addresses; only aligned 32-bit words are stored.
module imem #(
    parameter DEPTH = 2048,
    parameter INIT_FILE = ""
)(
    input  wire [31:0] addr,
    output wire [31:0] rdata
);

    localparam MEM_BYTES = DEPTH * 4;
    localparam ADDR_WIDTH = $clog2(DEPTH);
    reg [31:0] mem [0:DEPTH-1];
    integer i;
    wire [ADDR_WIDTH-1:0] word_index;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'b0;

        if (INIT_FILE != "")
            $readmemh(INIT_FILE, mem);
    end

    assign word_index = addr[ADDR_WIDTH+1:2];
    assign rdata = (addr < MEM_BYTES) ? mem[word_index] : 32'b0;

endmodule
