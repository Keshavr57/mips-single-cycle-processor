# Makefile - Single-Cycle MIPS Processor with Memory Interface
# make test            : run every unit test + every program (regression)
# make run PROG=factorial : run one program and open trace
# make wave PROG=array_sum : open waveform in GTKWave
# make synth           : Yosys synthesis + resource report
RTL  := $(wildcard rtl/*.v)
PROG ?= full_test

.PHONY: test run wave synth asm clean

test:
	python3 scripts/run_tests.py

asm:
	@for f in programs/*.s; do python3 scripts/mips_asm.py $$f -o programs/build; done

run: asm
	@mkdir -p sim
	iverilog -g2012 -I rtl -o sim/$(PROG).vvp \
	  -P tb_mips_top.IMEM_FILE='"programs/build/$(PROG).hex"' \
	  -P tb_mips_top.DMEM_FILE='"programs/build/$(PROG)_data.hex"' \
	  -P tb_mips_top.VCD_FILE='"sim/$(PROG).vcd"' tb/tb_mips_top.v $(RTL)
	vvp -n sim/$(PROG).vvp

wave: run
	gtkwave sim/$(PROG).vcd &

synth:
	yosys -q -s synth/synth.ys -l synth/yosys.log
	@echo "Report written to synth/report_stat.txt"

clean:
	rm -rf sim/*.vvp sim/*.vcd sim/trace.log
