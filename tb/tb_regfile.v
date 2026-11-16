// tb_regfile.v - unit test for regfile.v   (Owner: Mayank Gupta)
`timescale 1ns/1ps
module tb_regfile;
    reg clk = 0, rst = 1, we = 0;
    reg [4:0] ra1 = 0, ra2 = 0, wa = 0; reg [31:0] wd = 0;
    wire [31:0] rd1, rd2;
    integer i, errors = 0;
    regfile dut (.clk(clk), .rst(rst), .we(we), .ra1(ra1), .ra2(ra2), .wa(wa),
                 .wd(wd), .rd1(rd1), .rd2(rd2));
    always #5 clk = ~clk;

    initial begin
        $dumpfile("sim/tb_regfile.vcd"); $dumpvars(0, tb_regfile);
        @(posedge clk); #1 rst = 0;
        // write r[i] = i*0x01010101 for every register
        for (i = 0; i < 32; i = i + 1) begin
            we = 1; wa = i; wd = i * 32'h01010101; @(posedge clk); #1;
        end
        we = 0;
        for (i = 0; i < 32; i = i + 1) begin
            ra1 = i; ra2 = 31 - i; #1;
            if (rd1 !== (i == 0 ? 0 : i * 32'h01010101)) begin
                errors = errors + 1; $display("FAIL rd1 r%0d = %h", i, rd1);
            end
            if (rd2 !== ((31 - i) == 0 ? 0 : (31 - i) * 32'h01010101)) begin
                errors = errors + 1; $display("FAIL rd2 r%0d = %h", 31 - i, rd2);
            end
        end
        // write disabled must not change state
        wa = 5; wd = 32'hDEADBEEF; we = 0; @(posedge clk); #1; ra1 = 5; #1;
        if (rd1 !== 5 * 32'h01010101) begin errors = errors + 1; $display("FAIL we=0"); end
        $display("tb_regfile: 66 checks, %0d errors -> %s", errors, errors ? "FAIL" : "PASS");
        $finish;
    end
endmodule
