# Team Git Workflow

1. Everyone clones: `git clone https://github.com/<keshav-username>/mips-single-cycle-processor.git`
2. Set **your own** identity once (must match an email on your GitHub account so commits show your avatar):
   ```bash
   git config user.name  "Your Name"
   git config user.email "your.email@nst.rishihood.edu.in"
   ```
3. Before you push: `git pull --rebase`, then `make test` (needs `iverilog`).
4. Small commits with clear messages: `feat(alu): ...`, `test(regfile): ...`, `docs: ...`.

| Owner | Files |
|---|---|
| Keshav | `rtl/defines.vh rtl/control_unit.v rtl/alu_control.v rtl/mips_cpu.v rtl/mips_top.v tb/tb_control_unit.v tb/tb_mips_top.v synth/ report/ docs/ Makefile README.md` |
| Mayank | `rtl/alu.v rtl/regfile.v rtl/sign_extend.v tb/tb_alu.v tb/tb_regfile.v` |
| Gaurav | `rtl/pc.v rtl/imem.v rtl/dmem.v rtl/mem_interface.v tb/tb_mem_interface.v` |
| Aaryan | `rtl/next_pc.v tb/tb_next_pc.v scripts/mips_asm.py scripts/run_tests.py scripts/vcd_plot.py programs/*.s` |
