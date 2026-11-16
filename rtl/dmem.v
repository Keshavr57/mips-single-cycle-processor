// ============================================================================
// dmem.v - Data Memory (RAM)
// Owner : Gaurav Meena
// 32-bit wide, word-addressed RAM. Writes happen on the rising clock edge when
// `we` is high; reads are combinational (required for a single-cycle CPU, the
// loaded value must be available in the same cycle for write-back).
// Optional initial contents (".data" section) come from a hex file.
// ============================================================================
module dmem #(
    parameter DEPTH    = 1024,
    parameter AW       = 10,
    parameter MEM_FILE = ""
) (
    input  wire        clk,
    input  wire        we,
    input  wire [31:0] addr,                   // byte address
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);
    reg [31:0] ram [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            ram[i] = 32'h0000_0000;
        if (MEM_FILE != "")
            $readmemh(MEM_FILE, ram);
    end

    always @(posedge clk) begin
        if (we)
            ram[addr[AW+1:2]] <= wdata;
    end

    assign rdata = ram[addr[AW+1:2]];
endmodule
