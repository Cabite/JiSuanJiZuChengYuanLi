`timescale 1ns / 1ps

// Self-checking full system test. Uses only the currently supported 16
// instructions, with static prediction. No force/deposit or RAM writes by TB.
module cpu_system_tb;
    reg clk = 0;
    reg reset = 1;
    reg count_enable = 0;
    reg clear_overflow = 0;
    wire overflow_led, debug_write_enable, debug_retire;
    wire [4:0] debug_write_addr;
    wire [31:0] debug_pc, debug_write_data, debug_wb_pc;
    wire [63:0] cycle_count, retired_count, branch_count, mispredict_count;
    wire [63:0] load_stall_count, mem_wait_count, flush_count;
    reg [31:0] expected_pc [0:30];
    reg [4:0] expected_rd [0:30];
    reg [31:0] expected_data [0:30];
    reg [31:0] observed_regs [0:31];
    integer retired_seen = 0;
    integer reads_seen = 0;
    integer stores_seen = 0;
    integer overflows_seen = 0;
    integer i;
    integer monitor_i;

    cpu_system_top #(
        .RESET_PC(32'h10), .IMEM_DEPTH(128), .DMEM_DEPTH(64),
        .IMEM_INIT_FILE("system_test.hex"),
        .DMEM_INIT_FILE("system_data.hex")
    ) dut(
        .clk(clk), .reset(reset), .count_enable(count_enable),
        .clear_overflow(clear_overflow), .overflow_led(overflow_led),
        .debug_pc(debug_pc), .debug_write_enable(debug_write_enable),
        .debug_write_addr(debug_write_addr), .debug_write_data(debug_write_data),
        .debug_retire(debug_retire), .debug_wb_pc(debug_wb_pc),
        .cycle_count(cycle_count), .retired_count(retired_count),
        .branch_count(branch_count), .mispredict_count(mispredict_count),
        .load_stall_count(load_stall_count), .mem_wait_count(mem_wait_count),
        .flush_count(flush_count)
    );

    always #5 clk = ~clk;

    // A broken program/clock must report failure instead of running forever.
    initial begin
        #10000;
        $fatal(1, "CPU_SYSTEM_TB_TIMEOUT: IF_PC=%h retired=%0d",
               debug_pc, retired_seen);
    end

    task check;
        input [63:0] actual;
        input [63:0] expected;
        input [8*64-1:0] label;
        begin
            if (actual !== expected)
                $fatal(1, "CPU_SYSTEM_TB_FAIL: %0s actual=%h expected=%h",
                       label, actual, expected);
            $display("PASS: %0s = %h", label, actual);
        end
    endtask

    // Sample before NBA writes, exactly when the CPU commits the exposed WB
    // transaction. Check every retirement, not just final register contents.
    always @(posedge clk) begin
        if (reset) begin
            retired_seen = 0;
            reads_seen = 0;
            stores_seen = 0;
            overflows_seen = 0;
            for (monitor_i=0; monitor_i<32; monitor_i=monitor_i+1)
                observed_regs[monitor_i] = 0;
        end else if (count_enable) begin
            if (debug_retire !== 1'b0 && debug_retire !== 1'b1)
                $fatal(1, "CPU_SYSTEM_TB_FAIL: unknown retire signal");
            if (debug_retire) begin
                if (retired_seen >= 31)
                    $fatal(1, "CPU_SYSTEM_TB_FAIL: extra retirement");
                if (debug_wb_pc !== expected_pc[retired_seen])
                    $fatal(1, "CPU_SYSTEM_TB_FAIL: retirement %0d PC=%h expected=%h",
                           retired_seen, debug_wb_pc, expected_pc[retired_seen]);
                if (debug_write_enable !== (expected_rd[retired_seen] != 0))
                    $fatal(1, "CPU_SYSTEM_TB_FAIL: wrong WB enable at PC=%h",
                           debug_wb_pc);
                if (debug_write_enable) begin
                    if (debug_write_addr !== expected_rd[retired_seen] ||
                        debug_write_data !== expected_data[retired_seen])
                        $fatal(1, "CPU_SYSTEM_TB_FAIL: PC=%h WB r%0d=%h expected r%0d=%h",
                               debug_wb_pc, debug_write_addr, debug_write_data,
                               expected_rd[retired_seen], expected_data[retired_seen]);
                    observed_regs[debug_write_addr] = debug_write_data;
                end
                retired_seen = retired_seen + 1;
            end
            if (dut.u_cpu.set_overflow)
                overflows_seen = overflows_seen + 1;
            if (dut.dmem_valid && dut.dmem_ready) begin
                if (dut.dmem_write) begin
                    if (dut.dmem_wstrb !== 4'hf)
                        $fatal(1, "CPU_SYSTEM_TB_FAIL: bad store byte enables");
                    case (stores_seen)
                        0: if (dut.dmem_addr !== 8 || dut.dmem_wdata !== 13)
                            $fatal(1, "CPU_SYSTEM_TB_FAIL: first store");
                        1: if (dut.dmem_addr !== 28 || dut.dmem_wdata !== 7)
                            $fatal(1, "CPU_SYSTEM_TB_FAIL: overflow old-value store");
                        2: if (dut.dmem_addr !== 32 || dut.dmem_wdata !== 32'h80000000)
                            $fatal(1, "CPU_SYSTEM_TB_FAIL: ADDIU wrap store");
                        3: if (dut.dmem_addr !== 36 || dut.dmem_wdata !== 32'h7ffffffb)
                            $fatal(1, "CPU_SYSTEM_TB_FAIL: SUBU wrap store");
                        default: $fatal(1, "CPU_SYSTEM_TB_FAIL: unexpected store");
                    endcase
                    stores_seen = stores_seen + 1;
                end else begin
                    case (reads_seen)
                        0: if (dut.dmem_addr !== 8 || dut.dmem_rdata !== 13)
                            $fatal(1, "CPU_SYSTEM_TB_FAIL: store/load round trip");
                        1: if (dut.dmem_addr !== 0 || dut.dmem_rdata !== 32'h7fffffff)
                            $fatal(1, "CPU_SYSTEM_TB_FAIL: initialized positive maximum");
                        2: if (dut.dmem_addr !== 4 || dut.dmem_rdata !== 32'h80000000)
                            $fatal(1, "CPU_SYSTEM_TB_FAIL: initialized negative minimum");
                        default: $fatal(1, "CPU_SYSTEM_TB_FAIL: unexpected load");
                    endcase
                    reads_seen = reads_seen + 1;
                end
            end
        end
    end

    task run_program;
        input integer run_number;
        begin
            @(negedge clk); reset=1; count_enable=0; clear_overflow=0;
            repeat (2) @(posedge clk);
            #1;
            check(debug_pc, 32'h10, "nonzero reset PC");
            check(cycle_count | retired_count | branch_count | mispredict_count |
                  load_stall_count | mem_wait_count | flush_count, 0, "reset counters");
            check({overflow_led, debug_write_enable, debug_retire}, 0, "reset status");
            for (i=0; i<32; i=i+1)
                if (dut.u_cpu.u_regfile.regs[i] !== 0)
                    $fatal(1, "CPU_SYSTEM_TB_FAIL: register reset r%0d", i);
            if (run_number == 2)
                check(dut.u_dmem.mem[9], 32'h7ffffffb, "CPU reset preserves RAM");

            @(negedge clk); reset=0; count_enable=1;
            while (retired_seen < 31) @(negedge clk);
            count_enable=0;
            #1;
            // 31 instructions + 4 fill/drain + 2 load stalls + 8 flush slots.
            check(cycle_count, 45, "system cycles");
            check(retired_count, 31, "system retired instructions");
            check(branch_count, 4, "conditional branches");
            check(mispredict_count, 2, "static prediction misses");
            check(load_stall_count, 2, "load-use stalls");
            check(mem_wait_count, 0, "always-ready internal RAM");
            check(flush_count, 8, "flushed instruction slots");
            check(reads_seen, 3, "completed loads");
            check(stores_seen, 4, "completed stores");
            check(overflows_seen, 2, "signed overflows");
            check(overflow_led, 1, "sticky overflow LED");
            for (i=0; i<32; i=i+1)
                if (dut.u_cpu.u_regfile.regs[i] !== observed_regs[i])
                    $fatal(1, "CPU_SYSTEM_TB_FAIL: register/trace mismatch r%0d", i);
            check(dut.u_dmem.mem[0], 32'h7fffffff, "ROM/data spaces independent");
            check(dut.u_dmem.mem[2], 13, "stored OR result");
            for (i=3; i<=6; i=i+1)
                if (dut.u_dmem.mem[i] !== 0)
                    $fatal(1, "CPU_SYSTEM_TB_FAIL: wrong-path store at word %0d", i);
            check(dut.u_dmem.mem[7], 7, "overflow preserves nonzero destination");
            check(dut.u_dmem.mem[8], 32'h80000000, "unsigned addition wraps");
            check(dut.u_dmem.mem[9], 32'h7ffffffb, "unsigned subtraction wraps");

            repeat (3) @(posedge clk);
            #1;
            check(cycle_count, 45, "disabled cycle counter holds");
            check(retired_count, 31, "trailing NOPs excluded from benchmark");
            @(negedge clk); clear_overflow=1;
            @(posedge clk); #1;
            check(overflow_led, 0, "explicit overflow clear");
            @(negedge clk); clear_overflow=0;
            $display("SYSTEM_PERFORMANCE run=%0d cycles=%0d retired=%0d CPI=%0.4f IPC=%0.4f accuracy=50.00%%",
                     run_number, cycle_count, retired_count,
                     $itor(cycle_count[31:0])/$itor(retired_count[31:0]),
                     $itor(retired_count[31:0])/$itor(cycle_count[31:0]));
        end
    endtask

    initial begin
        expected_pc[0] = 32'h00000010;
        expected_rd[0] = 5'd1;
        expected_data[0] = 32'h00000005;
        expected_pc[1] = 32'h00000014;
        expected_rd[1] = 5'd2;
        expected_data[1] = 32'h00000008;
        expected_pc[2] = 32'h00000018;
        expected_rd[2] = 5'd3;
        expected_data[2] = 32'h0000000d;
        expected_pc[3] = 32'h0000001c;
        expected_rd[3] = 5'd4;
        expected_data[3] = 32'h00000015;
        expected_pc[4] = 32'h00000020;
        expected_rd[4] = 5'd5;
        expected_data[4] = 32'h00000010;
        expected_pc[5] = 32'h00000024;
        expected_rd[5] = 5'd6;
        expected_data[5] = 32'h00000008;
        expected_pc[6] = 32'h00000028;
        expected_rd[6] = 5'd7;
        expected_data[6] = 32'h00000008;
        expected_pc[7] = 32'h0000002c;
        expected_rd[7] = 5'd8;
        expected_data[7] = 32'h0000000d;
        expected_pc[8] = 32'h00000030;
        expected_rd[8] = 5'd9;
        expected_data[8] = 32'h12340000;
        expected_pc[9] = 32'h00000034;
        expected_rd[9] = 5'd0;
        expected_data[9] = 32'h00000000;
        expected_pc[10] = 32'h00000038;
        expected_rd[10] = 5'd10;
        expected_data[10] = 32'h0000000d;
        expected_pc[11] = 32'h0000003c;
        expected_rd[11] = 5'd0;
        expected_data[11] = 32'h00000000;
        expected_pc[12] = 32'h00000048;
        expected_rd[12] = 5'd0;
        expected_data[12] = 32'h00000000;
        expected_pc[13] = 32'h00000054;
        expected_rd[13] = 5'd0;
        expected_data[13] = 32'h00000000;
        expected_pc[14] = 32'h00000058;
        expected_rd[14] = 5'd0;
        expected_data[14] = 32'h00000000;
        expected_pc[15] = 32'h0000005c;
        expected_rd[15] = 5'd31;
        expected_data[15] = 32'h00000060;
        expected_pc[16] = 32'h00000070;
        expected_rd[16] = 5'd12;
        expected_data[16] = 32'h0000002a;
        expected_pc[17] = 32'h00000074;
        expected_rd[17] = 5'd0;
        expected_data[17] = 32'h00000000;
        expected_pc[18] = 32'h00000060;
        expected_rd[18] = 5'd11;
        expected_data[18] = 32'h00000001;
        expected_pc[19] = 32'h00000064;
        expected_rd[19] = 5'd0;
        expected_data[19] = 32'h00000000;
        expected_pc[20] = 32'h00000080;
        expected_rd[20] = 5'd13;
        expected_data[20] = 32'h7fffffff;
        expected_pc[21] = 32'h00000084;
        expected_rd[21] = 5'd14;
        expected_data[21] = 32'h00000007;
        expected_pc[22] = 32'h00000088;
        expected_rd[22] = 5'd0;
        expected_data[22] = 32'h00000000;
        expected_pc[23] = 32'h0000008c;
        expected_rd[23] = 5'd15;
        expected_data[23] = 32'h80000000;
        expected_pc[24] = 32'h00000090;
        expected_rd[24] = 5'd0;
        expected_data[24] = 32'h00000000;
        expected_pc[25] = 32'h00000094;
        expected_rd[25] = 5'd0;
        expected_data[25] = 32'h00000000;
        expected_pc[26] = 32'h00000098;
        expected_rd[26] = 5'd16;
        expected_data[26] = 32'h80000000;
        expected_pc[27] = 32'h0000009c;
        expected_rd[27] = 5'd0;
        expected_data[27] = 32'h00000000;
        expected_pc[28] = 32'h000000a0;
        expected_rd[28] = 5'd18;
        expected_data[28] = 32'h7ffffffb;
        expected_pc[29] = 32'h000000a4;
        expected_rd[29] = 5'd0;
        expected_data[29] = 32'h00000000;
        expected_pc[30] = 32'h000000a8;
        expected_rd[30] = 5'd19;
        expected_data[30] = 32'h00000063;
        run_program(1);
        run_program(2);
        $display("CPU_SYSTEM_TB_PASS");
        $finish;
    end
endmodule
