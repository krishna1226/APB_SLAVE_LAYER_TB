`ifndef APB_PKG_SV
`define APB_PKG_SV

package apb_pkg;

  event drv_done;
  event global_reset_start;
  event global_reset_done;

  int  reset_duration  = 2;
  int  objection_count = 0;
  time drain_time      = 50ns;

  function void set_drain_time(time drain);
    drain_time = drain;
  endfunction

  function void raise_objection();
    objection_count++;
  endfunction

  function void drop_objection();
    objection_count--;
    if (objection_count < 0) begin
      $error("[OBJECTION_UNDERFLOW] Dropped more objections than raised!");
      objection_count = 0;
    end
  endfunction

  task wait_for_clear();
    wait(objection_count == 0);
    if (drain_time > 0ns) begin
      $display("[OBJECTION] All objections dropped. Entering drain window: %0t", drain_time);
      #(drain_time);
    end
  endtask

  // Defines and base classes
  `include "apb_define.sv"
  `include "apb_sequence_item.sv"
  `include "apb_trans.sv"

  // Functional coverage
  `include "apb_coverage.sv"

  // Generators
  `include "apb_gen.sv"
  `include "apb_gen_wr_rd.sv"
  `include "apb_gen_back2back.sv"
  `include "apb_gen_strb.sv"
  `include "apb_gen_boundary.sv"
  `include "apb_gen_full_mem.sv"
  `include "apb_gen_data_integrity.sv"

  // Environment components
  `include "apb_driver.sv"
  `include "apb_monitor.sv"
  `include "apb_ref_model.sv"
  `include "apb_scoreboard.sv"
  `include "apb_env.sv"

  // Tests
  `include "apb_base_test.sv"
  `include "apb_write_test.sv"
  `include "apb_read_test.sv"
  `include "apb_wr_rd_test.sv"
  `include "apb_error_test.sv"
  `include "apb_strb_test.sv"
  `include "apb_back2back_test.sv"
  `include "apb_boundary_test.sv"
  `include "apb_full_mem_test.sv"
  `include "apb_data_integrity_test.sv"
  `include "apb_reset_test.sv"
endpackage
`endif
