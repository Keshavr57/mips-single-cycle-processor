#!/usr/bin/env python3
"""
run_tests.py - regression runner (Owner: Aaryan Gera)
Assembles every program, simulates it on the CPU with Icarus Verilog and
compares the values printed on the IO_OUT port with the expected output.
Also runs all unit testbenches. Exit code 0 = everything passed.
"""
import glob, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
RTL = sorted(glob.glob("rtl/*.v"))

EXPECTED = {
    "full_test":   [0x600D],
    "array_sum":   [55],
    "max_search":  [97],
    "factorial":   [1, 2, 6, 24, 120, 720, 5040, 5040],
    "bubble_sort": [-7, 0, 3, 9, 15, 22, 41, 88],
}
UNIT = ["tb_alu", "tb_regfile", "tb_control_unit", "tb_next_pc", "tb_mem_interface"]


def sh(cmd):
    return subprocess.run(cmd, shell=True, capture_output=True, text=True)


def main():
    os.makedirs("sim", exist_ok=True)
    ok = True
    print("== unit tests ==")
    for tb in UNIT:
        r = sh(f"iverilog -g2012 -I rtl -o sim/{tb}.vvp tb/{tb}.v {' '.join(RTL)} && vvp -n sim/{tb}.vvp")
        line = [l for l in r.stdout.splitlines() if "->" in l]
        res = line[-1] if line else (r.stdout + r.stderr).strip()
        passed = res.endswith("PASS")
        ok &= passed
        print(f"  [{'PASS' if passed else 'FAIL'}] {res}")
    print("== program tests ==")
    for prog, exp in EXPECTED.items():
        a = sh(f"python3 scripts/mips_asm.py programs/{prog}.s -o programs/build")
        if a.returncode:
            print("  [FAIL]", a.stderr); ok = False; continue
        r = sh(f"iverilog -g2012 -I rtl -o sim/{prog}.vvp "
               f"-P tb_mips_top.IMEM_FILE='\"programs/build/{prog}.hex\"' "
               f"-P tb_mips_top.DMEM_FILE='\"programs/build/{prog}_data.hex\"' "
               f"-P tb_mips_top.VCD_FILE='\"sim/{prog}.vcd\"' "
               f"tb/tb_mips_top.v {' '.join(RTL)} && vvp -n sim/{prog}.vvp")
        outs = [int(m.group(1)) for m in re.finditer(r"^OUT: \w+ (-?\d+)", r.stdout, re.M)]
        cyc = re.search(r"HALT after (\d+) cycles", r.stdout)
        passed = outs == exp and cyc is not None
        ok &= passed
        print(f"  [{'PASS' if passed else 'FAIL'}] {prog:12s} out={outs} "
              f"cycles={cyc.group(1) if cyc else '?'}")
        if not passed:
            print(r.stdout[-2000:], r.stderr[-2000:])
    print("ALL TESTS PASSED" if ok else "SOME TESTS FAILED")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
