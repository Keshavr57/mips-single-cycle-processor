// ============================================================================
// defines.vh - Shared constants for the Single-Cycle MIPS Processor
// Project : Single-Cycle MIPS Processor with Memory Interface (MCA, NST)
// ============================================================================
`ifndef MIPS_DEFINES_VH
`define MIPS_DEFINES_VH

// ---------------- Opcodes (instr[31:26]) ----------------
`define OP_RTYPE  6'b000000
`define OP_J      6'b000010
`define OP_JAL    6'b000011
`define OP_BEQ    6'b000100
`define OP_BNE    6'b000101
`define OP_ADDI   6'b001000
`define OP_ADDIU  6'b001001
`define OP_SLTI   6'b001010
`define OP_ANDI   6'b001100
`define OP_ORI    6'b001101
`define OP_XORI   6'b001110
`define OP_LUI    6'b001111
`define OP_LW     6'b100011
`define OP_SW     6'b101011

// ---------------- Funct codes (instr[5:0], R-type) ----------------
`define F_SLL     6'b000000
`define F_SRL     6'b000010
`define F_SRA     6'b000011
`define F_JR      6'b001000
`define F_ADD     6'b100000
`define F_ADDU    6'b100001
`define F_SUB     6'b100010
`define F_SUBU    6'b100011
`define F_AND     6'b100100
`define F_OR      6'b100101
`define F_XOR     6'b100110
`define F_NOR     6'b100111
`define F_SLT     6'b101010
`define F_SLTU    6'b101011

// ---------------- Main-decoder ALUOp (control -> alu_control) -------------
`define ALUOP_ADD   3'b000   // lw, sw, addi, addiu
`define ALUOP_SUB   3'b001   // beq, bne
`define ALUOP_FUNCT 3'b010   // R-type: look at funct
`define ALUOP_AND   3'b011   // andi
`define ALUOP_OR    3'b100   // ori
`define ALUOP_SLT   3'b101   // slti
`define ALUOP_LUI   3'b110   // lui
`define ALUOP_XOR   3'b111   // xori

// ---------------- ALU operation select (alu_control -> alu) ---------------
`define ALU_AND   4'b0000
`define ALU_OR    4'b0001
`define ALU_ADD   4'b0010
`define ALU_XOR   4'b0011
`define ALU_SUB   4'b0110
`define ALU_SLT   4'b0111
`define ALU_SLL   4'b1000
`define ALU_SRL   4'b1001
`define ALU_SRA   4'b1010
`define ALU_LUI   4'b1011
`define ALU_NOR   4'b1100
`define ALU_SLTU  4'b1101

// ---------------- Write-back source select ----------------
`define WB_ALU    2'b00
`define WB_MEM    2'b01
`define WB_PC4    2'b10   // jal link value

// ---------------- Destination register select ----------------
`define RD_RT     2'b00
`define RD_RD     2'b01
`define RD_RA     2'b10   // $31 for jal

// ---------------- Memory map ----------------
// 0x0000_0000 - 0x0000_0FFF : Data RAM (1024 x 32-bit words)
// 0x0000_FFF0               : IO_OUT    (write: output port to host / LEDs)
// 0x0000_FFF8               : IO_CYCLES (read : free-running cycle counter)
// 0x0000_FFFC               : IO_HALT   (write: stop the simulation / CPU)
`define IO_OUT_ADDR    32'h0000_FFF0
`define IO_CYCLES_ADDR 32'h0000_FFF8
`define IO_HALT_ADDR   32'h0000_FFFC

`endif
