/*
`ifndef APB_GEN_BACK2BACK_SV
`define APB_GEN_BACK2BACK_SV

class apb_gen_back2back extends apb_gen;

    virtual task run();
        int num_wr = num_trans / 2;
        int num_rd = num_trans - num_wr;
        bit [`ADDR_WIDTH-1:0] written_addrs[$];
        bit [`ADDR_WIDTH-1:0] addr;

        // Burst WRITES
        repeat (num_wr) begin
            apb_pkg::raise_objection();
            req = new();
            if (!req.randomize() with {
                PWRITE == 1;
                PSTRB  == 4'hF ;
                PADDR  >= local::this.min_addr;
                PADDR  <= local::this.max_addr;
                PWDATA >= local::this.min_data;
                PWDATA <= local::this.max_data;
            }) $fatal(1, "[GEN_B2B_FATAL] WRITE burst randomization failed!");
            $display("[GEN_B2B] WRITE burst trans_id=%0d PADDR=0x%02h",
                     req.trans_id, req.PADDR);
            written_addrs.push_back(req.PADDR);
            req_copy = new();
            req_copy.copy(req);
            gen2drv_mbx.put(req_copy);
            wait(apb_pkg::drv_done);
        end

        #10;
        // Burst READS
        repeat (num_rd) begin
            apb_pkg::raise_objection();
            addr = written_addrs.pop_front();
            req = new();
            if (!req.randomize() with {
                PWRITE == 0;
                PWDATA == 0;
                PADDR  == addr;
            }) $fatal(1, "[GEN_B2B_FATAL] READ burst randomization failed!");
            $display("[GEN_B2B] READ  burst trans_id=%0d PADDR=0x%02h",
                     req.trans_id, req.PADDR);
            req_copy = new();
            req_copy.copy(req);
            gen2drv_mbx.put(req_copy);
            wait(apb_pkg::drv_done);
        end

        $display("[GEN_B2B] Done - %0d burst transactions completed", num_trans);
    endtask

endclass
`endif
*/

`ifndef APB_GEN_BACK2BACK_SV
`define APB_GEN_BACK2BACK_SV

class apb_gen_back2back extends apb_gen;

    virtual task run();
        int num_wr = num_trans / 2;
        int num_rd = num_trans - num_wr;
        bit [`ADDR_WIDTH-1:0] written_addrs[$];

        // WRITE BURST
        // Calling task and passing the addrs que to store addr
        push_write(written_addrs);
        if (num_wr > 1) push_write(written_addrs);

        repeat (num_wr) begin
            @(apb_pkg::drv_done);
            if (written_addrs.size() < num_wr)
                push_write(written_addrs);
        end

        #10;

        // READ BURST
        // Calling task and passing the addrs que to pop addr
        push_read(written_addrs);
        if (num_rd > 1) push_read(written_addrs);

        repeat (num_rd) begin
            @(apb_pkg::drv_done);
            if (written_addrs.size() > 0)
                push_read(written_addrs);
        end

        $display("[GEN_B2B] Done - %0d burst transactions completed", num_trans);
    endtask

    // push_write
    task push_write(ref bit [`ADDR_WIDTH-1:0] written_addrs[$]);
        apb_pkg::raise_objection();
        req = new();
        if (!req.randomize() with {
            PWRITE == 1;
            PSTRB  == 4'hF;
            PADDR  >= local::this.min_addr;
            PADDR  <= local::this.max_addr;
            PWDATA >= local::this.min_data;
            PWDATA <= local::this.max_data;
        }) $fatal(1, "[GEN_B2B_FATAL] WRITE randomization failed!");
        //$display("[GEN_B2B] WRITE trans_id=%0d PADDR=0x%02h", req.trans_id, req.PADDR);
        written_addrs.push_back(req.PADDR);
        req_copy = new();
        req_copy.copy(req);
        gen2drv_mbx.put(req_copy);
    endtask

    // push_read
    task push_read(ref bit [`ADDR_WIDTH-1:0] written_addrs[$]);
        bit [`ADDR_WIDTH-1:0] addr;
        apb_pkg::raise_objection();
        addr = written_addrs.pop_front();
        req  = new();
        if (!req.randomize() with {
            PWRITE == 0;
            PWDATA == 0;
            PADDR  == addr;
        }) $fatal(1, "[GEN_B2B_FATAL] READ randomization failed!");
        //$display("[GEN_B2B] READ  trans_id=%0d PADDR=0x%02h", req.trans_id, req.PADDR);
        req_copy = new();
        req_copy.copy(req);
        gen2drv_mbx.put(req_copy);
    endtask

endclass
`endif
