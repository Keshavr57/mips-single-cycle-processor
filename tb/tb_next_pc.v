// tb_next_pc.v - unit test for branch/jump logic (Owner: Aaryan Gera)
`timescale 1ns/1ps
module tb_next_pc;
    reg [31:0] pc, imm, rs; reg [25:0] idx; reg br, bne, z, j, jr;
    wire [31:0] p4, bt, nx; wire taken;
    integer errors = 0, tests = 0;
    next_pc dut (.pc(pc), .imm_ext(imm), .instr_index(idx), .rs_data(rs), .branch(br),
        .branch_ne(bne), .zero(z), .jump(j), .jr(jr), .pc_plus4(p4),
        .branch_target(bt), .branch_taken(taken), .pc_next(nx));

    task chk(input [31:0] exp, input [8*12:1] name);
        begin
            #1; tests = tests + 1;
            if (nx !== exp) begin errors = errors + 1; $display("FAIL %s: %h exp %h", name, nx, exp); end
        end
    endtask

    initial begin
        pc = 32'h100; imm = 32'd3; rs = 32'h400; idx = 26'h40; {br,bne,z,j,jr} = 0;
        chk(32'h104, "sequential");
        br = 1; z = 1;            chk(32'h104 + 12, "beq taken");
        z = 0;                    chk(32'h104, "beq not tkn");
        br = 0; bne = 1;          chk(32'h104 + 12, "bne taken");
        imm = 32'hFFFFFFFE;       chk(32'h104 - 8, "bne back");
        bne = 0; j = 1;           chk(32'h100, "jump");
        jr = 1;                   chk(32'h400, "jr priority");
        $display("tb_next_pc: %0d tests, %0d errors -> %s", tests, errors, errors ? "FAIL" : "PASS");
        $finish;
    end
endmodule
