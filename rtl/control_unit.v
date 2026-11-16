// ============================================================================
// control_unit.v - Main Decoder (MIPS Control Unit)
// Owner : Keshav Rajput
// Decodes opcode (and funct for JR) into the datapath control signals.
//
//  Instr | RegDst AluSrc MemToReg RegWr MemRd MemWr Branch BNE Jump ExtOp ALUOp
//  R     |  rd     reg    ALU      1     0     0     0      0   0    -     FUNCT
//  lw    |  rt     imm    MEM      1     1     0     0      0   0    sign  ADD
//  sw    |  -      imm    -        0     0     1     0      0   0    sign  ADD
//  beq   |  -      reg    -        0     0     0     1      0   0    sign  SUB
//  bne   |  -      reg    -        0     0     0     0      1   0    sign  SUB
//  addi  |  rt     imm    ALU      1     0     0     0      0   0    sign  ADD
//  andi  |  rt     imm    ALU      1     0     0     0      0   0    zero  AND
//  ori   |  rt     imm    ALU      1     0     0     0      0   0    zero  OR
//  xori  |  rt     imm    ALU      1     0     0     0      0   0    zero  XOR
//  slti  |  rt     imm    ALU      1     0     0     0      0   0    sign  SLT
//  lui   |  rt     imm    ALU      1     0     0     0      0   0    -     LUI
//  j     |  -      -      -        0     0     0     0      0   1    -     -
//  jal   |  $ra    -      PC+4     1     0     0     0      0   1    -     -
//  jr    |  -      -      -        0     0     0     0      0   0    -     -  (jr=1)
// ============================================================================
`include "defines.vh"

module control_unit (
    input  wire [5:0] opcode,
    input  wire [5:0] funct,
    output reg  [1:0] reg_dst,
    output reg        alu_src,
    output reg  [1:0] mem_to_reg,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        branch,
    output reg        branch_ne,
    output reg        jump,
    output reg        jr,
    output reg        zero_ext,
    output reg  [2:0] alu_op,
    output reg        illegal
);
    always @(*) begin
        // safe defaults = NOP
        reg_dst    = `RD_RT;
        alu_src    = 1'b0;
        mem_to_reg = `WB_ALU;
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        branch     = 1'b0;
        branch_ne  = 1'b0;
        jump       = 1'b0;
        jr         = 1'b0;
        zero_ext   = 1'b0;
        alu_op     = `ALUOP_ADD;
        illegal    = 1'b0;

        case (opcode)
            `OP_RTYPE: begin
                if (funct == `F_JR) begin
                    jr = 1'b1;
                end else begin
                    reg_dst   = `RD_RD;
                    reg_write = 1'b1;
                    alu_op    = `ALUOP_FUNCT;
                end
            end
            `OP_LW: begin
                alu_src = 1'b1; mem_to_reg = `WB_MEM;
                reg_write = 1'b1; mem_read = 1'b1;
            end
            `OP_SW: begin
                alu_src = 1'b1; mem_write = 1'b1;
            end
            `OP_BEQ: begin
                branch = 1'b1; alu_op = `ALUOP_SUB;
            end
            `OP_BNE: begin
                branch_ne = 1'b1; alu_op = `ALUOP_SUB;
            end
            `OP_ADDI, `OP_ADDIU: begin
                alu_src = 1'b1; reg_write = 1'b1;
            end
            `OP_ANDI: begin
                alu_src = 1'b1; reg_write = 1'b1; zero_ext = 1'b1;
                alu_op = `ALUOP_AND;
            end
            `OP_ORI: begin
                alu_src = 1'b1; reg_write = 1'b1; zero_ext = 1'b1;
                alu_op = `ALUOP_OR;
            end
            `OP_XORI: begin
                alu_src = 1'b1; reg_write = 1'b1; zero_ext = 1'b1;
                alu_op = `ALUOP_XOR;
            end
            `OP_SLTI: begin
                alu_src = 1'b1; reg_write = 1'b1; alu_op = `ALUOP_SLT;
            end
            `OP_LUI: begin
                alu_src = 1'b1; reg_write = 1'b1; alu_op = `ALUOP_LUI;
            end
            `OP_J: begin
                jump = 1'b1;
            end
            `OP_JAL: begin
                jump = 1'b1; reg_write = 1'b1;
                reg_dst = `RD_RA; mem_to_reg = `WB_PC4;
            end
            default: illegal = 1'b1;
        endcase
    end
endmodule
