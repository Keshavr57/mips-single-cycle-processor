// tb_alu.v - self-checking unit test for alu.v   (Owner: Mayank Gupta)
`timescale 1ns/1ps
`include "defines.vh"
module tb_alu;
    reg  [31:0] a, b; reg [4:0] sh; reg [3:0] op;
    wire [31:0] y; wire z, ov;
    integer errors = 0, tests = 0;
    alu dut (.a(a), .b(b), .shamt(sh), .alu_ctrl(op), .result(y), .zero(z), .overflow(ov));

    task check(input [3:0] o, input [31:0] x, input [31:0] w, input [4:0] s,
               input [31:0] exp, input expov);
        begin
            op = o; a = x; b = w; sh = s; #1;
            tests = tests + 1;
            if (y !== exp || ov !== expov || z !== (exp == 0)) begin
                errors = errors + 1;
                $display("FAIL op=%b a=%h b=%h -> %h (exp %h) ov=%b", o, x, w, y, exp, ov);
            end
        end
    endtask

    initial begin
        $dumpfile("sim/tb_alu.vcd"); $dumpvars(0, tb_alu);
        check(`ALU_ADD, 32'd7, 32'd5, 0, 32'd12, 0);
        check(`ALU_ADD, 32'h7FFFFFFF, 32'd1, 0, 32'h80000000, 1);   // +overflow
        check(`ALU_SUB, 32'd5, 32'd7, 0, 32'hFFFFFFFE, 0);
        check(`ALU_SUB, 32'h80000000, 32'd1, 0, 32'h7FFFFFFF, 1);   // -overflow
        check(`ALU_SUB, 32'd9, 32'd9, 0, 32'd0, 0);                 // zero flag
        check(`ALU_AND, 32'hF0F0F0F0, 32'hFF00FF00, 0, 32'hF000F000, 0);
        check(`ALU_OR , 32'hF0F0F0F0, 32'h0F000000, 0, 32'hFFF0F0F0, 0);
        check(`ALU_XOR, 32'hFFFF0000, 32'hFF00FF00, 0, 32'h00FFFF00, 0);
        check(`ALU_NOR, 32'h0, 32'h0, 0, 32'hFFFFFFFF, 0);
        check(`ALU_SLT, 32'hFFFFFFFF, 32'd1, 0, 32'd1, 0);          // -1 < 1
        check(`ALU_SLTU,32'hFFFFFFFF, 32'd1, 0, 32'd0, 0);
        check(`ALU_SLL, 32'd0, 32'h1, 31, 32'h80000000, 0);
        check(`ALU_SRL, 32'd0, 32'h80000000, 31, 32'h1, 0);
        check(`ALU_SRA, 32'd0, 32'h80000000, 4, 32'hF8000000, 0);
        check(`ALU_LUI, 32'd0, 32'h0000ABCD, 0, 32'hABCD0000, 0);
        $display("tb_alu: %0d tests, %0d errors -> %s", tests, errors, errors ? "FAIL" : "PASS");
        $finish;
    end
endmodule
