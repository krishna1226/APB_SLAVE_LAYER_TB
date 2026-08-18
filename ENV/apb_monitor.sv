`ifndef APB_MONITOR_SV
`define APB_MONITOR_SV

class apb_monitor;

    mailbox #(apb_trans) mon2ref_mbx;
    mailbox #(apb_trans) mon2sb_mbx;
    virtual apb_inf.MONITOR vif;

    function void connect(mailbox #(apb_trans) mon2ref_mbx,
                          mailbox #(apb_trans) mon2sb_mbx,
                         virtual apb_inf.MONITOR vif);
        this.mon2ref_mbx = mon2ref_mbx;
        this.mon2sb_mbx  = mon2sb_mbx;
        this.vif         = vif;
    endfunction

    task run();
        forever begin
        fork
            run_monitor();
            @(vif.mon_cb iff (vif.PRESETn === 1'b0));   // reset assert check
        join_any
        disable fork;

        $display("[MON] Reset asserted stopping @ %0t", $time);
        @(vif.mon_cb iff (vif.PRESETn === 1'b1)); // reset deassert check
        $display("[MON] Reset deasserted resuming @ %0t", $time);
        end
    endtask

    task run_monitor();
        forever begin
        @(vif.mon_cb iff (vif.PRESETn  === 1'b1 &&
                        vif.mon_cb.PSEL    === 1'b1 &&
                        vif.mon_cb.PENABLE === 1'b1 &&
                        vif.mon_cb.PREADY  === 1'b1));

        dispatch(vif.mon_cb.PWRITE);
        end
    endtask

    task dispatch(logic pwrite);
    apb_trans ref_pkt = new();
    apb_trans sb_pkt  = new();
    apb_pkg::raise_objection();

    if (pwrite) begin
        // Write: all signals are valid on the PREADY edge
        ref_pkt.PADDR  = vif.mon_cb.PADDR;
        ref_pkt.PWRITE = 1'b1;
        ref_pkt.PWDATA = vif.mon_cb.PWDATA;
        ref_pkt.PSTRB  = vif.mon_cb.PSTRB;
        ref_pkt.PREADY = vif.mon_cb.PREADY;

        sb_pkt.PADDR   = vif.mon_cb.PADDR;
        sb_pkt.PWRITE  = 1'b1;
        sb_pkt.PWDATA  = vif.mon_cb.PWDATA;
        sb_pkt.PSTRB   = vif.mon_cb.PSTRB;
        sb_pkt.PSLVERR = vif.mon_cb.PSLVERR;
        sb_pkt.PREADY  = vif.mon_cb.PREADY;
    end
    else begin
        // Capture everything except PRDATA on the PREADY edge
        sb_pkt.PADDR   = vif.mon_cb.PADDR;
        sb_pkt.PWRITE  = 1'b0;
        sb_pkt.PSLVERR = vif.mon_cb.PSLVERR;
        sb_pkt.PREADY  = vif.mon_cb.PREADY;

        ref_pkt.PADDR  = vif.mon_cb.PADDR;
        ref_pkt.PWRITE = 1'b0;
        ref_pkt.PREADY = vif.mon_cb.PREADY;

        @(vif.mon_cb);
        sb_pkt.PRDATA = vif.mon_cb.PRDATA;
    end

        mon2ref_mbx.put(ref_pkt);
        mon2sb_mbx.put(sb_pkt);
        apb_pkg::drop_objection();
    endtask
endclass
`endif
