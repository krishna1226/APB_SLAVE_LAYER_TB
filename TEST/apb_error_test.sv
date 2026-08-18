`ifndef APB_ERROR_TEST_SV
`define APB_ERROR_TEST_SV

// NOTE: Reduce MEM_DEPTH in apb_define.sv to exercise error paths.

class apb_error_test extends apb_base_test;

  function new(virtual apb_inf vif);
    super.new(vif);
  endfunction

  virtual function void build();
    apb_gen_wr_rd g_h;
    super.build();
    g_h = new();
    g_h.gen_c.constraint_mode(0);
    g_h.num_trans = 40;
    g_h.min_addr  = 8'hFA;
    g_h.max_addr  = {`ADDR_WIDTH{1'b1}};
    g_h.min_data  = 0;
    g_h.max_data  = {`DATA_WIDTH{1'b1}};
    env_h.gen_h = g_h;
  endfunction

endclass

`endif
