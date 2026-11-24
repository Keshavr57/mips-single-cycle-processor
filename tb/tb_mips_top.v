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
    // Phase II: instruction-mix counters (used by scripts/perf_analysis.py)
    integer n_alu = 0, n_load = 0, n_store = 0, n_branch = 0, n_jump = 0, n_mul = 0;
    wire [5:0] opc = dut.u_cpu.dbg_instr[31:26];
    wire [5:0] fnc = dut.u_cpu.dbg_instr[5:0];

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
            if (opc == 6'h23 || opc == 6'h20 || opc == 6'h21 || opc == 6'h24 || opc == 6'h25)
                n_load = n_load + 1;
            else if (opc == 6'h2B || opc == 6'h28 || opc == 6'h29)
                n_store = n_store + 1;
            else if (opc == 6'h04 || opc == 6'h05)
                n_branch = n_branch + 1;
            else if (opc == 6'h02 || opc == 6'h03 || (opc == 6'h00 && fnc == 6'h08))
                n_jump = n_jump + 1;
            else if (opc == 6'h1C)
                n_mul = n_mul + 1;
            else
                n_alu = n_alu + 1;
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
            $display("MIX: alu=%0d load=%0d store=%0d branch=%0d jump=%0d mul=%0d",
                     n_alu, n_load, n_store, n_branch, n_jump, n_mul);
            $fclose(trace);
            #20 $finish;
        end
        if (cycles >= MAX_CYCLES) begin
            $display("TIMEOUT after %0d cycles (pc=%h)", cycles, pc);
            $finish;
        end
    end
endmodule
