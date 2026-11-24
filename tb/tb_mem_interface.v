// tb_mem_interface.v - data RAM + MMIO decode test (Owner: Gaurav Meena)
`timescale 1ns/1ps
`include "defines.vh"
module tb_mem_interface;
    reg clk = 0, rst = 1, rd = 0, wr = 0;
    reg [31:0] addr = 0, wdata = 0;
    reg [1:0]  size = 2'b10; reg uns = 0;
    wire [31:0] rdata, io_out; wire io_v, halted, mis;
    integer errors = 0, i;
    mem_interface dut (.clk(clk), .rst(rst), .addr(addr), .wdata(wdata), .mem_read(rd),
        .mem_write(wr), .size(size), .is_unsigned(uns), .rdata(rdata), .io_out(io_out), .io_out_valid(io_v),
        .halted(halted), .misaligned(mis));
    always #5 clk = ~clk;

    task write(input [31:0] a, input [31:0] d);
        begin addr = a; wdata = d; wr = 1; rd = 0; @(posedge clk); #1 wr = 0; end
    endtask
    task expect_read(input [31:0] a, input [31:0] d);
        begin
            addr = a; rd = 1; #1;
            if (rdata !== d) begin errors = errors + 1; $display("FAIL read %h = %h exp %h", a, rdata, d); end
            rd = 0;
        end
    endtask

    initial begin
        $dumpfile("sim/tb_mem_interface.vcd"); $dumpvars(0, tb_mem_interface);
        @(posedge clk); #1 rst = 0;
        for (i = 0; i < 16; i = i + 1) write(i * 4, 32'hA5000000 + i);
        for (i = 0; i < 16; i = i + 1) expect_read(i * 4, 32'hA5000000 + i);
        write(32'h0FFC, 32'h12345678); expect_read(32'h0FFC, 32'h12345678); // last word
        // MMIO output port
        addr = `IO_OUT_ADDR; wdata = 32'h600D; wr = 1; @(posedge clk); #1 wr = 0;
        if (!(io_out == 32'h600D && io_v)) begin errors = errors + 1; $display("FAIL IO_OUT"); end
        @(posedge clk); #1 if (io_v) begin errors = errors + 1; $display("FAIL io_valid not a strobe"); end
        // writes to IO must not corrupt RAM word 0
        expect_read(0, 32'hA5000000);
        // cycle counter increases
        addr = `IO_CYCLES_ADDR; rd = 1; #1 i = rdata; @(posedge clk); #1;
        if (rdata != i + 1) begin errors = errors + 1; $display("FAIL cycle counter"); end
        rd = 0;
        // misaligned detection
        addr = 32'h2; rd = 1; #1 if (!mis) begin errors = errors + 1; $display("FAIL misaligned"); end
        rd = 0;
        // ---------------- Phase II: byte / halfword access ----------------
        size = `MEM_WORD; write(32'h100, 32'h11223344);
        size = `MEM_BYTE; uns = 0;
        expect_read(32'h100, 32'h00000044);                 // byte 0 (little-endian)
        expect_read(32'h103, 32'h00000011);                 // byte 3
        write(32'h101, 32'h000000F0);                       // sb to byte 1
        size = `MEM_WORD; expect_read(32'h100, 32'h1122F044);
        size = `MEM_BYTE; uns = 0; expect_read(32'h101, 32'hFFFFFFF0);   // lb sign-extends
        uns = 1;                   expect_read(32'h101, 32'h000000F0);   // lbu zero-extends
        size = `MEM_HALF; uns = 0;
        write(32'h102, 32'h0000ABCD);                       // sh to upper half
        size = `MEM_WORD; expect_read(32'h100, 32'hABCDF044);
        size = `MEM_HALF; uns = 0; expect_read(32'h102, 32'hFFFFABCD);   // lh
        uns = 1;                   expect_read(32'h102, 32'h0000ABCD);   // lhu
        uns = 0;                   expect_read(32'h100, 32'hFFFFF044);   // lh lower half
        // misaligned halfword store must be blocked
        addr = 32'h101; wdata = 32'h5555; size = `MEM_HALF; wr = 1; #1;
        if (!mis) begin errors = errors + 1; $display("FAIL half misaligned flag"); end
        @(posedge clk); #1 wr = 0;
        size = `MEM_WORD; expect_read(32'h100, 32'hABCDF044);
        // halt register
        size = `MEM_WORD; uns = 0;
        write(`IO_HALT_ADDR, 0);
        if (!halted) begin errors = errors + 1; $display("FAIL halt"); end
        $display("tb_mem_interface: %0d errors -> %s", errors, errors ? "FAIL" : "PASS");
        $finish;
    end
endmodule

// ============================================================================
// Testbench Summary (Owner: Gaurav Meena):
// This self-checking testbench thoroughly verifies the Memory Interface (mem_interface):
// 1. Verifies 32-bit aligned reads and writes across Data RAM boundaries.
// 2. Verifies Memory-Mapped I/O functionality (IO_OUT strobe, IO_CYCLES increment,
//    and IO_HALT assertion) ensuring MMIO operations do not corrupt RAM word 0.
// 3. Verifies Phase II sub-word operations:
//    - Little-endian byte extraction (lb, lbu) and sign/zero extension.
//    - Sub-word byte/halfword stores (sb, sh) modifying only targeted byte lanes.
//    - Alignment verification: detects misaligned word and halfword accesses and
//      verifies that misaligned store operations are safely blocked.
// ============================================================================
