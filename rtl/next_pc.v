// ============================================================================
// next_pc.v - Branch / Jump Logic (Next-PC selection)
// Owner : Aaryan Gera
// Computes the address of the next instruction:
//   * PC + 4                                  (sequential)
//   * PC + 4 + (sign_ext(imm) << 2)           (beq taken / bne taken)
//   * {PC+4[31:28], instr_index, 2'b00}       (j, jal)
//   * rs                                      (jr)
// Priority: jr > j/jal > branch > sequential.
// ============================================================================
module next_pc (
    input  wire [31:0] pc,
    input  wire [31:0] imm_ext,        // sign-extended branch offset
    input  wire [25:0] instr_index,    // J-type target field
    input  wire [31:0] rs_data,        // jr target
    input  wire        branch,         // beq
    input  wire        branch_ne,      // bne
    input  wire        zero,           // ALU zero flag (rs - rt == 0)
    input  wire        jump,           // j / jal
    input  wire        jr,
    output wire [31:0] pc_plus4,
    output wire [31:0] branch_target,
    output wire        branch_taken,
    output reg  [31:0] pc_next
);
    assign pc_plus4      = pc + 32'd4;
    assign branch_target = pc_plus4 + {imm_ext[29:0], 2'b00};
    assign branch_taken  = (branch & zero) | (branch_ne & ~zero);

    wire [31:0] jump_target = {pc_plus4[31:28], instr_index, 2'b00};

    always @(*) begin
        if (jr)
            pc_next = rs_data;
        else if (jump)
            pc_next = jump_target;
        else if (branch_taken)
            pc_next = branch_target;
        else
            pc_next = pc_plus4;
    end
endmodule
