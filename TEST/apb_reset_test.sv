`ifndef APB_RESET_TEST_SV
`define APB_RESET_TEST_SV

class apb_reset_test extends apb_base_test;

  function new(virtual apb_inf vif);
    super.new(vif);
  endfunction

  virtual function void build();
    apb_gen_wr_rd g_h;
    super.build();
    g_h = new();
    g_h.gen_c.constraint_mode(0);
    g_h.num_trans = 100;
    g_h.min_addr  = 0;
    g_h.max_addr  = {`ADDR_WIDTH{1'b1}};
    g_h.min_data  = 0;
    g_h.max_data  = {`DATA_WIDTH{1'b1}};
    env_h.gen_h = g_h;
  endfunction

  virtual task run();
    fork
      super.run();
      begin
        repeat(10)begin
            // Trigger mid-way reset after 4 transactions complete
            repeat(4) @(apb_pkg::drv_done);
            $display("[RESET_TEST] Triggering mid-way reset at time %0t", $time);
            -> apb_pkg::global_reset_start;
            apb_pkg::reset_duration = 4;
            @(apb_pkg::global_reset_done);
            $display("[RESET_TEST] Reset released. Resuming at time %0t", $time);
        end
      end
    join
  endtask

endclass

`endif
