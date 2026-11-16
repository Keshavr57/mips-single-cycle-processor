// ============================================================================
// imem.v - Instruction Memory (ROM)
// Owner : Gaurav Meena
// Word-addressed, asynchronous-read instruction ROM. The byte address coming
// from the PC is converted to a word index with addr[AW+1:2]. The contents are
// loaded from a hex file produced by scripts/mips_asm.py.
// ============================================================================
module imem #(
    parameter DEPTH    = 1024,                 // number of 32-bit words
    parameter AW       = 10,                   // log2(DEPTH)
    parameter MEM_FILE = "programs/build/full_test.hex"
) (
    input  wire [31:0] addr,                   // byte address (from PC)
    output wire [31:0] instr
);
    reg [31:0] rom [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            rom[i] = 32'h0000_0000;            // NOP (sll $0,$0,0)
        if (MEM_FILE != "")
            $readmemh(MEM_FILE, rom);
    end

    assign instr = rom[addr[AW+1:2]];
endmodule
