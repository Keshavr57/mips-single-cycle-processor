#!/usr/bin/env python3
"""vcd_plot.py - render selected VCD signals to a PNG waveform (Owner: Aaryan Gera)
Usage: python3 scripts/vcd_plot.py sim/array_sum.vcd docs/images/wave_array_sum.png 0 24
"""
import sys
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

SIGNALS = [  # (scope-suffix, name, label)
    ("tb_mips_top", "clk", "clk"),
    ("u_cpu", "pc_cur", "PC"),
    ("u_cpu", "instr", "instr"),
    ("u_cpu", "alu_result", "ALU result"),
    ("u_cpu", "zero", "zero"),
    ("u_cpu", "reg_write", "RegWrite"),
    ("u_cpu", "wa", "write reg"),
    ("u_cpu", "wb_data", "write data"),
    ("u_cpu", "mem_write", "MemWrite"),
    ("u_cpu", "mem_read", "MemRead"),
    ("u_cpu", "branch_taken", "branch taken"),
]


def parse_vcd(path, wanted):
    ids, scope, data, t = {}, [], {}, 0
    with open(path) as f:
        for line in f:
            tok = line.split()
            if not tok:
                continue
            if tok[0] == "$scope":
                scope.append(tok[2])
            elif tok[0] == "$upscope":
                scope.pop()
            elif tok[0] == "$var":
                code, name = tok[3], tok[4]
                for sc, nm, lab in wanted:
                    if scope and scope[-1] == sc and name == nm and lab not in ids.values():
                        ids.setdefault(code, []).append(lab)
            elif tok[0].startswith("#"):
                t = int(tok[0][1:])
            elif tok[0][0] in "01xz" and len(tok) == 1:
                for lab in ids.get(tok[0][1:], []):
                    data.setdefault(lab, []).append((t, tok[0][0]))
            elif tok[0][0] == "b":
                for lab in ids.get(tok[1], []):
                    data.setdefault(lab, []).append((t, tok[0][1:]))
    return data


def main():
    vcd, out, c0, c1 = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
    period = 10000  # 10 ns in ps
    t0, t1 = (c0 + 2) * period, (c1 + 2) * period
    data = parse_vcd(vcd, SIGNALS)
    labels = [s[2] for s in SIGNALS if s[2] in data]
    fig, ax = plt.subplots(figsize=(15, 0.55 * len(labels) + 1))
    for row, lab in enumerate(labels):
        y = len(labels) - row - 1
        ev = data[lab]
        width = max(len(v) for _, v in ev)
        for i, (t, v) in enumerate(ev):
            tn = ev[i + 1][0] if i + 1 < len(ev) else t1
            a, b = max(t, t0), min(tn, t1)
            if b <= a:
                continue
            if width == 1:
                lvl = y + (0.7 if v == "1" else 0.1)
                ax.plot([a, b], [lvl, lvl], color="#1f4e79", lw=1.4)
                if i + 1 < len(ev) and tn < t1:
                    nl = y + (0.7 if ev[i + 1][1] == "1" else 0.1)
                    ax.plot([tn, tn], [lvl, nl], color="#1f4e79", lw=1.4)
            else:
                ax.fill_between([a, b], y + 0.1, y + 0.7, color="#dbe8f5", ec="#1f4e79", lw=0.8)
                try:
                    txt = f"{int(v, 2):x}"
                except ValueError:
                    txt = "x"
                if b - a > period * 0.6:
                    ax.text((a + b) / 2, y + 0.4, txt, ha="center", va="center", fontsize=6.5,
                            family="monospace")
    ax.set_yticks([len(labels) - i - 1 + 0.4 for i in range(len(labels))])
    ax.set_yticklabels(labels, fontsize=9)
    ax.set_xlim(t0, t1)
    ax.set_xticks(range(t0, t1 + 1, period * 2))
    ax.set_xticklabels([str((x - 2 * period) // period) for x in range(t0, t1 + 1, period * 2)], fontsize=8)
    ax.set_xlabel("clock cycle")
    ax.grid(axis="x", color="#ddd", lw=0.5)
    for s in ("top", "right", "left"):
        ax.spines[s].set_visible(False)
    plt.tight_layout()
    plt.savefig(out, dpi=170)
    print("wrote", out)


if __name__ == "__main__":
    main()
