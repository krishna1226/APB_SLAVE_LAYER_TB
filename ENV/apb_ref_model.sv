`ifndef APB_REF_MODEL_SV
`define APB_REF_MODEL_SV

class apb_ref_model;

    apb_trans trans_h;
    mailbox #(apb_trans) mon2ref_mbx;
    mailbox #(apb_trans) ref2sb_mbx;

    // Reference memory
    logic [`DATA_WIDTH-1:0] mem [0:`MEM_DEPTH-1];

    function void connect(mailbox #(apb_trans) mon2ref_mbx,
                          mailbox #(apb_trans) ref2sb_mbx);
        this.mon2ref_mbx = mon2ref_mbx;
        this.ref2sb_mbx  = ref2sb_mbx;
    endfunction

    task run();
        for (int i = 0; i < `MEM_DEPTH; i++) mem[i] = {`DATA_WIDTH{1'b0}};

        fork
        forever begin
            mon2ref_mbx.get(trans_h);
            predict(trans_h);
        end

        forever begin
            @(apb_pkg::global_reset_start);
            $display("[REF_MODEL] Reset event received, clearing reference memory");
            for (int i = 0; i < `MEM_DEPTH; i++) mem[i] = {`DATA_WIDTH{1'b0}};
        end
        join
    endtask 

    task predict(apb_trans trans_h);

        // Check for ADDR ERROR
        bit addr_error;
        addr_error = (trans_h.PADDR >= 255); 

        // WRITE prediction
        if (trans_h.PWRITE) begin
            trans_h.PSLVERR = addr_error;
            trans_h.PRDATA  = '0;

            if (!addr_error) begin
            // PSTRB write 
                for (int i = 0; i < `STRB_WIDTH; i++) begin
                if (trans_h.PSTRB[i])
                    mem[trans_h.PADDR][i*8 +: 8] = trans_h.PWDATA[i*8 +: 8];
                end
            end
        end

        else begin
            // READ prediction
            trans_h.PSLVERR = addr_error;

            if (!addr_error)
            trans_h.PRDATA = mem[trans_h.PADDR];

            else
            trans_h.PRDATA = '0;      // Error reads return 0
        end
          /*  $display("[REF] trans_id=%0d PADDR=0x%02h PWRITE=%0b PSTRB=4'b%4b PWDATA=4'b%4b PRDATA=4'b%4b",
                         trans_h.trans_id, trans_h.PADDR, trans_h.PWRITE, trans_h.PSTRB, trans_h.PWDATA, trans_h.PRDATA);
          */
            ref2sb_mbx.put(trans_h);
    endtask
endclass
`endif
