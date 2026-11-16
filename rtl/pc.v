// ============================================================================
// pc.v - Program Counter register
// Owner : Gaurav Meena
// Holds the address of the current instruction. Updates on every rising clock
// edge with the next-PC value produced by the branch/jump logic. Synchronous
// active-high reset forces execution to start at RESET_VECTOR. When `halt` is
// asserted the PC freezes (used after a write to the IO_HALT register).
// ============================================================================
module pc #(
    parameter RESET_VECTOR = 32'h0000_0000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        halt,
    input  wire [31:0] pc_next,
    output reg  [31:0] pc
);
    always @(posedge clk) begin
        if (rst)
            pc <= RESET_VECTOR;
        else if (!halt)
            pc <= pc_next;
    end
endmodule
