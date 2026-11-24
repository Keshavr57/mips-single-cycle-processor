// ============================================================================
// dmem.v - Data Memory (RAM)
// Owner : Gaurav Meena
// 32-bit wide, word-addressed RAM. Writes happen on the rising clock edge and
// only update the bytes whose byte-enable bit is set (Phase II, needed for sb
// and sh). Reads are combinational (required for a single-cycle CPU: the loaded
// value must be available in the same cycle for write-back).
// Byte order is little-endian: byte 0 of a word is bits [7:0].
// Optional initial contents (".data" section) come from a hex file.
// ============================================================================
module dmem #(
    parameter DEPTH    = 1024,
    parameter AW       = 10,
    parameter MEM_FILE = ""
) (
    input  wire        clk,
    input  wire        we,
    input  wire [3:0]  be,                     // byte enables (Phase II)
    input  wire [31:0] addr,                   // byte address
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);
    reg [31:0] ram [0:DEPTH-1];
    integer i;
    wire [AW-1:0] idx = addr[AW+1:2];

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            ram[i] = 32'h0000_0000;
        if (MEM_FILE != "")
            $readmemh(MEM_FILE, ram);
    end

    always @(posedge clk) begin
        if (we) begin
            if (be[0]) ram[idx][7:0]   <= wdata[7:0];
            if (be[1]) ram[idx][15:8]  <= wdata[15:8];
            if (be[2]) ram[idx][23:16] <= wdata[23:16];
            if (be[3]) ram[idx][31:24] <= wdata[31:24];
        end
    end

    assign rdata = ram[idx];
endmodule

// ============================================================================
// Module Summary (Owner: Gaurav Meena):
// This module implements the 4 KB Data Memory (RAM) for the MIPS32 processor.
// In Phase II, it supports byte-granular write enables (be[3:0]), enabling
// sub-word store instructions (sb and sh) without corrupting neighboring bytes.
// Memory reads are purely combinational (asynchronous) to meet the single-cycle
// timing requirement where load data must be available in the same cycle for
// write-back. Writes occur synchronously on the rising clock edge when 'we' is high.
// ============================================================================
