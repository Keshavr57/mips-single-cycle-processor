// ============================================================================
// sign_extend.v - Immediate Extension Unit
// Owner : Mayank Gupta
// Extends the 16-bit immediate to 32 bits. Arithmetic, load/store and branch
// instructions use sign extension; logical immediates (andi, ori, xori) use
// zero extension as defined by MIPS32.
// ============================================================================
module sign_extend (
    input  wire [15:0] imm,
    input  wire        zero_ext,   // 1: zero-extend, 0: sign-extend
    output wire [31:0] imm_ext
);
    assign imm_ext = zero_ext ? {16'h0000, imm} : {{16{imm[15]}}, imm};
endmodule
