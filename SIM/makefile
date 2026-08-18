# ==============================================================================
# KRISHNA.P / APB LAYER_TB IN SV
# Update this section when porting this Makefile to another project.
# ==============================================================================

# 1. Explicit RTL File Paths (Listed in exact compilation order)
RTL          ?= ../RTL/apb_slave.v

# 2. Explicit Testbench File Paths (Listed in exact compilation order)
TB           ?= ../ENV/apb_inf.sv \
                ../TEST/apb_pkg.sv \
                ../TOP/apb_tb_top.sv \
                ../TOP/apb_assertions.sv

# 3. Include Directories (Space-separated; auto-converted to +incdir+)
INCDIRS      ?= ../ENV ../TEST

# 4. Testbench Top Module & Elaboration Names
TB_TOP       ?= apb_tb_top
OPT_TOP      ?= $(TB_TOP)_opt
DESIGN_BIN   ?= design.bin

# 5. Default Individual Test Name
TEST         ?= apb_base_test

# 6. Regression Test Suite
REGRESS_LIST ?= apb_write_test \
                apb_read_test \
                apb_wr_rd_test \
                apb_strb_test \
                apb_back2back_test \
                apb_reset_test \
                apb_boundary_test \
                apb_full_mem_test \
                apb_data_integrity_test

# 7. Environment & Tools Configuration
BROWSER      ?= firefox
WORK_DIR     ?= work
MERGED_UCDB  ?= merged.ucdb
COV_DIR      ?= covhtmlreport

# ==============================================================================
# COMPILER, OPTIMIZER & SIMULATOR FLAGS
# ==============================================================================
INC_FLAGS    = $(addprefix +incdir+, $(INCDIRS))
VLOG_FLAGS   = -sv +acc -coveropt 3 +cover $(INC_FLAGS)
VOPT_FLAGS   = +acc -designfile $(DESIGN_BIN) $(TB_TOP) -o $(OPT_TOP)
VSIM_FLAGS   = -assertdebug -coverage

# ==============================================================================
# PHONY TARGETS DECLARATION
# ==============================================================================
.PHONY: all comp sim gui vis_live regress regress_gui regress_vis merge cov report del vis help

all: sim

# ==============================================================================
# TARGETS & COMMANDS
# ==============================================================================

## Create working library if missing
$(WORK_DIR):
	vlib $(WORK_DIR)
	vmap work $(WORK_DIR)

## 1. Compilation & Static Elaboration
comp: $(WORK_DIR)
	@echo "//================== Compilation & Elaboration Starts ======================//"
	vlog $(VLOG_FLAGS) $(RTL) $(TB)
	vopt $(VOPT_FLAGS)
	@echo "//================= Compilation & Elaboration Complete =====================//"

## 2. Single Simulation (Batch Mode)
sim: comp
	@echo "//==================== Simulation Starts: $(TEST) =====================//"
	vsim $(VSIM_FLAGS) $(OPT_TOP) \
		-qwavedb=+assertion+signal+wavefile=$(TEST).qwave.db \
		-c -do "coverage save -onexit -directive -cvg -codeall $(TEST).ucdb; run -all; exit" \
		+TESTNAME=$(TEST)
	@echo "//==================== Simulation Ended: $(TEST) ======================//"
	@echo "QWAVE DB generated: $(TEST).qwave.db -- Run 'make vis TEST=$(TEST)' to view."

## 3. Single Simulation (Classic Questa GUI with Auto-Loaded Waves)
gui: comp
	@echo "//==================== GUI Simulation Starts: $(TEST) =====================//"
	@echo "view wave"                 >  wave.do
	@echo "view structure"            >> wave.do
	@echo "view signals"              >> wave.do
	@echo "onfinish stop"             >> wave.do
	@echo "log -r /*"                 >> wave.do
	@echo "add wave -r /*"            >> wave.do
	@echo "run -all"                  >> wave.do
	@echo "wave zoom full"            >> wave.do
	vsim -gui $(VSIM_FLAGS) $(OPT_TOP) -do wave.do +TESTNAME=$(TEST) &

## 4. Interactive Live Visualizer Simulation
vis_live: comp
	@echo "//==================== Visualizer Live Starts: $(TEST) =====================//"
	vsim -visualizer $(VSIM_FLAGS) $(OPT_TOP) \
		-qwavedb=+assertion+signal+wavefile=$(TEST).qwave.db \
		+TESTNAME=$(TEST) &

## 5. Regression Execution
regress: comp
	@echo "//==================== Regression Starts =====================//"
	@rm -f *.ucdb $(MERGED_UCDB)
	@set -e; for t in $(REGRESS_LIST); do \
		echo "--> Running Test: $$t"; \
		vsim $(VSIM_FLAGS) $(OPT_TOP) \
			-qwavedb=+assertion+signal+wavefile=$$t.qwave.db -c \
			-do "coverage save -onexit -directive -cvg -codeall $$t.ucdb; run -all; exit" \
			+TESTNAME=$$t; \
	done
	@echo "//==================== Regression Ended ======================//"
	$(MAKE) merge

## Post-Simulation Visualizer Waveform GUI
vis:
	@if [ ! -e "$(TEST).qwave.db" ]; then \
		echo "Error: $(TEST).qwave.db not found. Run 'make sim TEST=$(TEST)' first."; \
		exit 1; \
	fi
	@if [ ! -f "$(DESIGN_BIN)" ]; then \
		echo "Error: $(DESIGN_BIN) not found. Run 'make comp' first."; \
		exit 1; \
	fi
	@echo "//================ Opening Visualizer: $(TEST).qwave.db =================//"
	visualizer -designfile $(DESIGN_BIN) $(TEST).qwave.db &

## 7. Coverage Operations
merge:
	@echo "//================ Merging Coverage Files =================//"
	vcover merge $(MERGED_UCDB) *.ucdb

cov: merge
	@echo "//================ Generating Coverage Reports =================//"
	vcover report -details -html -htmldir $(COV_DIR) $(MERGED_UCDB)
	vcover report -output my_coverage_log.txt -details -cvg $(MERGED_UCDB)
	@echo "Coverage reports generated in folder '$(COV_DIR)' and file 'my_coverage_log.txt'."

# Questa Classic Coverage Viewer
regress_gui:
	@if [ ! -f "$(MERGED_UCDB)" ]; then \
		echo "Coverage file $(MERGED_UCDB) not found. Running merge..."; \
		$(MAKE) merge; \
	fi
	@echo "//================ Opening Coverage in Questa GUI =================//"
	vsim -gui -viewcov $(MERGED_UCDB) &

# Visualizer Coverage Viewer
regress_vis:
	@if [ ! -f "$(MERGED_UCDB)" ]; then \
		echo "Coverage file $(MERGED_UCDB) not found. Running merge..."; \
		$(MAKE) merge; \
	fi
	@echo "//================ Opening Coverage in Visualizer =================//"
	visualizer -viewcov $(MERGED_UCDB) &

report:
	@if [ ! -d "$(COV_DIR)" ]; then \
		echo "Error: Directory '$(COV_DIR)' does not exist. Run 'make cov' first."; \
		exit 1; \
	fi
	$(BROWSER) $(COV_DIR)/index.html &

## 8. Cleanup
del:
	@echo "//================ Cleaning Project Directory =================//"
	rm -rf $(WORK_DIR) qrun.out/ vsim.wlf qrun.log *.ucdb $(MERGED_UCDB) $(COV_DIR) \
	       transcript my_coverage_log.txt wave.do *.wlf *.qwave.db visualizer.log $(DESIGN_BIN)
	@echo "Cleanup complete."

## 9. Quick Command Reference
help:
	@echo "Available Targets:"
	@echo "  make comp        : Compile and elaborate (vopt) RTL and TB files"
	@echo "  make sim         : Run batch simulation for TEST=<testname>"
	@echo "  make gui         : Run simulation in Questa GUI with auto-waves for TEST=<testname>"
	@echo "  make vis_live    : Interactive Visualizer simulation for TEST=<testname>"
	@echo "  make vis         : Open post-sim wave in Visualizer for TEST=<testname>"
	@echo "  make regress     : Run all tests in REGRESS_LIST and merge coverage"
	@echo "  make merge       : Merge all test UCDB files into merged.ucdb"
	@echo "  make cov         : Generate HTML and text coverage reports"
	@echo "  make report      : Open HTML coverage report in browser"
	@echo "  make regress_gui : View merged coverage DB in Questa Classic GUI"
	@echo "  make regress_vis : View merged coverage DB in Siemens Visualizer"
	@echo "  make del         : Remove generated build artifacts and logs"
