# APB Slave Verification Testbench  SystemVerilog

A fully constrained-random, layered SystemVerilog testbench for an **AMBA APB (Advanced Peripheral Bus) Slave** design.  
Verified with **QuestaSim / ModelSim** using functional coverage, SVA assertions, and a self-checking scoreboard.

---

## Coverage Results

| Metric                                   |   Result |
|------------------------------------------|----------|
| **Functional Coverage**                  | **100%** |
| **DUT Code Coverage** (without exclusion)|  **88%** |

---

## Architecture

```
+--------------------------------------------------------------------+
|                         apb_tb_top.sv                              |
|  +--------------------------------------------------------------+  |
|  |                      apb_env                                 |  |
|  |                                                              |  |
|  |  +-----------+   gen2drv   +-----------+                     |  |
|  |  |  apb_gen  |----mbx----->| apb_driver|                     |  |
|  |  +-----------+             +-----+-----+                     |  |
|  |                                  | drives                    |  |
|  |                            +-----v-----+                     |  |
|  |                            |  apb_inf  |<------ DUT          |  |
|  |                            +-----+-----+   apb_slave.v       |  |
|  |                                  | samples                   |  |
|  |  +------------+  mon2ref  +------v------+                    |  |
|  |  | apb_ref_   |<---mbx---|  apb_monitor|                     |  |
|  |  | model      |           +------+------+                    |  |
|  |  +-----+------+                  | mon2sb                    |  |
|  |        | ref2sb                  |                           |  |
|  |        +----------+  +-----------+                           |  |
|  |                   v  v                                       |  |
|  |             +-------------+  +--------------+                |  |
|  |             |apb_scoreboard|  | apb_coverage |               |  |
|  |             +-------------+  +--------------+                |  |
|  +-----------------------------------------------------------------+
|                    apb_assertions.sv (bind)                        |
+--------------------------------------------------------------------+
```

---

## Directory Structure

```
APB/
+-- RTL/
|   +-- apb_slave.v              # DUT - APB Slave (parameterized, wait-state, PSLVERR)
+-- ENV/
|   +-- apb_define.sv            # Global defines (widths, depth, wait)
|   +-- apb_inf.sv               # APB interface with driver/monitor clocking blocks
|   +-- apb_sequence_item.sv     # Abstract base class for transactions
|   +-- apb_trans.sv             # Transaction class (randomizable fields + constraints)
|   +-- apb_gen.sv               # Base generator
|   +-- apb_driver.sv            # APB protocol driver (back-to-back chaining + reset handling)
|   +-- apb_monitor.sv           # Bus monitor - captures completed transfers
|   +-- apb_ref_model.sv         # Reference memory model (mirrors DUT behaviour)
|   +-- apb_scoreboard.sv        # Self-checking scoreboard (match/mismatch tracking)
|   +-- apb_coverage.sv          # 6-covergroup functional coverage collector
|   +-- apb_env.sv               # Environment - wires all components, runs simulation
+-- TEST/
|   +-- apb_pkg.sv               # Package - includes all files, objection model, events
|   +-- apb_base_test.sv         # Base test + static factory for test selection
|   +-- apb_gen_wr_rd.sv         # Mixed write/read generator
|   +-- apb_gen_back2back.sv     # Back-to-back burst generator
|   +-- apb_gen_strb.sv          # Byte-strobe pattern generator
|   +-- apb_gen_boundary.sv      # Address boundary generator
|   +-- apb_gen_full_mem.sv      # Full memory sweep generator
|   +-- apb_gen_data_integrity.sv# Write-then-read data integrity generator
|   +-- apb_write_test.sv        # Directed write test
|   +-- apb_read_test.sv         # Directed read test
|   +-- apb_wr_rd_test.sv        # Mixed write/read test
|   +-- apb_error_test.sv        # Out-of-bound address / PSLVERR test *
|   +-- apb_strb_test.sv         # Byte-strobe coverage test
|   +-- apb_back2back_test.sv    # Back-to-back burst test
|   +-- apb_boundary_test.sv     # Address boundary test
|   +-- apb_full_mem_test.sv     # Full memory fill test
|   +-- apb_data_integrity_test.sv# Write-then-read integrity test
|   +-- apb_reset_test.sv        # Mid-simulation reset stress test
+-- TOP/
|   +-- apb_tb_top.sv            # Testbench top - clock, reset, DUT, test factory
|   +-- apb_assertions.sv        # 12 SVA properties (bound to DUT)
+-- SIM/
    +-- makefile                 # Questa Makefile - compile, sim, regression, coverage
```

> **\*** `apb_error_test` requires `MEM_DEPTH` to be set to `240` in `apb_define.sv` before running,
> so that out-of-bound addresses (>= 255) are reachable and `PSLVERR` is triggered correctly.

---

## Features

- **APB Protocol Compliance**  FSM with IDLE -> SETUP -> ACCESS states, wait-state support (up to `MAX_WAIT` = 3 cycles derived from `PADDR[3:2]`), `PSLVERR` for out-of-bound addresses
- **Parameterized DUT**  `ADDR_WIDTH`, `DATA_WIDTH`, `STRB_WIDTH`, `MEM_DEPTH`, `MAX_WAIT`
- **Constrained-Random Stimulus**  6 specialised generators, all extending `apb_gen`
- **Back-to-Back Transfer Chaining**  driver chains consecutive transactions without idle cycles between them
- **Mid-Simulation Reset**  reset test triggers `PRESETn` asynchronously up to 10 times, validating in-flight transaction dropping and bus recovery
- **Byte-Strobe Writes**  all 15 non-zero `PSTRB` combinations exercised and verified
- **Self-Checking Scoreboard**  expected vs actual comparison for every completed transfer
- **Reference Model**  cycle-accurate memory model that mirrors DUT write/read behaviour including strobe masking
- **Functional Coverage**  6 covergroups: transaction type, address space, data patterns, strobe patterns, direction transitions, wait-state x direction cross
- **12 SVA Assertions**  protocol rule checks: no-X on control signals, setup->access handshake, signal stability (PSEL, PWRITE, PADDR, PWDATA, PSTRB), PSLVERR on OOB, bounded ACCESS duration, reset output clearing

---

## Test Suite

| Test |      Generator     | Description                                                                                |
|------|--------------------|--------------------------------------------------------------------------------------------|
| `apb_write_test`          | `apb_gen`   (WRITE_ONLY) | 5 random write transactions                                     |
| `apb_read_test`           | `apb_gen`    (READ_ONLY) | 5 random read transactions                                      |
| `apb_wr_rd_test`          | `apb_gen_wr_rd`          | 1000 interleaved writes and reads                               |
| `apb_error_test`          | `apb_gen_wr_rd`          | Transactions targeting PADDR >= 255 to trigger PSLVERR          |
| `apb_strb_test`           | `apb_gen_strb`           | All 15 non-zero PSTRB patterns                                  |
| `apb_back2back_test`      | `apb_gen_back2back`      | 1000 back-to-back burst transfers (10W + 10R to same addresses) |
| `apb_boundary_test`       | `apb_gen_boundary`       | Addresses at 0x00, 0x3F, 0xBF, 0xFE boundaries                  |
| `apb_full_mem_test`       | `apb_gen_full_mem`       | Sequential write then read of all 254 memory locations          |
| `apb_data_integrity_test` | `apb_gen_data_integrity` | Write unique patterns then verify every byte strobe lane        |
| `apb_reset_test`          | `apb_gen_wr_rd`          | 100 transactions with 10 mid-simulation resets every 4 transfers|

---

## Quick Start

### Prerequisites

- **QuestaSim / ModelSim** (Siemens EDA)  `vlog`, `vopt`, `vsim` must be on PATH

### Compile and Run a Single Test

```bash
cd SIM/

# Compile + simulate default test
make sim

# Compile + simulate a specific test
make sim TEST=apb_wr_rd_test

# Open in GUI with waveforms auto-loaded
make gui TEST=apb_strb_test
```

### Run Full Regression

```bash
make regress      # Runs all 9 tests and merges coverage UCDBs
make cov          # Generates HTML coverage report + text log
make report       # Opens HTML report in browser
```

### View Waveforms (Post-Sim)

```bash
make vis TEST=apb_back2back_test
```

### Clean Build Artifacts

```bash
make del
```

---

## Makefile Targets

| Target                      | Description                                  |
|-----------------------------|----------------------------------------------|
| `make comp`                 | Compile RTL + TB and elaborate with vopt     |
| `make sim TEST=<name>`      | Batch simulation for one test                |
| `make gui TEST=<name>`      | Questa GUI simulation with auto-loaded waves |
| `make vis_live TEST=<name>` | Interactive Visualizer simulation (live)     |
| `make vis TEST=<name>`      | Open post-sim waveform in Visualizer         |
| `make regress`              | Run all tests and merge coverage             |
| `make merge`                | Merge individual .ucdb files into merged.ucdb|
| `make cov`                  | Generate HTML + text coverage reports        |
| `make report`               | Open HTML coverage report in browser         |
| `make regress_gui`          | View merged coverage in Questa Classic GUI   |
| `make regress_vis`          | View merged coverage in Visualizer           |
| `make del`                  | Remove all generated build artifacts         |

---

## Functional Coverage Details

| Covergroup       | Description                                          | Result |
|------------------|--------------------------------------------------------|------|
| `transaction_cg` | Write / Read x Error / No-Error cross coverage         | 100% |
| `address_cg`     | Five address bins: zero, low, mid, high, max (0xFE)    | 100% |
| `data_cg`        | Five data bins for PWDATA (writes) and PRDATA (reads)  | 100% |
| `strobe_cg`      | 9 named PSTRB patterns + default catch-all             | 100% |
| `transition_cg`  | W->R, R->W, W->W, R->R direction transition sequences  | 100% |
| `waitstate_cg`   | 0-3 wait states x Write/Read direction (cross)         | 100% |
| **Overall**      |                                                    | **100%** |

---

## DUT Code Coverage

| Metric | Coverage |
|--------|----------|
| Statement | 88% |
| Branch | 88% |
| **Total (no exclusions)** | **88%** |

The uncovered 12% corresponds to unreachable default FSM branches and reset-guard logic paths that require glitch injection beyond the scope of a protocol-level testbench.
