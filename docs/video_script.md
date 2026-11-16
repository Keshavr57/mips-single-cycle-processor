# Prototype Video Script (≤ 5 minutes)

Record the screen (OBS / Loom / Zoom recording). Each member speaks their own part. Keep cameras on during introductions if possible.

| Time | Speaker | Show on screen | What to say |
|---|---|---|---|
| 0:00–0:35 | **Keshav** | Title slide / README | "We are Team ___. I'm Keshav Rajput, team lead, and with me are Mayank Gupta, Gaurav Meena and Aaryan Gera. Our project is a **Single-Cycle MIPS32 Processor with a Memory Interface**, written in Verilog. It runs 27 MIPS instructions, each in one clock cycle, and the memory interface maps a data RAM and I/O registers into the address space." |
| 0:35–1:20 | **Keshav** | `docs/images/datapath.png`, then `rtl/control_unit.v` | Walk the datapath left to right: PC → instruction memory → register file → ALU → memory interface → write-back mux. Show the control table at the top of `control_unit.v` and explain `lw` vs `add` signals. |
| 1:20–2:00 | **Mayank** | `rtl/alu.v`, `rtl/regfile.v` | ALU operations and zero/overflow flags; register file has 2 read ports, 1 write port, `$0` always zero. Run `tb_alu` and show PASS. |
| 2:00–2:40 | **Gaurav** | `rtl/mem_interface.v` + memory map table | Explain address decoding: RAM vs IO_OUT / IO_CYCLES / IO_HALT; misaligned access flag. Run `tb_mem_interface`, show PASS. |
| 2:40–3:30 | **Aaryan** | `rtl/next_pc.v`, `programs/factorial.s`, terminal | Branch target = PC+4+(imm<<2), jump target, jr. Show the assembler turning `factorial.s` into hex. Run `make run PROG=factorial` → 1 2 6 24 120 720 5040. |
| 3:30–4:30 | **Keshav** | terminal `make test`, GTKWave / `wave_array_sum.png` | Run full regression: all PASS. Open waveform: point to PC, instruction, ALU result, MemRead going high on `lw`. Mention CPI = 1 and synthesis numbers (~1,660 LUTs). |
| 4:30–5:00 | **Keshav** | README | Phase II plan: timing / Fmax, byte loads/stores, performance comparison. Thank you. |

> ⚠️ The brief says "introduce all 5 group members" — our team has 4. Say that clearly at the start so it is not marked as missing.
