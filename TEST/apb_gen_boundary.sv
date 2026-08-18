`ifndef APB_GEN_BOUNDARY_SV
`define APB_GEN_BOUNDARY_SV

class apb_gen_boundary extends apb_gen;

        virtual task run();
            bit [`ADDR_WIDTH-1:0] bnd_addrs[12]  = '{8'h00,8'h01,8'h02,8'h03,8'h04,8'h05,8'hFA,8'hFB,8'hFC,8'hFD,8'hFE,8'hFF};
            bit [`DATA_WIDTH-1:0] patterns[14]   = '{32'h0000_0000,32'h0000_0001,32'h0000_0002,32'h0000_0003,32'h0000_0004,32'h0000_0005,
                                                    32'hFFFF_FFFA,32'hFFFF_FFFB,32'hFFFF_FFFC,32'hFFFF_FFFD,32'hFFFF_FFFE,32'hFFFF_FFFF,
                                                    32'hA5A5_A5A5, 32'h5A5A_5A5A};
        foreach (bnd_addrs[a]) begin
            foreach (patterns[p]) begin
            // WRITE 
            apb_pkg::raise_objection();
            req = new();
            if (!req.randomize() with {
                PWRITE == 1;
                PSTRB  == 8'hF;
                PADDR  == bnd_addrs[a];
                PWDATA == patterns[p];
                }) $fatal(1, "[GEN_BOUNDARY_FATAL] WRITE randomization failed!");
                //$display("[GEN_BOUNDARY] @%0t WRITE trans_id=%0d PADDR=0x%02h PWDATA=0x%08h",
                //          $time, req.trans_id, req.PADDR, req.PWDATA);
                req_copy = new();
                req_copy.copy(req);
                gen2drv_mbx.put(req_copy);
                @(apb_pkg::drv_done);

            // READ 
            apb_pkg::raise_objection();
            req = new();
            if (!req.randomize() with {
                PWRITE == 0;
                PWDATA == 0;
                PADDR  == bnd_addrs[a];
                }) $fatal(1, "[GEN_BOUNDARY_FATAL] READ randomization failed!");
                //$display("[GEN_BOUNDARY] READ @%0t  trans_id=%0d PADDR=0x%02h",
                //         $time, req.trans_id, req.PADDR);
                req_copy = new();
                req_copy.copy(req);
                gen2drv_mbx.put(req_copy);
                @(apb_pkg::drv_done);
            end
        end
    endtask
endclass

`endif
