`timescale 1ns / 1ps

// Demonstrates one complete instruction through the currently available
// modules. Instruction at PC=0 is:
//   32'h2402_0004 = addiu $2, $0, 4
// Expected architectural effect after one commit edge: register $2 = 4.
module single_instruction_demo_tb;

    localparam [1:0] DEST_RD = 2'b00;
    localparam [1:0] DEST_RT = 2'b01;
    localparam [1:0] DEST_RA = 2'b10;
    localparam [1:0] RESULT_ALU = 2'b00;
    localparam [1:0] RESULT_LUI = 2'b11;

    reg clk;
    reg reset;
    reg commit_enable;

    wire [31:0] pc;
    wire [31:0] instruction;
    wire [5:0]  opcode;
    wire [5:0]  funct;
    wire [4:0]  rs;
    wire [4:0]  rt;
    wire [4:0]  rd;
    wire [4:0]  shamt;
    wire [15:0] imm16;

    wire        reg_write;
    wire [1:0]  dest_sel;
    wire        alu_src_b;
    wire [1:0]  imm_mode;
    wire [4:0]  alu_control;
    wire        mem_read;
    wire        mem_write;
    wire [1:0]  result_src;
    wire        branch_eq;
    wire        branch_ne;
    wire        jump_direct;
    wire        jump_link;
    wire        jump_reg;
    wire        check_overflow;
    wire        uses_rs;
    wire        uses_rt;
    wire        illegal;

    wire [31:0] rs_value;
    wire [31:0] rt_value;
    wire [31:0] imm_ext;
    wire [31:0] lui_value;
    wire [31:0] branch_offset;
    wire [31:0] alu_b;
    wire [31:0] alu_result;
    wire        alu_zero;
    wire        alu_overflow;

    reg  [4:0]  write_addr;
    reg  [31:0] write_data;
    wire        write_enable;

    integer errors;

    assign opcode = instruction[31:26];
    assign rs      = instruction[25:21];
    assign rt      = instruction[20:16];
    assign rd      = instruction[15:11];
    assign shamt   = instruction[10:6];
    assign funct   = instruction[5:0];
    assign imm16   = instruction[15:0];

    pc_reg dut_pc(
        .clk(clk),
        .reset(reset),
        .enable(1'b0),
        .next_pc(32'b0),
        .pc(pc)
    );

    imem #(
        .DEPTH(4),
        .INIT_FILE("single_instruction_demo.hex")
    ) dut_imem(
        .addr(pc),
        .rdata(instruction)
    );

    control_unit dut_control(
        .opcode(opcode),
        .funct(funct),
        .is_zero_inst(instruction == 32'b0),
        .reg_write(reg_write),
        .dest_sel(dest_sel),
        .alu_src_b(alu_src_b),
        .imm_mode(imm_mode),
        .alu_control(alu_control),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .result_src(result_src),
        .branch_eq(branch_eq),
        .branch_ne(branch_ne),
        .jump_direct(jump_direct),
        .jump_link(jump_link),
        .jump_reg(jump_reg),
        .check_overflow(check_overflow),
        .uses_rs(uses_rs),
        .uses_rt(uses_rt),
        .illegal(illegal)
    );

    regfile dut_regfile(
        .clk(clk),
        .reset(reset),
        .raddr1(rs),
        .raddr2(rt),
        .rdata1(rs_value),
        .rdata2(rt_value),
        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data)
    );

    imm_extend dut_imm_extend(
        .imm16(imm16),
        .imm_mode(imm_mode),
        .imm_ext(imm_ext),
        .lui_value(lui_value),
        .branch_offset(branch_offset)
    );

    mux2 #(32) dut_alu_b_mux(
        .a(rt_value),
        .b(imm_ext),
        .sel(alu_src_b),
        .y(alu_b)
    );

    alu dut_alu(
        .a(rs_value),
        .b(alu_b),
        .shamt(shamt),
        .alu_control(alu_control),
        .check_overflow(check_overflow),
        .result(alu_result),
        .zero(alu_zero),
        .overflow(alu_overflow)
    );

    always @(*) begin
        case (dest_sel)
            DEST_RD: write_addr = rd;
            DEST_RT: write_addr = rt;
            DEST_RA: write_addr = 5'd31;
            default: write_addr = 5'd0;
        endcase

        case (result_src)
            RESULT_ALU: write_data = alu_result;
            RESULT_LUI: write_data = lui_value;
            default:    write_data = 32'b0;
        endcase
    end

    assign write_enable = commit_enable && reg_write && !illegal && !alu_overflow;

    always #5 clk = ~clk;

    task check_value;
        input [31:0] actual;
        input [31:0] expected;
        input [8*48-1:0] test_name;
        begin
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL: %0s actual=%h expected=%h", test_name, actual, expected);
            end else begin
                $display("PASS: %0s = %h", test_name, actual);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        commit_enable = 1'b0;
        errors = 0;

        // Reset PC and register file at the first rising edge.
        @(posedge clk);
        #1;

        $display("--------------------------------------------------");
        $display("Single instruction demonstration");
        $display("PC          = %h", pc);
        $display("Instruction = %h  (addiu $2,$0,4)", instruction);
        $display("opcode      = %b, rs=%0d, rt=%0d, imm=%h", opcode, rs, rt, imm16);
        $display("reg_write   = %b, dest_sel=%b, alu_src_b=%b", reg_write, dest_sel, alu_src_b);
        $display("rs_value    = %h, imm_ext=%h", rs_value, imm_ext);
        $display("ALU result  = %h, overflow=%b", alu_result, alu_overflow);
        $display("write_addr  = %0d, write_data=%h", write_addr, write_data);
        $display("--------------------------------------------------");

        check_value(pc, 32'h0000_0000, "fetch PC");
        check_value(instruction, 32'h2402_0004, "fetched machine code");
        check_value(rs_value, 32'h0000_0000, "source register $0");
        check_value(imm_ext, 32'h0000_0004, "sign-extended immediate");
        check_value(alu_result, 32'h0000_0004, "ALU addition result");

        if ((reg_write !== 1'b1) || (dest_sel !== DEST_RT) ||
            (alu_src_b !== 1'b1) || (illegal !== 1'b0) ||
            (write_addr !== 5'd2)) begin
            errors = errors + 1;
            $display("FAIL: decoded writeback controls are incorrect");
        end else begin
            $display("PASS: decoded destination is register $2");
        end

        // Commit the decoded result on exactly one rising edge.
        @(negedge clk);
        reset = 1'b0;
        commit_enable = 1'b1;
        @(posedge clk);
        #1;
        commit_enable = 1'b0;

        check_value(rt_value, 32'h0000_0004, "register $2 after writeback");

        if (errors == 0) begin
            $display("SINGLE_INSTRUCTION_DEMO_PASS");
            $finish;
        end else begin
            $fatal(1, "SINGLE_INSTRUCTION_DEMO_FAIL: %0d errors", errors);
        end
    end

endmodule

