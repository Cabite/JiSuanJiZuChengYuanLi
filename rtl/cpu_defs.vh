`ifndef CPU_DEFS_VH
`define CPU_DEFS_VH

// ALU operation codes.
`define ALU_ADD   5'b00000
`define ALU_SUB   5'b00001
`define ALU_AND   5'b00010
`define ALU_OR    5'b00011
`define ALU_XOR   5'b00100
`define ALU_NOR   5'b00101
`define ALU_SLT   5'b00110
`define ALU_SLTU  5'b00111
`define ALU_SLL   5'b01000
`define ALU_SRL   5'b01001
`define ALU_SRA   5'b01010

// Immediate extension modes.
`define IMM_SIGN  2'b00
`define IMM_ZERO  2'b01
`define IMM_UPPER 2'b10

// Destination-register selection modes used by later stages.
`define DEST_RD   2'b00
`define DEST_RT   2'b01
`define DEST_RA   2'b10

// Writeback-result selection modes used by later stages.
`define RESULT_ALU 2'b00
`define RESULT_MEM 2'b01
`define RESULT_PC4 2'b10
`define RESULT_LUI 2'b11

// Opcodes used by the stage-2 minimum instruction subset.
`define OP_RTYPE 6'b000000
`define OP_ADDI  6'b001000
`define OP_ADDIU 6'b001001
`define OP_LUI   6'b001111
`define OP_LW    6'b100011
`define OP_SW    6'b101011
`define OP_BEQ   6'b000100
`define OP_BNE   6'b000101
`define OP_J     6'b000010
`define OP_JAL   6'b000011

// R-type function codes used by the stage-2 minimum instruction subset.
`define FUNCT_ADD 6'b100000
`define FUNCT_ADDU 6'b100001
`define FUNCT_SUB 6'b100010
`define FUNCT_SUBU 6'b100011
`define FUNCT_AND 6'b100100
`define FUNCT_OR  6'b100101
`define FUNCT_JR  6'b001000

`endif
