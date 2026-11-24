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
// Phase II: byte and halfword accesses (lb, lbu, lh, lhu, sb, sh).
//   * Stores: the data is copied into the right byte lane(s) and a 4-bit byte
//     enable selects which bytes of the RAM word are written.
//   * Loads : the addressed byte/halfword is shifted down to bit 0 and then
//     sign-extended (lb, lh) or zero-extended (lbu, lhu).
//   * Alignment: words need addr[1:0]=00, halfwords need addr[0]=0. A bad
//     address raises `misaligned` and the store is blocked.
// MMIO registers are word-only.
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
    input  wire [1:0]  size,                   // MEM_BYTE / MEM_HALF / MEM_WORD
    input  wire        is_unsigned,            // zero-extend loads
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
    wire [1:0] off = addr[1:0];                // byte offset inside the word

    wire bad_align = (size == `MEM_WORD) ? (off != 2'b00) :
                     (size == `MEM_HALF) ? off[0] : 1'b0;
    assign misaligned = (mem_read | mem_write) & bad_align;

    // -------------------- store lane steering --------------------
    reg [3:0]  be;
    reg [31:0] lane_wdata;
    always @(*) begin
        case (size)
            `MEM_BYTE: begin
                be         = 4'b0001 << off;
                lane_wdata = {4{wdata[7:0]}};
            end
            `MEM_HALF: begin
                be         = off[1] ? 4'b1100 : 4'b0011;
                lane_wdata = {2{wdata[15:0]}};
            end
            default: begin
                be         = 4'b1111;
                lane_wdata = wdata;
            end
        endcase
    end

    // -------------------- data RAM --------------------
    wire [31:0] ram_rdata;
    dmem #(.MEM_FILE(DMEM_FILE)) u_dmem (
        .clk   (clk),
        .we    (mem_write & sel_ram & ~bad_align),
        .be    (be),
        .addr  (addr),
        .wdata (lane_wdata),
        .rdata (ram_rdata)
    );

    // -------------------- load alignment + extension --------------------
    wire [31:0] shifted = ram_rdata >> {off, 3'b000};   // wanted byte/half -> bit 0
    reg  [31:0] ram_load;
    always @(*) begin
        case (size)
            `MEM_BYTE: ram_load = is_unsigned ? {24'h0, shifted[7:0]}
                                              : {{24{shifted[7]}}, shifted[7:0]};
            `MEM_HALF: ram_load = is_unsigned ? {16'h0, shifted[15:0]}
                                              : {{16{shifted[15]}}, shifted[15:0]};
            default:   ram_load = ram_rdata;
        endcase
    end

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
            rdata = ram_load;
        else if (addr == `IO_CYCLES_ADDR)
            rdata = cycle_count;
        else if (addr == `IO_OUT_ADDR)
            rdata = io_out;
        else
            rdata = 32'd0;
    end
endmodule

// ============================================================================
// Module Summary (Owner: Gaurav Meena):
// This module implements the Data Memory Interface and Address Decoder.
// It sits between the CPU core and physical memory / peripherals:
// 1. Decodes memory addresses into Data RAM (0x0000-0x0FFF) and MMIO registers
//    (IO_OUT at 0xFFF0, IO_CYCLES at 0xFFF8, IO_HALT at 0xFFFC).
// 2. Implements Phase II sub-word support (lb, lbu, lh, lhu, sb, sh, lw, sw):
//    - Store Lane Steering: replicates byte/halfword across 32-bit lanes and
//      generates 4-bit byte enables (be) based on access size and addr[1:0].
//    - Load Alignment & Extension: shifts read data down by 8*addr[1:0] and
//      performs sign extension (lb, lh) or zero extension (lbu, lhu).
//    - Alignment Checking: enforces that word accesses are 4-byte aligned and
//      halfword accesses are 2-byte aligned, asserting 'misaligned' and blocking
//      illegal stores.
// ============================================================================
