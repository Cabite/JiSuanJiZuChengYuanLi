`timescale 1ns / 1ps

// Stage-7 integration test for static not-taken prediction and no-delay-slot
// control transfers.  Wrong paths intentionally contain register writes and
// stores, so any missing flush becomes architecturally visible.
module cpu_control_flow_tb;

    reg clk;
    reg reset;
    reg count_enable;
    reg clear_overflow;
    wire [31:0] imem_addr;
    wire [31:0] imem_rdata;
    wire dmem_valid;
    wire dmem_write;
    wire [3:0] dmem_wstrb;
    wire [31:0] dmem_addr;
    wire [31:0] dmem_wdata;
    wire [31:0] dmem_rdata;
    wire dmem_ready;
    wire overflow_status;
    wire [63:0] cycle_count;
    wire [63:0] retired_count;
    wire [63:0] branch_count;
    wire [63:0] mispredict_count;
    wire [63:0] load_stall_count;
    wire [63:0] mem_wait_count;
    wire [63:0] flush_count;

    integer errors;
    integer load_stalls;
    integer cond_branches;
    integer taken_branches;
    integer not_taken_branches;
    integer branch_mispredicts;
    integer ex_redirects;
    integer direct_jumps;
    integer register_jumps;
    integer read_transactions;
    integer write_transactions;

    cpu_core #(.PRED_MODE(0)) dut(
        .clk(clk), .reset(reset), .count_enable(count_enable),
        .clear_overflow(clear_overflow), .imem_addr(imem_addr),
        .imem_rdata(imem_rdata), .dmem_valid(dmem_valid),
        .dmem_write(dmem_write), .dmem_wstrb(dmem_wstrb),
        .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata), .dmem_ready(dmem_ready),
        .overflow_status(overflow_status), .cycle_count(cycle_count),
        .retired_count(retired_count), .branch_count(branch_count),
        .mispredict_count(mispredict_count),
        .load_stall_count(load_stall_count),
        .mem_wait_count(mem_wait_count), .flush_count(flush_count)
    );

    imem #(
        .DEPTH(128),
        .INIT_FILE("stage7_control_test.hex")
    ) u_imem(
        .addr(imem_addr), .rdata(imem_rdata)
    );

    dmem #(.DEPTH(64)) u_dmem(
        .clk(clk), .reset(reset), .valid(dmem_valid),
        .write(dmem_write), .wstrb(dmem_wstrb), .addr(dmem_addr),
        .wdata(dmem_wdata), .rdata(dmem_rdata), .ready(dmem_ready)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!reset) begin
            if (dut.load_use_stall)
                load_stalls = load_stalls + 1;

            if (dut.is_cond_branch_e) begin
                cond_branches = cond_branches + 1;
                if (dut.actual_taken_e)
                    taken_branches = taken_branches + 1;
                else
                    not_taken_branches = not_taken_branches + 1;
                if (dut.mispredict_e)
                    branch_mispredicts = branch_mispredicts + 1;
            end

            if (dut.redirect_e)
                ex_redirects = ex_redirects + 1;
            if (dut.jump_direct_event_d)
                direct_jumps = direct_jumps + 1;
            if (dut.valid_e && dut.jump_reg_e)
                register_jumps = register_jumps + 1;

            if (dmem_valid && dmem_ready) begin
                if (dmem_write)
                    write_transactions = write_transactions + 1;
                else
                    read_transactions = read_transactions + 1;
            end
        end
    end

    task check32;
        input [31:0] actual;
        input [31:0] expected;
        input [8*60-1:0] test_name;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s actual=%h expected=%h",
                         test_name, actual, expected);
            end else
                $display("PASS: %0s = %h", test_name, actual);
        end
    endtask

    task check_count;
        input integer actual;
        input integer expected;
        input [8*60-1:0] test_name;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s actual=%0d expected=%0d",
                         test_name, actual, expected);
            end else
                $display("PASS: %0s = %0d", test_name, actual);
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        count_enable = 0;
        clear_overflow = 0;
        errors = 0;
        load_stalls = 0;
        cond_branches = 0;
        taken_branches = 0;
        not_taken_branches = 0;
        branch_mispredicts = 0;
        ex_redirects = 0;
        direct_jumps = 0;
        register_jumps = 0;
        read_transactions = 0;
        write_transactions = 0;

        // The first branch is a real lw-to-beq dependency.
        #1 u_dmem.mem[0] = 32'd5;

        repeat (2) @(posedge clk);
        @(negedge clk);
        reset = 0;
        count_enable = 1;

        // Stop the benchmark immediately after the final non-NOP instruction
        // at PC=0x74 retires, so trailing instruction-memory zeros are excluded.
        while (!(dut.valid_w && (dut.pc_w == 32'h0000_0074)))
            @(negedge clk);
        @(posedge clk);
        #1 count_enable = 0;
        repeat (3) @(posedge clk);
        #1;

        check32(dut.u_regfile.regs[1],  32'd5, "setup register $1");
        check32(dut.u_regfile.regs[2],  32'd5, "setup register $2");
        check32(dut.u_regfile.regs[3],  32'd3, "path after taken BEQ executes");
        check32(dut.u_regfile.regs[4],  32'd4, "BNE not-taken fall-through executes");
        check32(dut.u_regfile.regs[5],  32'd5, "BEQ not-taken fall-through executes");
        check32(dut.u_regfile.regs[6],  32'd6, "JAL target function executes");
        check32(dut.u_regfile.regs[7],  32'd1, "JAL return instruction executes exactly once");
        check32(dut.u_regfile.regs[8],  32'd8, "execution continues after returned-path J");
        check32(dut.u_regfile.regs[9],  32'd9, "final sequential instruction executes");
        check32(dut.u_regfile.regs[16], 32'd5, "lw result used by immediate BEQ");
        check32(dut.u_regfile.regs[31], 32'h0000_0054, "JAL writes $31 = PC plus four");

        check32(dut.u_regfile.regs[10], 32'd0, "first taken branch flushes wrong register write");
        check32(dut.u_regfile.regs[11], 32'd0, "second taken branch flushes wrong register write");
        check32(dut.u_regfile.regs[12], 32'd0, "taken BNE flushes wrong register write");
        check32(dut.u_regfile.regs[13], 32'd0, "direct J flushes fetched register write");
        check32(dut.u_regfile.regs[14], 32'd0, "JR flushes wrong register write");
        check32(dut.u_regfile.regs[15], 32'd0, "returned-path J flushes wrong register write");

        check32(u_dmem.mem[0], 32'd5, "source memory remains unchanged");
        check32(u_dmem.mem[1], 32'd0, "wrong-path store after first BEQ is cancelled");
        check32(u_dmem.mem[2], 32'd0, "wrong-path store after second BEQ is cancelled");
        check32(u_dmem.mem[3], 32'd0, "wrong-path store after BNE is cancelled");
        check32(u_dmem.mem[4], 32'd0, "wrong-path store after JR is cancelled");
        check32({31'b0, overflow_status}, 32'd0,
                "control-flow program has no overflow");

        check_count(load_stalls, 1, "lw-to-beq load-use stalls");
        check_count(cond_branches, 5, "conditional branches resolved");
        check_count(taken_branches, 3, "taken conditional branches");
        check_count(not_taken_branches, 2, "not-taken conditional branches");
        check_count(branch_mispredicts, 3,
                    "static-not-taken branch mispredictions");
        check_count(ex_redirects, 4, "EX redirects including JR");
        check_count(direct_jumps, 3, "ID direct J/JAL redirects");
        check_count(register_jumps, 1, "JR executions");
        check_count(read_transactions, 1, "data-memory reads");
        check_count(write_transactions, 0,
                    "wrong-path stores produce no transactions");

        check32(cycle_count[31:0], 32'd35,
                "performance cycle count for benchmark window");
        check32(retired_count[31:0], 32'd19,
                "performance retired instruction count");
        check32(branch_count[31:0], 32'd5,
                "performance conditional branch count");
        check32(mispredict_count[31:0], 32'd3,
                "performance branch misprediction count");
        check32(load_stall_count[31:0], 32'd1,
                "performance load-use stall cycles");
        check32(mem_wait_count[31:0], 32'd0,
                "performance memory wait cycles");
        check32(flush_count[31:0], 32'd11,
                "performance flushed valid instructions");

        $display("PERFORMANCE_RESULT_CONTROL: cycles=%0d retired=%0d CPI=%0.4f IPC=%0.4f",
                 cycle_count, retired_count,
                 $itor(cycle_count[31:0]) / $itor(retired_count[31:0]),
                 $itor(retired_count[31:0]) / $itor(cycle_count[31:0]));
        $display("PERFORMANCE_RESULT_CONTROL: branches=%0d mispredicts=%0d accuracy=%0.2f%% flushes=%0d load_stalls=%0d",
                 branch_count, mispredict_count,
                 100.0 * $itor(branch_count[31:0] - mispredict_count[31:0]) /
                 $itor(branch_count[31:0]), flush_count, load_stall_count);

        if (errors == 0) begin
            $display("CPU_CONTROL_FLOW_TB_PASS");
            $finish;
        end else
            $fatal(1, "CPU_CONTROL_FLOW_TB_FAIL: %0d errors", errors);
    end

endmodule
