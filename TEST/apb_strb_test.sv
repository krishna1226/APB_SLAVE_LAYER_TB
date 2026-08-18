`ifndef APB_STRB_TEST_SV
`define APB_STRB_TEST_SV

class apb_strb_test extends apb_base_test;

  function new(virtual apb_inf vif);
    super.new(vif);
  endfunction

  virtual function void build();
    apb_gen_strb g_h;
    super.build();
    g_h = new();
    g_h.gen_c.constraint_mode(0);
    g_h.num_trans = 1000;           // 7 PSTRB patterns x 2 (write+read)
    g_h.min_addr  = 8'h40;
    g_h.max_addr  = 8'hFE;
    g_h.min_data  = 0;
    g_h.max_data  = {`DATA_WIDTH{1'b1}};
    env_h.gen_h = g_h;
  endfunction

endclass

`endif
