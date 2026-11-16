#!/usr/bin/env python3
"""draw_datapath.py - draws docs/images/datapath.png (Owner: Keshav Rajput)"""
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch

fig, ax = plt.subplots(figsize=(16, 8.2))
ax.set_xlim(0, 160); ax.set_ylim(0, 82); ax.axis("off")
C = {"blue": ("#e8f0fa", "#1f4e79"), "red": ("#fde9d9", "#c0504d"),
     "green": ("#d7e4bd", "#4f6228"), "gold": ("#fff2cc", "#b8860b"),
     "purple": ("#e4dfec", "#5f497a"), "white": ("#ffffff", "#444444")}
B = {}

def box(key, x, y, w, h, text, col="blue", fs=10):
    fc, ec = C[col]
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.4,rounding_size=1.2",
                                fc=fc, ec=ec, lw=1.6))
    ax.text(x + w / 2, y + h / 2, text, ha="center", va="center", fontsize=fs)
    B[key] = (x, y, w, h)

def arrow(p, q, label=None, lp=None, col="#333", ls="-"):
    ax.annotate("", xy=q, xytext=p, arrowprops=dict(arrowstyle="-|>", color=col, lw=1.3,
                                                   linestyle=ls, shrinkA=0, shrinkB=0))
    if label:
        x, y = lp if lp else ((p[0] + q[0]) / 2, (p[1] + q[1]) / 2 + 1.2)
        ax.text(x, y, label, fontsize=8, ha="center", color="#222",
                bbox=dict(fc="white", ec="none", pad=0.5))

def line(pts, col="#333", ls="-"):
    xs, ys = zip(*pts); ax.plot(xs, ys, color=col, lw=1.3, linestyle=ls)

# datapath blocks
box("pc", 3, 36, 10, 10, "PC\npc.v")
box("im", 20, 33, 15, 16, "Instruction\nMemory\nimem.v")
box("rf", 50, 30, 18, 22, "Register File\n32 x 32\nregfile.v\n\nrs  rt  rd")
box("se", 50, 12, 18, 8, "Sign / Zero\nExtend")
box("mx", 76, 26, 6, 14, "Mux\nALU\nSrc", "white", 8)
box("alu", 88, 30, 14, 16, "ALU\nalu.v", "green", 11)
box("mif", 110, 30, 18, 16, "Memory\nInterface\nmem_interface.v", "gold", 9)
box("ram", 136, 38, 18, 9, "Data RAM 4 KB\ndmem.v", "gold", 9)
box("io", 136, 26, 18, 9, "MMIO\nOUT/CYCLES/HALT", "gold", 8.5)
box("wb", 136, 8, 18, 12, "Write-back Mux\nALU | MEM | PC+4", "white", 9)
# control blocks
box("cu", 50, 66, 22, 10, "Main Control Unit\ncontrol_unit.v", "red")
box("ac", 82, 56, 18, 8, "ALU Control\nalu_control.v", "red", 9)
box("np", 18, 62, 22, 12, "Branch / Jump Logic\nnext_pc.v\nPC+4 | branch | j | jr", "purple", 9)

arrow((13, 41), (20, 41), "addr")
arrow((35, 44), (50, 44), "rs, rt, rd")
line([(30, 49.4), (30, 58), (44, 58), (44, 71)]); arrow((44, 71), (50, 71), "opcode, funct", (44, 73.5))
line([(32, 33), (32, 16)]); arrow((32, 16), (50, 16), "imm[15:0]")
arrow((68, 44), (88, 44), "rd1 (A)", (78, 45.5))
arrow((68, 36), (76, 36), "rd2")
line([(68, 16), (72, 16), (72, 30)]); arrow((72, 30), (76, 30))
arrow((82, 33), (88, 33), "B")
line([(72, 71), (91, 71)]); arrow((91, 71), (91, 64), "ALUOp", (95, 67))
arrow((91, 56), (91, 46.4), "alu_ctrl", (95, 51))
arrow((102, 38), (110, 38), "addr")
line([(68, 32), (74, 32), (74, 24), (106, 24), (106, 34)]); arrow((106, 34), (110, 34), "wdata", (100, 25.4))
arrow((128.4, 42), (136, 42)); arrow((128.4, 32), (136, 31))
line([(119, 30), (119, 16)]); arrow((119, 16), (136, 16), "read data", (126, 17.2))
line([(102, 42), (106, 42), (106, 50), (132, 50), (132, 13)]); arrow((132, 13), (136, 13), "ALU result", (120, 51.5))
line([(145, 8), (145, 4), (46, 4)])
ax.text(100, 2.3, "write-back data -> rd / rt / $ra", fontsize=8, ha="center")
line([(46, 4), (46, 40)]); arrow((46, 40), (50, 40), "wd", (47.5, 41.5))
line([(95, 46.4), (95, 52), (104, 52), (104, 78), (29, 78)]); arrow((29, 78), (29, 74.4), "zero", (104, 66))
line([(18, 68), (8, 68)]); arrow((8, 68), (8, 46), "pc_next", (8, 57))
line([(13, 44), (15, 44), (15, 64)]); arrow((15, 64), (18, 64), "pc", (14, 59))
line([(72, 68), (76, 68), (76, 60), (42, 60)]); arrow((42, 60), (40, 63), "branch/jump/jr", (60, 61.5), col="#c0504d")
ax.text(80, 80.5, "Single-Cycle MIPS32 Processor with Memory Interface — Datapath and Control",
        ha="center", fontsize=13, weight="bold")
plt.savefig("docs/images/datapath.png", dpi=170, bbox_inches="tight")
print("ok")
