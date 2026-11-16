// ============================================================================
// mem_interface.v - Data-side Memory Interface / Address Decoder
// Owner : Gaurav Meena
// Sits between the CPU core and the data memory. It decodes every load/store
// address and routes it either to the data RAM or to the memory-mapped I/O
// (MMIO) registers:
//
//   0x0000_0000 .. 0x0000_0FFF  Data RAM (1024 words)
//   0x0000_FFF0                 IO_OUT    W : latch a value on the output port
//   0x0000_FFF8                 IO_CYCLES R : cycle counter since reset
//   0x0000_FFFC                 IO_HALT   W : halt the processor
//
// Unaligned word accesses raise `misaligned` (reported by the testbench).
// ============================================================================
`include "defines.vh"

module mem_interface #(
    parameter DMEM_FILE = ""
) (
    input  wire        clk,
    input  wire        rst,
    // ---- CPU side ----
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire        mem_read,
    input  wire        mem_write,
    output reg  [31:0] rdata,
    // ---- peripheral side ----
    output reg  [31:0] io_out,
    output reg         io_out_valid,           // 1-cycle strobe per write
    output reg         halted,
    output wire        misaligned
);
    // -------------------- address decode --------------------
    wire sel_io  = (addr[15:4] == 12'hFFF);    // 0xFFF0..0xFFFF
    wire sel_ram = (addr[31:12] == 20'h0);     // 0x0000..0x0FFF

    assign misaligned = (mem_read | mem_write) & (addr[1:0] != 2'b00);

    // -------------------- data RAM --------------------
    wire [31:0] ram_rdata;
    dmem #(.MEM_FILE(DMEM_FILE)) u_dmem (
        .clk   (clk),
        .we    (mem_write & sel_ram),
        .addr  (addr),
        .wdata (wdata),
        .rdata (ram_rdata)
    );

    // -------------------- MMIO registers --------------------
    reg [31:0] cycle_count;

    always @(posedge clk) begin
        if (rst) begin
            cycle_count  <= 32'd0;
            io_out       <= 32'd0;
            io_out_valid <= 1'b0;
            halted       <= 1'b0;
        end else begin
            cycle_count  <= cycle_count + 32'd1;
            io_out_valid <= 1'b0;
            if (mem_write && sel_io) begin
                if (addr == `IO_OUT_ADDR) begin
                    io_out       <= wdata;
                    io_out_valid <= 1'b1;
                end
                if (addr == `IO_HALT_ADDR)
                    halted <= 1'b1;
            end
        end
    end

    // -------------------- read mux --------------------
    always @(*) begin
        if (!mem_read)
            rdata = 32'd0;
        else if (sel_ram)
            rdata = ram_rdata;
        else if (addr == `IO_CYCLES_ADDR)
            rdata = cycle_count;
        else if (addr == `IO_OUT_ADDR)
            rdata = io_out;
        else
            rdata = 32'd0;
    end
endmodule
