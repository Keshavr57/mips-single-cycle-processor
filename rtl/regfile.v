// ============================================================================
// regfile.v - 32 x 32-bit MIPS Register File
// Owner : Mayank Gupta
// Two combinational read ports (rs, rt) and one synchronous write port (rd).
// Register $0 is hard-wired to zero: writes to it are ignored and reads always
// return 0, as required by the MIPS32 ISA.
// ============================================================================
module regfile (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [4:0]  ra1,
    input  wire [4:0]  ra2,
    input  wire [4:0]  wa,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;
            regs[29] <= 32'h0000_0FFC;         // $sp = top of data RAM
        end else if (we && (wa != 5'd0)) begin
            regs[wa] <= wd;
        end
    end

    assign rd1 = (ra1 == 5'd0) ? 32'd0 : regs[ra1];
    assign rd2 = (ra2 == 5'd0) ? 32'd0 : regs[ra2];
endmodule
