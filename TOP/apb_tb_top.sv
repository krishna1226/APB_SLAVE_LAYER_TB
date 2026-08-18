`include "apb_define.sv"

module apb_tb_top();

  import apb_pkg::*;

  bit   PCLK;
  logic PRESETn;

  always #5 PCLK = ~PCLK;

  // Interface instantiation
  apb_inf vif(.PCLK(PCLK), .PRESETn(PRESETn));

  // DUT instantiation
  apb_slave #(
    .ADDR_WIDTH (`ADDR_WIDTH),
    .DATA_WIDTH (`DATA_WIDTH),
    .STRB_WIDTH (`STRB_WIDTH),
    .MEM_DEPTH  (`MEM_DEPTH),
    .MAX_WAIT   (`MAX_WAIT)
  ) DUT (
    .PCLK    (PCLK),
    .PRESETn (PRESETn),
    .PADDR   (vif.PADDR),
    .PSEL    (vif.PSEL),
    .PENABLE (vif.PENABLE),
    .PWRITE  (vif.PWRITE),
    .PWDATA  (vif.PWDATA),
    .PSTRB   (vif.PSTRB),
    .PRDATA  (vif.PRDATA),
    .PREADY  (vif.PREADY),
    .PSLVERR (vif.PSLVERR)
  );

    // Assertions module instantiate
    bind apb_slave apb_assertions #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DATA_WIDTH(`DATA_WIDTH),
        .STRB_WIDTH(`STRB_WIDTH),
        .MAX_DEPTH (`MEM_DEPTH),
        .MAX_WAIT  (`MAX_WAIT)
    ) assert_h (
        .PCLK   (vif.PCLK),
        .PRESETn(vif.PRESETn),
        .PADDR  (vif.PADDR),
        .PSEL   (vif.PSEL),
        .PENABLE(vif.PENABLE),
        .PWRITE (vif.PWRITE),
        .PWDATA (vif.PWDATA),
        .PSTRB  (vif.PSTRB),
        .PRDATA (vif.PRDATA),
        .PREADY (vif.PREADY),
        .PSLVERR(vif.PSLVERR)
    );

    apb_base_test test_h;
    string        test_name;

    // Reset handler
    initial begin
        forever begin
            @(apb_pkg::global_reset_start);
            PRESETn = 1'b0;
            begin
                automatic int cycles = (apb_pkg::reset_duration < 2) ? 2 : apb_pkg::reset_duration;
                repeat(cycles) @(posedge PCLK);
            end
            PRESETn = 1'b1;
            -> apb_pkg::global_reset_done;
        end
    end

    initial begin
        -> apb_pkg::global_reset_start;
        @(apb_pkg::global_reset_done);

        if (!$value$plusargs("TESTNAME=%s", test_name)) begin
            $display("[TB_TOP] No +TESTNAME provided. Defaulting to apb_base_test.");
            test_name = "apb_base_test";
        end

        test_h = apb_base_test::get_test(vif, test_name);

        if (test_h == null) begin
            $fatal(1, "[TB_TOP_FATAL] Test allocation failed for: %s", test_name);
        end

        $display("[TB_TOP] Executing test: %s", test_name);

        test_h.build();
        test_h.connect();
        test_h.run();

         $finish;
    end

    // Final report 
    // By --> AI
    final begin
        automatic bit   sb_ok  = (test_h != null && test_h.env_h != null && test_h.env_h.sb_h != null);
        automatic bit   drv_ok = (test_h != null && test_h.env_h != null && test_h.env_h.drv_h != null);
        automatic int   total_matches    = sb_ok  ? test_h.env_h.sb_h.match_count      : 0;
        automatic int   total_mismatches = sb_ok  ? test_h.env_h.sb_h.mismatch_count   : 0;
        automatic int   drv_dropped      = drv_ok ? test_h.env_h.drv_h.dropped_count   : 0;
        automatic int   leftover_actual  = sb_ok  ? test_h.env_h.sb_h.actual_q.size()  : 0;
        automatic int   leftover_expected= sb_ok  ? test_h.env_h.sb_h.expected_q.size(): 0;
        automatic bit   passed = (total_mismatches == 0 && total_matches > 0 && leftover_actual == 0 && leftover_expected == 0);

        if (sb_ok) begin test_h.env_h.sb_h.final_check(); test_h.env_h.sb_h.report(); end

        $display("\n================================================================================");
        $display("                        SIMULATION REPORT SUMMARY                              ");
        $display("================================================================================");
        $display("  TEST EXECUTED      : %s",  test_name);
        $display("  TOTAL MATCHES      : %0d", total_matches);
        $display("  TOTAL MISMATCHES   : %0d", total_mismatches);
        $display("  TRANS DROPPED      : %0d", drv_dropped);
        $display("  LEFTOVER ACTUAL_Q  : %0d", leftover_actual);
        $display("  LEFTOVER EXPECTED_Q: %0d", leftover_expected);
        $display("--------------------------------------------------------------------------------");
        $display("  FINAL STATUS       : [%s]", passed ? "PASSED" : "FAILED");

        if (!passed) begin
        if (total_mismatches > 0)  $display("    -> %0d mismatches detected",              total_mismatches);
        if (total_matches    == 0) $display("    -> No transactions matched (0 matches)");
        if (leftover_actual  > 0)  $display("    -> actual_q has %0d unmatched entries",  leftover_actual);
        if (leftover_expected > 0) $display("    -> expected_q has %0d unmatched entries", leftover_expected);
        end
        $display("================================================================================");
    end
endmodule
