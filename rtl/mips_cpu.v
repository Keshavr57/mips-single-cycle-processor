// ============================================================================
// mips_cpu.v - Single-Cycle MIPS32 Core (datapath + control)
// Owner : Keshav Rajput (integration)
// Connects PC, register file, sign extension, ALU, control, ALU control,
// branch/jump logic and the write-back multiplexer. Instruction and data
// memories are external and reached through the instruction bus (imem_*) and
// the data bus (dmem_*), which is what the memory interface module serves.
// Every instruction completes in exactly one clock cycle (CPI = 1).
// ============================================================================
`include "defines.vh"

module mips_cpu (
    input  wire        clk,
    input  wire        rst,
    input  wire        halt,
    // instruction bus
    output wire [31:0] imem_addr,
    input  wire [31:0] imem_data,
    // data bus
    output wire [31:0] dmem_addr,
    output wire [31:0] dmem_wdata,
    output wire        dmem_read,
    output wire        dmem_write,
    input  wire [31:0] dmem_rdata,
    // debug / observation
    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_instr,
    output wire        dbg_reg_write,
    output wire [4:0]  dbg_wa,
    output wire [31:0] dbg_wd,
    output wire        dbg_illegal
);
    // ------------------------------------------------------------ fetch
    wire [31:0] pc_cur, pc_next, pc_plus4, branch_target;
    wire        branch_taken;

    pc u_pc (
        .clk(clk), .rst(rst), .halt(halt),
        .pc_next(pc_next), .pc(pc_cur)
    );

    assign imem_addr = pc_cur;
    wire [31:0] instr = imem_data;

    // ------------------------------------------------------------ decode
    wire [5:0]  opcode = instr[31:26];
    wire [4:0]  rs     = instr[25:21];
    wire [4:0]  rt     = instr[20:16];
    wire [4:0]  rd     = instr[15:11];
    wire [4:0]  shamt  = instr[10:6];
    wire [5:0]  funct  = instr[5:0];
    wire [15:0] imm    = instr[15:0];
    wire [25:0] index  = instr[25:0];

    wire [1:0] reg_dst, mem_to_reg;
    wire       alu_src, reg_write, mem_read, mem_write;
    wire       branch, branch_ne, jump, jr, zero_ext, illegal;
    wire [2:0] alu_op;

    control_unit u_ctrl (
        .opcode(opcode), .funct(funct),
        .reg_dst(reg_dst), .alu_src(alu_src), .mem_to_reg(mem_to_reg),
        .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
        .branch(branch), .branch_ne(branch_ne), .jump(jump), .jr(jr),
        .zero_ext(zero_ext), .alu_op(alu_op), .illegal(illegal)
    );

    // destination register mux
    reg [4:0] wa;
    always @(*) begin
        case (reg_dst)
            `RD_RD : wa = rd;
            `RD_RA : wa = 5'd31;
            default: wa = rt;
        endcase
    end

    wire [31:0] rd1, rd2, wb_data;

    regfile u_rf (
        .clk(clk), .rst(rst), .we(reg_write & ~halt),
        .ra1(rs), .ra2(rt), .wa(wa), .wd(wb_data),
        .rd1(rd1), .rd2(rd2)
    );

    wire [31:0] imm_ext;
    sign_extend u_ext (.imm(imm), .zero_ext(zero_ext), .imm_ext(imm_ext));

    // ------------------------------------------------------------ execute
    wire [3:0]  alu_ctrl;
    wire [31:0] alu_b = alu_src ? imm_ext : rd2;
    wire [31:0] alu_result;
    wire        zero, overflow;

    alu_control u_aluc (.alu_op(alu_op), .funct(funct), .alu_ctrl(alu_ctrl));

    alu u_alu (
        .a(rd1), .b(alu_b), .shamt(shamt), .alu_ctrl(alu_ctrl),
        .result(alu_result), .zero(zero), .overflow(overflow)
    );

    next_pc u_npc (
        .pc(pc_cur), .imm_ext(imm_ext), .instr_index(index), .rs_data(rd1),
        .branch(branch), .branch_ne(branch_ne), .zero(zero),
        .jump(jump), .jr(jr),
        .pc_plus4(pc_plus4), .branch_target(branch_target),
        .branch_taken(branch_taken), .pc_next(pc_next)
    );

    // ------------------------------------------------------------ memory
    assign dmem_addr  = alu_result;
    assign dmem_wdata = rd2;
    assign dmem_read  = mem_read;
    assign dmem_write = mem_write & ~halt;

    // ------------------------------------------------------------ write-back
    reg [31:0] wb_mux;
    always @(*) begin
        case (mem_to_reg)
            `WB_MEM: wb_mux = dmem_rdata;
            `WB_PC4: wb_mux = pc_plus4;
            default: wb_mux = alu_result;
        endcase
    end
    assign wb_data = wb_mux;

    // ------------------------------------------------------------ debug
    assign dbg_pc        = pc_cur;
    assign dbg_instr     = instr;
    assign dbg_reg_write = reg_write & ~halt & (wa != 5'd0);
    assign dbg_wa        = wa;
    assign dbg_wd        = wb_data;
    assign dbg_illegal   = illegal;
endmodule
