// tb_mips_top.v - system testbench: runs a program until it halts
// Owner : Keshav Rajput
// Usage : iverilog -P tb_mips_top.IMEM_FILE=\"x.hex\" -P tb_mips_top.DMEM_FILE=\"x_data.hex\"
// Every value written to IO_OUT is printed as "OUT: <hex> <signed decimal>".
// Every register write is logged to sim/trace.log for debugging.
`timescale 1ns/1ps
module tb_mips_top;
    parameter IMEM_FILE = "programs/build/full_test.hex";
    parameter DMEM_FILE = "programs/build/full_test_data.hex";
    parameter VCD_FILE  = "sim/mips_top.vcd";
    parameter MAX_CYCLES = 20000;

    reg clk = 0, rst = 1;
    wire [31:0] io_out, pc; wire io_v, halted;
    integer cycles = 0, instret = 0, trace;

    mips_top #(.IMEM_FILE(IMEM_FILE), .DMEM_FILE(DMEM_FILE)) dut (
        .clk(clk), .rst(rst), .io_out(io_out), .io_out_valid(io_v),
        .halted(halted), .pc(pc));

    always #5 clk = ~clk;                // 100 MHz simulation clock

    initial begin
        $dumpfile(VCD_FILE);
        $dumpvars(0, tb_mips_top);
        trace = $fopen("sim/trace.log", "w");
        repeat (2) @(posedge clk);
        #1 rst = 0;
    end

    always @(posedge clk) if (!rst) begin
        if (!halted) begin
            cycles = cycles + 1; instret = instret + 1;
            if (dut.u_cpu.dbg_reg_write)
                $fdisplay(trace, "%0d pc=%h instr=%h  $%0d <= %h", cycles,
                          dut.u_cpu.dbg_pc, dut.u_cpu.dbg_instr,
                          dut.u_cpu.dbg_wa, dut.u_cpu.dbg_wd);
            if (dut.u_cpu.dbg_illegal)
                $display("WARN: illegal instruction %h at pc %h",
                         dut.u_cpu.dbg_instr, dut.u_cpu.dbg_pc);
            if (dut.u_memif.misaligned)
                $display("WARN: misaligned access at pc %h", dut.u_cpu.dbg_pc);
        end
        if (io_v) $display("OUT: %h %0d", io_out, $signed(io_out));
        if (halted) begin
            $display("HALT after %0d cycles, %0d instructions, CPI = 1.00", cycles, instret);
            $fclose(trace);
            #20 $finish;
        end
        if (cycles >= MAX_CYCLES) begin
            $display("TIMEOUT after %0d cycles (pc=%h)", cycles, pc);
            $finish;
        end
    end
endmodule
