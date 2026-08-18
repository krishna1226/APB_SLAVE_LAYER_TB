`ifndef APB_ENV_SV
`define APB_ENV_SV

class apb_env;

    apb_gen        gen_h;
    apb_driver     drv_h;
    apb_monitor    mon_h;
    apb_ref_model  ref_h;
    apb_scoreboard sb_h;

    mailbox #(apb_trans) gen2drv_mbx;
    mailbox #(apb_trans) mon2ref_mbx;
    mailbox #(apb_trans) ref2sb_mbx;
    mailbox #(apb_trans) mon2sb_mbx;

    virtual apb_inf vif;

    function new(virtual apb_inf vif);
        this.vif = vif;
    endfunction

    function void build();
        if (gen_h == null) begin
        gen_h = new();
        end
        drv_h = new();
        mon_h = new();
        ref_h = new();
        sb_h  = new();

        gen2drv_mbx = new();
        mon2ref_mbx = new();
        ref2sb_mbx  = new();
        mon2sb_mbx  = new();
    endfunction

    virtual function void connect();
        gen_h.connect(gen2drv_mbx);
        drv_h.connect(gen2drv_mbx, vif);
        mon_h.connect(mon2ref_mbx, mon2sb_mbx, vif);
        ref_h.connect(mon2ref_mbx, ref2sb_mbx);
        sb_h.connect(mon2sb_mbx, ref2sb_mbx);
    endfunction

    task run();
        fork
            gen_h.run();
            drv_h.run();
            mon_h.run();
            ref_h.run();
            sb_h.run();
    join_none

        fork
            begin
                wait(gen_h.num_trans == (sb_h.match_count + sb_h.mismatch_count
                                 + drv_h.dropped_count));
                apb_pkg::wait_for_clear();
                $display("[ENV] All transactions completed with a clean drain window.");
            end
            begin
                #50000ns;
                $warning("[ENV_TIMEOUT] Simulation forcefully timed out!");
            end
        join_any
        disable fork;
    endtask
endclass
`endif
