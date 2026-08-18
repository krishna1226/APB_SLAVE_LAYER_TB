`ifndef APB_DATA_INTEGRITY_TEST_SV
`define APB_DATA_INTEGRITY_TEST_SV

class apb_data_integrity_test extends apb_base_test;

    function new(virtual apb_inf vif);
        super.new(vif);
    endfunction

    virtual function void build();
        apb_gen_data_integrity g_h;
        super.build();
        g_h = new();
        g_h.gen_c.constraint_mode(0);
        g_h.num_trans = 2 * `MEM_DEPTH;   // 256 writes + 256 reads = 512
        g_h.min_data  = 0;
        g_h.max_data  = {`DATA_WIDTH{1'b1}};
        env_h.gen_h = g_h;
    endfunction
endclass

`endif
