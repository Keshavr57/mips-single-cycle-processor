// ============================================================================
// mips_top.v - System top: CPU core + instruction memory + memory interface
// Owner : Keshav Rajput
// Harvard organisation: separate instruction ROM and data-side memory
// interface (data RAM + memory-mapped I/O).
// ============================================================================
module mips_top #(
    parameter IMEM_FILE = "programs/build/full_test.hex",
    parameter DMEM_FILE = ""
) (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] io_out,
    output wire        io_out_valid,
    output wire        halted,
    output wire [31:0] pc
);
    wire [31:0] imem_addr, imem_data;
    wire [31:0] dmem_addr, dmem_wdata, dmem_rdata;
    wire        dmem_read, dmem_write, misaligned;
    wire [1:0]  dmem_size;
    wire        dmem_unsigned;

    mips_cpu u_cpu (
        .clk(clk), .rst(rst), .halt(halted),
        .imem_addr(imem_addr), .imem_data(imem_data),
        .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata),
        .dmem_read(dmem_read), .dmem_write(dmem_write),
        .dmem_size(dmem_size), .dmem_unsigned(dmem_unsigned),
        .dmem_rdata(dmem_rdata),
        .dbg_pc(pc), .dbg_instr(), .dbg_reg_write(), .dbg_wa(), .dbg_wd(),
        .dbg_illegal()
    );

    imem #(.MEM_FILE(IMEM_FILE)) u_imem (
        .addr(imem_addr), .instr(imem_data)
    );

    mem_interface #(.DMEM_FILE(DMEM_FILE)) u_memif (
        .clk(clk), .rst(rst),
        .addr(dmem_addr), .wdata(dmem_wdata),
        .mem_read(dmem_read), .mem_write(dmem_write),
        .size(dmem_size), .is_unsigned(dmem_unsigned),
        .rdata(dmem_rdata),
        .io_out(io_out), .io_out_valid(io_out_valid),
        .halted(halted), .misaligned(misaligned)
    );
endmodule
