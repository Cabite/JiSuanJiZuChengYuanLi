`timescale 1ns / 1ps

// Centralized pipeline-control unit.
//
// Stage 6 uses the load-use and memory-wait paths.  The redirect inputs and
// flush outputs are already present so stage 7 can add branches/jumps without
// creating a second, competing source of pipeline enables.
module hazard_unit(
    input  wire       reset,
    input  wire       mem_wait,
    input  wire       redirect_e,
    input  wire       jump_direct_d,

    input  wire       mem_read_e,
    input  wire [4:0] dest_e,
    input  wire [4:0] rs_d,
    input  wire [4:0] rt_d,
    input  wire       uses_rs_d,
    input  wire       uses_rt_d,
    input  wire       valid_d,
    input  wire       valid_e,

    output wire       load_use_stall,
    output reg        pc_enable,
    output reg        if_id_enable,
    output reg        id_ex_enable,
    output reg        ex_mem_enable,
    output reg        mem_wb_enable,
    output reg        if_id_flush,
    output reg        id_ex_flush,
    output reg        global_advance
);

    wire rs_depends_on_load;
    wire rt_depends_on_load;

    assign rs_depends_on_load = uses_rs_d && (rs_d == dest_e);
    assign rt_depends_on_load = uses_rt_d && (rt_d == dest_e);

    // Register zero never carries a dependency.  valid bits prevent reset,
    // flushed bubbles and unused instruction fields from causing false stalls.
    assign load_use_stall = !reset && valid_d && valid_e && mem_read_e &&
                            (dest_e != 5'd0) &&
                            (rs_depends_on_load || rt_depends_on_load);

    always @(*) begin
        // Normal operation: every stage advances.
        pc_enable      = 1'b1;
        if_id_enable   = 1'b1;
        id_ex_enable   = 1'b1;
        ex_mem_enable  = 1'b1;
        mem_wb_enable  = 1'b1;
        if_id_flush    = 1'b0;
        id_ex_flush    = 1'b0;
        global_advance = 1'b1;

        if (reset) begin
            // Pipeline registers perform their own synchronous reset.  Keeping
            // enables low makes the control outputs deterministic during reset.
            pc_enable      = 1'b0;
            if_id_enable   = 1'b0;
            id_ex_enable   = 1'b0;
            ex_mem_enable  = 1'b0;
            mem_wb_enable  = 1'b0;
            global_advance = 1'b0;
        end else if (mem_wait) begin
            // A live MEM transaction must remain unchanged until ready=1.
            pc_enable      = 1'b0;
            if_id_enable   = 1'b0;
            id_ex_enable   = 1'b0;
            ex_mem_enable  = 1'b0;
            mem_wb_enable  = 1'b0;
            global_advance = 1'b0;
        end else if (redirect_e) begin
            // Stage 7 will use this path for an EX-stage redirect.
            if_id_flush = 1'b1;
            id_ex_flush = 1'b1;
        end else if (jump_direct_d) begin
            // Stage 7 will use this path for a direct jump resolved in ID.
            if_id_flush = 1'b1;
        end else if (load_use_stall) begin
            // Hold the consumer in ID, while replacing its attempted entry into
            // EX with a bubble.  The load itself continues into MEM and WB.
            pc_enable    = 1'b0;
            if_id_enable = 1'b0;
            id_ex_flush  = 1'b1;
        end
    end

endmodule
