`ifndef APB_WR_RD_TEST_SV
`define APB_WR_RD_TEST_SV

class apb_wr_rd_test extends apb_base_test;

  function new(virtual apb_inf vif);
    super.new(vif);
  endfunction

  virtual function void build();
    apb_gen_wr_rd g_h;
    super.build();
    g_h = new();
    g_h.gen_c.constraint_mode(0);
    g_h.num_trans = 1000;           // 5 write-read pairs
    g_h.min_addr  = 0;
    g_h.max_addr  = {`ADDR_WIDTH{1'b1}};
    g_h.min_data  = 0;
    g_h.max_data  = {`DATA_WIDTH{1'b1}};
    env_h.gen_h = g_h;
  endfunction

endclass

`endif
