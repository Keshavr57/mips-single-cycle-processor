// tb_control_unit.v - checks decoder outputs for every opcode (Owner: Keshav Rajput)
// Phase II: adds lb/lbu/lh/lhu/sb/sh and mul, and checks MemSize/MemUnsigned.
`timescale 1ns/1ps
`include "defines.vh"
module tb_control_unit;
    reg [5:0] op, fn;
    wire [1:0] reg_dst, m2r, msz; wire alu_src, rw, mr, mw, br, bne, j, jr, zx, mu, ill;
    wire [3:0] aluop;
    integer errors = 0, tests = 0;
    control_unit dut (.opcode(op), .funct(fn), .reg_dst(reg_dst), .alu_src(alu_src),
        .mem_to_reg(m2r), .reg_write(rw), .mem_read(mr), .mem_write(mw), .branch(br),
        .branch_ne(bne), .jump(j), .jr(jr), .zero_ext(zx), .alu_op(aluop),
        .mem_size(msz), .mem_unsigned(mu), .illegal(ill));

    // expected: {reg_dst,alu_src,m2r,rw,mr,mw,br,bne,j,jr,zx,aluop,msz,mu,ill} = 21 bits
    task chk(input [5:0] o, input [5:0] f, input [20:0] exp, input [8*6:1] name);
        reg [20:0] got;
        begin
            op = o; fn = f; #1; tests = tests + 1;
            got = {reg_dst, alu_src, m2r, rw, mr, mw, br, bne, j, jr, zx, aluop, msz, mu, ill};
            if (got !== exp) begin
                errors = errors + 1;
                $display("FAIL %s got=%b exp=%b", name, got, exp);
            end
        end
    endtask

    localparam W = 2'b10, H = 2'b01, B = 2'b00;
    initial begin
        //                     rdst  as   m2r   rw   mr   mw   br   bn   j    jr   zx   aluop    msz mu   il
        chk(`OP_RTYPE,`F_ADD,{2'b01,1'b0,2'b00,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0010,W,1'b0,1'b0},"add");
        chk(`OP_RTYPE,`F_JR ,{2'b00,1'b0,2'b00,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,4'b0000,W,1'b0,1'b0},"jr");
        chk(`OP_LW   ,6'd0  ,{2'b00,1'b1,2'b01,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0000,W,1'b0,1'b0},"lw");
        chk(`OP_SW   ,6'd0  ,{2'b00,1'b1,2'b00,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0000,W,1'b0,1'b0},"sw");
        chk(`OP_BEQ  ,6'd0  ,{2'b00,1'b0,2'b00,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,4'b0001,W,1'b0,1'b0},"beq");
        chk(`OP_BNE  ,6'd0  ,{2'b00,1'b0,2'b00,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,4'b0001,W,1'b0,1'b0},"bne");
        chk(`OP_ADDI ,6'd0  ,{2'b00,1'b1,2'b00,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0000,W,1'b0,1'b0},"addi");
        chk(`OP_ANDI ,6'd0  ,{2'b00,1'b1,2'b00,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,4'b0011,W,1'b0,1'b0},"andi");
        chk(`OP_ORI  ,6'd0  ,{2'b00,1'b1,2'b00,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,4'b0100,W,1'b0,1'b0},"ori");
        chk(`OP_SLTI ,6'd0  ,{2'b00,1'b1,2'b00,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0101,W,1'b0,1'b0},"slti");
        chk(`OP_LUI  ,6'd0  ,{2'b00,1'b1,2'b00,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0110,W,1'b0,1'b0},"lui");
        chk(`OP_J    ,6'd0  ,{2'b00,1'b0,2'b00,1'b0,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,4'b0000,W,1'b0,1'b0},"j");
        chk(`OP_JAL  ,6'd0  ,{2'b10,1'b0,2'b10,1'b1,1'b0,1'b0,1'b0,1'b0,1'b1,1'b0,1'b0,4'b0000,W,1'b0,1'b0},"jal");
        // ---- Phase II
        chk(`OP_LB   ,6'd0  ,{2'b00,1'b1,2'b01,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0000,B,1'b0,1'b0},"lb");
        chk(`OP_LBU  ,6'd0  ,{2'b00,1'b1,2'b01,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0000,B,1'b1,1'b0},"lbu");
        chk(`OP_LH   ,6'd0  ,{2'b00,1'b1,2'b01,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0000,H,1'b0,1'b0},"lh");
        chk(`OP_LHU  ,6'd0  ,{2'b00,1'b1,2'b01,1'b1,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0000,H,1'b1,1'b0},"lhu");
        chk(`OP_SB   ,6'd0  ,{2'b00,1'b1,2'b00,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0000,B,1'b0,1'b0},"sb");
        chk(`OP_SH   ,6'd0  ,{2'b00,1'b1,2'b00,1'b0,1'b0,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0000,H,1'b0,1'b0},"sh");
        chk(`OP_SPECIAL2,`F2_MUL,{2'b01,1'b0,2'b00,1'b1,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'b1000,W,1'b0,1'b0},"mul");
        chk(`OP_SPECIAL2,6'd5,{2'b00,1'b0,2'b00,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0000,W,1'b0,1'b1},"sp2bad");
        chk(6'b111111,6'd0  ,{2'b00,1'b0,2'b00,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,4'b0000,W,1'b0,1'b1},"illeg");
        $display("tb_control_unit: %0d opcodes, %0d errors -> %s", tests, errors, errors ? "FAIL" : "PASS");
        $finish;
    end
endmodule
