`ifndef APB_BASE_TEST_SV
`define APB_BASE_TEST_SV

typedef class apb_write_test;
typedef class apb_read_test;
typedef class apb_wr_rd_test;
typedef class apb_error_test;
typedef class apb_strb_test;
typedef class apb_back2back_test;
typedef class apb_reset_test;
typedef class apb_boundary_test;
typedef class apb_full_mem_test;
typedef class apb_data_integrity_test;

class apb_base_test;
  apb_env env_h;
  virtual apb_inf vif;

  function new(virtual apb_inf vif);
    this.vif = vif;
  endfunction

  virtual function void build();
    env_h = new(vif);
    env_h.build();
  endfunction

  virtual function void connect();
    env_h.connect();
  endfunction

  virtual task run();
    env_h.run();
  endtask

  // Static factory
  static function apb_base_test get_test(virtual apb_inf vif, string test_name);
    apb_write_test          w_t;
    apb_read_test           r_t;
    apb_wr_rd_test          wr_t;
    apb_error_test          e_t;
    apb_strb_test           s_t;
    apb_back2back_test      b2b_t;
    apb_reset_test          rst_t;
    apb_boundary_test       bt_t;
    apb_full_mem_test       fm_t;
    apb_data_integrity_test di_t;
    apb_base_test           b_t;

    case (test_name)
      "apb_write_test":         begin w_t   = new(vif); return w_t;   end
      "apb_read_test":          begin r_t   = new(vif); return r_t;   end
      "apb_wr_rd_test":         begin wr_t  = new(vif); return wr_t;  end
      "apb_error_test":         begin e_t   = new(vif); return e_t;   end
      "apb_strb_test":          begin s_t   = new(vif); return s_t;   end
      "apb_back2back_test":     begin b2b_t = new(vif); return b2b_t; end
      "apb_reset_test":         begin rst_t = new(vif); return rst_t; end
      "apb_boundary_test":      begin bt_t  = new(vif); return bt_t;  end
      "apb_full_mem_test":      begin fm_t  = new(vif); return fm_t;  end
      "apb_data_integrity_test":begin di_t  = new(vif); return di_t;  end
      default:                  begin b_t   = new(vif); return b_t;   end
    endcase
  endfunction

endclass

`endif
