`ifndef APB_WRITE_TEST_SV
`define APB_WRITE_TEST_SV

class apb_write_test extends apb_base_test;

  function new(virtual apb_inf vif);
    super.new(vif);
  endfunction

  virtual function void build();
    apb_gen g_h;
    super.build();
    g_h = new();
    g_h.gen_c.constraint_mode(0);
    g_h.num_trans = 5;
    g_h.gen_mode  = WRITE_ONLY;
    g_h.min_addr  = 0;
    g_h.max_addr  = 3;
    g_h.min_data  = 10;
    g_h.max_data  = 500;
    env_h.gen_h = g_h;
  endfunction

endclass

`endif
