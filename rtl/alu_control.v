// ============================================================================
// alu_control.v - ALU Control (second-level decoder)
// Owner : Keshav Rajput
// Maps the main decoder's ALUOp and the instruction funct field to the 4-bit
// operation select used by the ALU. Also tells the datapath whether the
// instruction is a shift by shamt (sll/srl/sra).
// ============================================================================
`include "defines.vh"

module alu_control (
    input  wire [2:0] alu_op,
    input  wire [5:0] funct,
    output reg  [3:0] alu_ctrl
);
    always @(*) begin
        case (alu_op)
            `ALUOP_ADD : alu_ctrl = `ALU_ADD;
            `ALUOP_SUB : alu_ctrl = `ALU_SUB;
            `ALUOP_AND : alu_ctrl = `ALU_AND;
            `ALUOP_OR  : alu_ctrl = `ALU_OR;
            `ALUOP_XOR : alu_ctrl = `ALU_XOR;
            `ALUOP_SLT : alu_ctrl = `ALU_SLT;
            `ALUOP_LUI : alu_ctrl = `ALU_LUI;
            `ALUOP_FUNCT: begin
                case (funct)
                    `F_ADD, `F_ADDU : alu_ctrl = `ALU_ADD;
                    `F_SUB, `F_SUBU : alu_ctrl = `ALU_SUB;
                    `F_AND          : alu_ctrl = `ALU_AND;
                    `F_OR           : alu_ctrl = `ALU_OR;
                    `F_XOR          : alu_ctrl = `ALU_XOR;
                    `F_NOR          : alu_ctrl = `ALU_NOR;
                    `F_SLT          : alu_ctrl = `ALU_SLT;
                    `F_SLTU         : alu_ctrl = `ALU_SLTU;
                    `F_SLL          : alu_ctrl = `ALU_SLL;
                    `F_SRL          : alu_ctrl = `ALU_SRL;
                    `F_SRA          : alu_ctrl = `ALU_SRA;
                    default         : alu_ctrl = `ALU_ADD;
                endcase
            end
            default: alu_ctrl = `ALU_ADD;
        endcase
    end
endmodule
