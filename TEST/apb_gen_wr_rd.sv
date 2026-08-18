`ifndef APB_GEN_WR_RD_SV
`define APB_GEN_WR_RD_SV
class apb_gen_wr_rd extends apb_gen;
    
    virtual task run();
        int pairs = num_trans / 2;
        logic [`ADDR_WIDTH-1:0] target_addr;
        
        repeat (pairs) begin
            // WRITE 
            apb_pkg::raise_objection();
            req = new();
            if (!req.randomize() with {
                PWRITE == 1;
                PSTRB  != 0;
                PADDR  >= local::this.min_addr;
                PADDR  <= local::this.max_addr;
                PADDR  <  `MEM_DEPTH;
                PWDATA >= local::this.min_data;
                PWDATA <= local::this.max_data;
                }) $fatal(1, "[GEN_WR_RD_FATAL] WRITE randomization failed!");
                target_addr = req.PADDR;
                //$display("[GEN_WR_RD] @%0t WRITE trans_id=%0d PADDR=0x%02h PWDATA=0x%08h",
                //         $time, req.trans_id, req.PADDR, req.PWDATA);
                req_copy = new();
                req_copy.copy(req);
                gen2drv_mbx.put(req_copy);
                @(apb_pkg::drv_done);

            // READ back same address
            apb_pkg::raise_objection();
            req = new();
            if (!req.randomize() with {
                PWRITE == 0;
                PWDATA == 0;
                PADDR  == local::target_addr;
                }) $fatal(1, "[GEN_WR_RD_FATAL] READ randomization failed!");
                //$display("[GEN_WR_RD] READ @%0t  trans_id=%0d PADDR=0x%02h",
                //         $time, req.trans_id, req.PADDR);
                req_copy = new();
                req_copy.copy(req);
                gen2drv_mbx.put(req_copy);
                @(apb_pkg::drv_done);

            end
            $display("[GEN_WR_RD] Done %0d write-read pairs completed", pairs);
    endtask
endclass
`endif
