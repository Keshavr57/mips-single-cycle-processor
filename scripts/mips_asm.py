#!/usr/bin/env python3
"""
mips_asm.py - Two-pass assembler for the Single-Cycle MIPS project.
Owner : Aaryan Gera

Converts a small MIPS assembly program into $readmemh hex files:
    <name>.hex       instruction memory image (.text, starts at 0x0000_0000)
    <name>_data.hex  data memory image        (.data, starts at 0x0000_0000)

Supported instructions
    R : add addu sub subu and or xor nor slt sltu sll srl sra jr
    I : addi addiu andi ori xori slti lui lw sw beq bne
        lb lbu lh lhu sb sh                     (Phase II)
    S2: mul rd, rs, rt                          (Phase II, SPECIAL2)
    J : j jal
Pseudo-instructions
    nop, move rd,rs, li rt,imm32, la rt,label, b label,
    print rs   (store rs to the IO_OUT port 0xFFF0)
    halt       (store to the IO_HALT port 0xFFFC)
Directives
    .text  .data  .word v1, v2, ...  .space nbytes
    .byte b1, b2, ...   .asciiz "text"          (Phase II, little-endian packing)

Usage:  python3 scripts/mips_asm.py programs/array_sum.s -o programs/build
"""
import argparse
import os
import re
import sys

REGS = {
    "zero": 0, "at": 1, "v0": 2, "v1": 3, "a0": 4, "a1": 5, "a2": 6, "a3": 7,
    "t0": 8, "t1": 9, "t2": 10, "t3": 11, "t4": 12, "t5": 13, "t6": 14, "t7": 15,
    "s0": 16, "s1": 17, "s2": 18, "s3": 19, "s4": 20, "s5": 21, "s6": 22, "s7": 23,
    "t8": 24, "t9": 25, "k0": 26, "k1": 27, "gp": 28, "sp": 29, "fp": 30, "ra": 31,
}

R_FUNCT = {"add": 0x20, "addu": 0x21, "sub": 0x22, "subu": 0x23, "and": 0x24,
           "or": 0x25, "xor": 0x26, "nor": 0x27, "slt": 0x2A, "sltu": 0x2B}
SHIFT_FUNCT = {"sll": 0x00, "srl": 0x02, "sra": 0x03}
I_OP = {"addi": 0x08, "addiu": 0x09, "slti": 0x0A, "andi": 0x0C, "ori": 0x0D,
        "xori": 0x0E}
MEM_OP = {"lw": 0x23, "sw": 0x2B,
          "lb": 0x20, "lh": 0x21, "lbu": 0x24, "lhu": 0x25, "sb": 0x28, "sh": 0x29}
BR_OP = {"beq": 0x04, "bne": 0x05}
J_OP = {"j": 0x02, "jal": 0x03}
SPECIAL2 = {"mul": (0x1C, 0x02)}

IO_OUT, IO_HALT = 0xFFF0, 0xFFFC


class AsmError(Exception):
    pass


def reg(tok):
    tok = tok.strip().lstrip("$")
    if tok.isdigit() and 0 <= int(tok) < 32:
        return int(tok)
    if tok in REGS:
        return REGS[tok]
    raise AsmError(f"bad register '{tok}'")


def num(tok):
    tok = tok.strip()
    return int(tok, 0)


def split_ops(s):
    return [x.strip() for x in s.split(",")] if s.strip() else []


def expand_pseudo(mn, ops):
    """Return list of (mnemonic, operands) real instructions."""
    if mn == "nop":
        return [("sll", ["$zero", "$zero", "0"])]
    if mn == "move":
        return [("addu", [ops[0], ops[1], "$zero"])]
    if mn == "b":
        return [("beq", ["$zero", "$zero", ops[0]])]
    if mn == "li":
        # always two words so that pass-1 sizes are fixed
        return [("lui", [ops[0], f"%hi({ops[1]})"]),
                ("ori", [ops[0], ops[0], f"%lo({ops[1]})"])]
    if mn == "la":
        return [("lui", [ops[0], f"%hi({ops[1]})"]),
                ("ori", [ops[0], ops[0], f"%lo({ops[1]})"])]
    if mn == "print":
        return [("ori", ["$at", "$zero", str(IO_OUT)]),
                ("sw", [ops[0], "0($at)"])]
    if mn == "halt":
        return [("ori", ["$at", "$zero", str(IO_HALT)]),
                ("sw", ["$zero", "0($at)"])]
    return [(mn, ops)]


def pack_bytes(data):
    """Turn the byte list of the .data section into little-endian words."""
    words = []
    for i in range(0, len(data), 4):
        chunk = data[i:i + 4] + [0] * (4 - len(data[i:i + 4]))
        words.append(chunk[0] | chunk[1] << 8 | chunk[2] << 16 | chunk[3] << 24)
    return words


def parse(src):
    text, data, labels = [], [], {}
    # data is a list of bytes (int) or pending 32-bit words ('word', lineno, token)
    section = "text"
    for lineno, raw in enumerate(src.splitlines(), 1):
        line = re.sub(r'#(?=(?:[^"]*"[^"]*")*[^"]*$).*', "", raw).strip()
        while True:
            m = re.match(r"^([A-Za-z_][\w]*)\s*:(.*)$", line)
            if not m:
                break
            name = m.group(1)
            if name in labels:
                raise AsmError(f"line {lineno}: duplicate label '{name}'")
            labels[name] = len(text) * 4 if section == "text" else len(data)
            line = m.group(2).strip()
        if not line:
            continue
        if line.startswith("."):
            parts = line.split(None, 1)
            d = parts[0]
            arg = parts[1] if len(parts) > 1 else ""
            if d == ".text":
                section = "text"
            elif d == ".data":
                section = "data"
            elif d == ".word":
                while len(data) % 4:            # .word is always word-aligned
                    data.append(0)
                for v in split_ops(arg):
                    data.extend([("word", lineno, v), None, None, None])
            elif d == ".byte":
                data.extend(num(v) & 0xFF for v in split_ops(arg))
            elif d == ".asciiz":
                m = re.match(r'^"(.*)"$', arg.strip())
                if not m:
                    raise AsmError(f"line {lineno}: .asciiz needs a quoted string")
                txt = m.group(1).encode().decode("unicode_escape")
                data.extend(list(txt.encode("latin-1")) + [0])
            elif d == ".align":
                while len(data) % (1 << num(arg)):
                    data.append(0)
            elif d == ".space":
                data.extend([0] * num(arg))
            else:
                raise AsmError(f"line {lineno}: unknown directive {d}")
            continue
        parts = line.split(None, 1)
        mn = parts[0].lower()
        ops = split_ops(parts[1]) if len(parts) > 1 else []
        for real in expand_pseudo(mn, ops):
            text.append((lineno, raw.strip(), real[0], real[1]))
    return text, data, labels


def value(tok, labels):
    tok = tok.strip()
    m = re.match(r"^%(hi|lo)\((.+)\)$", tok)
    if m:
        v = value(m.group(2), labels) & 0xFFFFFFFF
        return (v >> 16) & 0xFFFF if m.group(1) == "hi" else v & 0xFFFF
    if tok in labels:
        return labels[tok]
    return num(tok)


def imm16(v, signed, lineno):
    if signed and not -32768 <= v <= 32767:
        raise AsmError(f"line {lineno}: immediate {v} out of signed 16-bit range")
    if not signed and not 0 <= v <= 0xFFFF:
        raise AsmError(f"line {lineno}: immediate {v} out of unsigned 16-bit range")
    return v & 0xFFFF


def encode(pc, mn, ops, labels, lineno):
    if mn in R_FUNCT:
        rd, rs, rt = reg(ops[0]), reg(ops[1]), reg(ops[2])
        return (rs << 21) | (rt << 16) | (rd << 11) | R_FUNCT[mn]
    if mn in SHIFT_FUNCT:
        rd, rt, sh = reg(ops[0]), reg(ops[1]), value(ops[2], labels)
        return (rt << 16) | (rd << 11) | ((sh & 31) << 6) | SHIFT_FUNCT[mn]
    if mn in SPECIAL2:
        rd, rs, rt = reg(ops[0]), reg(ops[1]), reg(ops[2])
        op, fn = SPECIAL2[mn]
        return (op << 26) | (rs << 21) | (rt << 16) | (rd << 11) | fn
    if mn == "jr":
        return (reg(ops[0]) << 21) | 0x08
    if mn in I_OP:
        rt, rs, v = reg(ops[0]), reg(ops[1]), value(ops[2], labels)
        signed = mn in ("addi", "addiu", "slti")
        return (I_OP[mn] << 26) | (rs << 21) | (rt << 16) | imm16(v, signed, lineno)
    if mn == "lui":
        rt, v = reg(ops[0]), value(ops[1], labels)
        return (0x0F << 26) | (rt << 16) | imm16(v, False, lineno)
    if mn in MEM_OP:
        rt = reg(ops[0])
        m = re.match(r"^(.*)\((.+)\)$", ops[1].replace(" ", ""))
        if not m:
            raise AsmError(f"line {lineno}: expected offset(base)")
        off = value(m.group(1) or "0", labels)
        rs = reg(m.group(2))
        return (MEM_OP[mn] << 26) | (rs << 21) | (rt << 16) | imm16(off, True, lineno)
    if mn in BR_OP:
        rs, rt = reg(ops[0]), reg(ops[1])
        target = value(ops[2], labels)
        off = (target - (pc + 4)) >> 2
        return (BR_OP[mn] << 26) | (rs << 21) | (rt << 16) | imm16(off, True, lineno)
    if mn in J_OP:
        target = value(ops[0], labels)
        return (J_OP[mn] << 26) | ((target >> 2) & 0x3FFFFFF)
    raise AsmError(f"line {lineno}: unknown instruction '{mn}'")


def assemble(src):
    text, data, labels = parse(src)
    words, listing = [], []
    for i, (lineno, raw, mn, ops) in enumerate(text):
        pc = i * 4
        w = encode(pc, mn, ops, labels, lineno) & 0xFFFFFFFF
        words.append(w)
        listing.append(f"{pc:08x}: {w:08x}    {mn:6s} {', '.join(ops):28s} # {raw}")
    raw = []
    for b in data:
        if b is None:
            continue
        if isinstance(b, tuple):
            w = value(b[2], labels) & 0xFFFFFFFF
            raw.extend([w & 0xFF, (w >> 8) & 0xFF, (w >> 16) & 0xFF, (w >> 24) & 0xFF])
        else:
            raw.append(b)
    dwords = pack_bytes(raw)
    return words, dwords, listing


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source")
    ap.add_argument("-o", "--outdir", default=".")
    args = ap.parse_args()
    with open(args.source) as f:
        src = f.read()
    try:
        words, dwords, listing = assemble(src)
    except AsmError as e:
        sys.exit(f"{args.source}: {e}")
    os.makedirs(args.outdir, exist_ok=True)
    base = os.path.join(args.outdir, os.path.splitext(os.path.basename(args.source))[0])
    with open(base + ".hex", "w") as f:
        f.write("\n".join(f"{w:08x}" for w in words) + "\n")
    with open(base + "_data.hex", "w") as f:
        f.write("\n".join(f"{w:08x}" for w in dwords) + ("\n" if dwords else "00000000\n"))
    with open(base + ".lst", "w") as f:
        f.write("\n".join(listing) + "\n")
    print(f"{args.source}: {len(words)} instructions, {len(dwords)} data words -> {base}.hex")


if __name__ == "__main__":
    main()
