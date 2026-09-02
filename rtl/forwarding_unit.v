`timescale 1ns / 1ps

// EX-stage forwarding controller.
// Selection encoding:
//   2'b00: original ID/EX value
//   2'b01: final MEM/WB writeback value
//   2'b10: early EX/MEM value (only when result_ready_m is true)
// EX/MEM has priority over MEM/WB when both stages match.
module forwarding_unit(
    input  wire [4:0] rs_e,
    input  wire [4:0] rt_e,
    input  wire [4:0] dest_m,
    input  wire [4:0] dest_w,
    input  wire       reg_write_m,
    input  wire       reg_write_w,
    input  wire       result_ready_m,
    input  wire       valid_m,
    input  wire       valid_w,
    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b,
    output reg  [1:0] forward_store
);

    wire match_m_rs;
    wire match_m_rt;
    wire match_w_rs;
    wire match_w_rt;

    assign match_m_rs = valid_m && reg_write_m && result_ready_m &&
                        (dest_m != 5'd0) && (dest_m == rs_e);
    assign match_m_rt = valid_m && reg_write_m && result_ready_m &&
                        (dest_m != 5'd0) && (dest_m == rt_e);
    assign match_w_rs = valid_w && reg_write_w &&
                        (dest_w != 5'd0) && (dest_w == rs_e);
    assign match_w_rt = valid_w && reg_write_w &&
                        (dest_w != 5'd0) && (dest_w == rt_e);

    always @(*) begin
        forward_a = 2'b00;
        if (match_m_rs)
            forward_a = 2'b10;
        else if (match_w_rs)
            forward_a = 2'b01;

        forward_b = 2'b00;
        if (match_m_rt)
            forward_b = 2'b10;
        else if (match_w_rt)
            forward_b = 2'b01;

        // Store data comes from rt and follows the same register match, but
        // remains a separate output for later independent hazard handling.
        forward_store = 2'b00;
        if (match_m_rt)
            forward_store = 2'b10;
        else if (match_w_rt)
            forward_store = 2'b01;
    end

endmodule
