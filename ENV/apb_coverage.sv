`ifndef APB_COVERAGE_SV
`define APB_COVERAGE_SV

class apb_coverage;

    // Sampled transaction fields
    bit                   txn_pwrite;
    bit [`ADDR_WIDTH-1:0] txn_paddr;
    bit [`DATA_WIDTH-1:0] txn_pwdata;
    bit [`DATA_WIDTH-1:0] txn_prdata;
    bit [`STRB_WIDTH-1:0] txn_pstrb;
    bit                   txn_pslverr;
    bit                   txn_result;   // 0 = MATCH, 1 = MISMATCH
    int                   txn_wait_count;   // Wait-state count (0-MAX_WAIT)
    bit                   txn_same_addr;    // Back-to-back same address flag
    bit                   txn_wr_rd_same;   // Write-then-read to same address flag

    // Previous transaction state for transition/back-to-back tracking
    bit                   prev_valid;
    bit                   prev_pwrite;
    bit [`ADDR_WIDTH-1:0] prev_paddr;

    // Covergroup 1: Transaction type 
    covergroup transaction_cg;
        cp_dir: coverpoint txn_pwrite {
            bins write = {1'b1};
            bins read  = {1'b0};
        }
/*      cp_result: coverpoint txn_result {
            bins match    = {1'b0};
            bins mismatch = {1'b1};
        }*/
        cp_error: coverpoint txn_pslverr {
            bins no_error = {1'b0};
            bins error    = {1'b1};
        }
        //cx_dir_result: cross cp_dir, cp_result;
        cx_dir_error:  cross cp_dir, cp_error;
    endgroup

    // Covergroup 2: Address space
    covergroup address_cg;
        cp_addr: coverpoint txn_paddr {
            bins addr_zero    = {0};
            bins addr_low     = {[1:63]};
            bins addr_mid     = {[64:191]};
            bins addr_high    = {[192:253]};
            bins addr_max     = {8'hFE};
        }
    endgroup

    // Covergroup 3: Data patterns
    covergroup data_cg;
    cp_wdata: coverpoint txn_pwdata iff (txn_pwrite) {
      bins data_zero = {32'h0};
      bins data_low  = {[32'h1       : 32'hFF]};
      bins data_mid  = {[32'h100     : 32'hFFFF]};
      bins data_high = {[32'h1_0000  : 32'hFFFF_FFFE]};
      bins data_max  = {32'hFFFF_FFFF};
    }
    cp_rdata: coverpoint txn_prdata iff (!txn_pwrite) {
      bins data_zero = {32'h0};
      bins data_low  = {[32'h1       : 32'hFF]};
      bins data_mid  = {[32'h100     : 32'hFFFF]};
      bins data_high = {[32'h1_0000  : 32'hFFFF_FFFE]};
      bins data_max  = {32'hFFFF_FFFF};
    }
  endgroup

  // Covergroup 4: Strobe patterns 
  covergroup strobe_cg;
    cp_strb: coverpoint txn_pstrb iff (txn_pwrite) {
      bins all_bytes   = {4'b1111};
      bins byte_0_only = {4'b0001};
      bins byte_1_only = {4'b0010};
      bins byte_2_only = {4'b0100};
      bins byte_3_only = {4'b1000};
      bins lower_half  = {4'b0011};
      bins upper_half  = {4'b1100};
      bins upper_3     = {4'b1110};
      bins lower_3     = {4'b0111};
      bins others      = default;
    }
  endgroup

  // Covergroup 5: Transaction transitions
  covergroup transition_cg;
    cp_dir_trans: coverpoint txn_pwrite {
      bins write_then_read  = (1'b1 => 1'b0);
      bins read_then_write  = (1'b0 => 1'b1);
      bins write_then_write = (1'b1 => 1'b1);
      bins read_then_read   = (1'b0 => 1'b0);
    }
  endgroup

  // Covergroup 6: Wait-State / PREADY Coverage
  // DUT derives wait states from PADDR[3:2], clamped to MAX_WAIT. We compute the expected wait count in the sample() function.
  covergroup waitstate_cg;

    cp_wait_states: coverpoint txn_wait_count {
      bins zero_wait  = {0};
      bins one_wait   = {1};
      bins two_wait   = {2};
      bins three_wait = {3};
    }

    cp_ready_dir: coverpoint txn_pwrite {
      bins write = {1'b1};
      bins read  = {1'b0};
    }

    // Cross: all wait durations exercised for both read and write
    cx_wait_x_dir: cross cp_wait_states, cp_ready_dir;

  endgroup

  // Constructor
  function new();
    transaction_cg = new();
    address_cg     = new();
    data_cg        = new();
    strobe_cg      = new();
    transition_cg  = new();
    waitstate_cg   = new();

    prev_valid     = 1'b0;
    prev_pwrite    = 1'b0;
    prev_paddr     = '0;
  endfunction

// Sample all covergroups
  function void sample(apb_trans act, bit is_match);
    txn_pwrite  = act.PWRITE;
    txn_paddr   = act.PADDR;
    txn_pwdata  = act.PWDATA;
    txn_prdata  = act.PRDATA;
    txn_pstrb   = act.PSTRB;
    txn_pslverr = act.PSLVERR;
    txn_result  = is_match ? 1'b0 : 1'b1;

    // Compute wait-state count from address bits [3:2], clamped to MAX_WAIT
    begin
      int raw_waits;
      raw_waits = txn_paddr[3:2];
      txn_wait_count = (raw_waits > `MAX_WAIT) ? `MAX_WAIT : raw_waits;
    end

    // Compute back-to-back flags
    if (prev_valid) begin
      txn_same_addr  = (txn_paddr == prev_paddr);
      txn_wr_rd_same = (prev_pwrite == 1'b1) && (txn_pwrite == 1'b0) && (txn_paddr == prev_paddr);
    end else begin
      txn_same_addr  = 1'b0;
      txn_wr_rd_same = 1'b0;
    end

    // Sample all covergroups
    transaction_cg.sample();
    address_cg.sample();
    data_cg.sample();
    strobe_cg.sample();
    transition_cg.sample();
    waitstate_cg.sample();

    // Update previous transaction state for next call
    prev_valid  = 1'b1;
    prev_pwrite = txn_pwrite;
    prev_paddr  = txn_paddr;
  endfunction

  // Print coverage summary
  function void report();
    real overall;
    overall = (transaction_cg.get_coverage() + address_cg.get_coverage() +
               data_cg.get_coverage()        + strobe_cg.get_coverage() +
               transition_cg.get_coverage()  + waitstate_cg.get_coverage()) / 6.0;

    $display("\n================================================================================");
    $display("                          FUNCTIONAL COVERAGE REPORT                             ");
    $display("================================================================================");
    $display("  Transaction Coverage : %.2f%%", transaction_cg.get_coverage());
    $display("  Address Coverage     : %.2f%%", address_cg.get_coverage());
    $display("  Data Coverage        : %.2f%%", data_cg.get_coverage());
    $display("  Strobe Coverage      : %.2f%%", strobe_cg.get_coverage());
    $display("  Transition Coverage  : %.2f%%", transition_cg.get_coverage());
    $display("  Wait-State Coverage  : %.2f%%", waitstate_cg.get_coverage());
    $display("--------------------------------------------------------------------------------");
    $display("  OVERALL COVERAGE     : %.2f%%", overall);
    $display("================================================================================");
  endfunction

endclass

`endif
