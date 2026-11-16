// ============================================================================
// alu.v - 32-bit Arithmetic Logic Unit
// Owner : Mayank Gupta
// Supports add, sub, and, or, xor, nor, slt (signed), sltu, logical/arithmetic
// shifts (by shamt) and lui. Produces `zero` for BEQ/BNE and a signed
// `overflow` flag for add/sub (reported, not trapped).
// ============================================================================
`include "defines.vh"

module alu (
    input  wire [31:0] a,          // rs
    input  wire [31:0] b,          // rt or immediate
    input  wire [4:0]  shamt,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] result,
    output wire        zero,
    output reg         overflow
);
    wire [31:0] sum  = a + b;
    wire [31:0] diff = a - b;

    always @(*) begin
        overflow = 1'b0;
        case (alu_ctrl)
            `ALU_AND : result = a & b;
            `ALU_OR  : result = a | b;
            `ALU_XOR : result = a ^ b;
            `ALU_NOR : result = ~(a | b);
            `ALU_ADD : begin
                result   = sum;
                overflow = (a[31] == b[31]) && (sum[31] != a[31]);
            end
            `ALU_SUB : begin
                result   = diff;
                overflow = (a[31] != b[31]) && (diff[31] != a[31]);
            end
            `ALU_SLT : result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            `ALU_SLTU: result = (a < b) ? 32'd1 : 32'd0;
            `ALU_SLL : result = b << shamt;
            `ALU_SRL : result = b >> shamt;
            `ALU_SRA : result = $signed(b) >>> shamt;
            `ALU_LUI : result = {b[15:0], 16'h0000};
            default  : result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);
endmodule
