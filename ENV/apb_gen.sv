`ifndef APB_GEN_SV
`define APB_GEN_SV

class apb_gen;

    mailbox #(apb_trans) gen2drv_mbx;
    apb_trans req, req_copy;

    rand int                        num_trans;
    rand trans_kind                 gen_mode;
    rand logic [`ADDR_WIDTH-1:0]   min_addr;
    rand logic [`ADDR_WIDTH-1:0]   max_addr;
    rand logic [`DATA_WIDTH-1:0]   min_data;
    rand logic [`DATA_WIDTH-1:0]   max_data;

    constraint gen_c {
        num_trans == 10;
        gen_mode  == WRITE_ONLY;
        min_addr  == 0;
        max_addr  == {`ADDR_WIDTH{1'b1}};
        min_data  == 0;
        max_data  == {`DATA_WIDTH{1'b1}};
    }

    function void connect(mailbox #(apb_trans) gen2drv_mbx);
        this.gen2drv_mbx = gen2drv_mbx;
    endfunction

    virtual task run();
        repeat (num_trans) begin
        apb_pkg::raise_objection();
        req = new();

        case (gen_mode)

            WRITE_ONLY: begin
            if (!req.randomize() with {
                PWRITE == 1;
                PSTRB  != 0;
                PADDR  >= local::this.min_addr; PADDR <= local::this.max_addr;
                PWDATA >= local::this.min_data; PWDATA <= local::this.max_data;
                }) $fatal(1, "[GEN_FATAL] WRITE_ONLY randomization failed!");
            end

            READ_ONLY: begin
            if (!req.randomize() with {
                PWRITE == 0;
                PADDR  >= local::this.min_addr; PADDR <= local::this.max_addr;
                }) $fatal(1, "[GEN_FATAL] READ_ONLY randomization failed!");
            end

            default: begin
            if (!req.randomize())
                $fatal(1, "[GEN_FATAL] Default randomization failed!");
            end
        endcase

        //$display("[GEN] mode=%0s trans_id=%0d PADDR=0x%02h PWRITE=%0b PSTRB=4'b%4b",
        //          gen_mode.name(), req.trans_id, req.PADDR, req.PWRITE, req.PSTRB);

        req_copy = new();
        req_copy.copy(req);
        gen2drv_mbx.put(req_copy);
        @(apb_pkg::drv_done);
        end

        $display("[GEN] Done generating %0d transactions (mode=%0s)", num_trans, gen_mode.name());
    endtask
endclass
`endif

/*
`ifndef APB_GEN_SV
`define APB_GEN_SV

class apb_gen;
    mailbox #(apb_trans) gen2drv_mbx;
    apb_trans req, req_copy;
    rand int                       num_trans;
    rand trans_kind                gen_mode;
    rand logic [`ADDR_WIDTH-1:0]   min_addr;
    rand logic [`ADDR_WIDTH-1:0]   max_addr;
    rand logic [`DATA_WIDTH-1:0]   min_data;
    rand logic [`DATA_WIDTH-1:0]   max_data;

    constraint gen_c {
        num_trans == 10;
        gen_mode  == WRITE_ONLY;
        min_addr  == 0;
        max_addr  == {`ADDR_WIDTH{1'b1}};
        min_data  == 0;
        max_data  == {`DATA_WIDTH{1'b1}};
    }

    function void connect(mailbox #(apb_trans) gen2drv_mbx);
        this.gen2drv_mbx = gen2drv_mbx;
    endfunction

 task gen_and_put();
        apb_pkg::raise_objection();
        req = new();
        case (gen_mode)
            WRITE_ONLY: begin
                if (!req.randomize() with {
                    PWRITE == 1;
                    PSTRB  != 0;
                    PADDR  >= local::this.min_addr; PADDR <= local::this.max_addr;
                    PWDATA >= local::this.min_data; PWDATA <= local::this.max_data;
                }) $fatal(1, "[GEN_FATAL] WRITE_ONLY randomization failed!");
            end
            READ_ONLY: begin
                if (!req.randomize() with {
                    PWRITE == 0;
                    PADDR  >= local::this.min_addr; PADDR <= local::this.max_addr;
                }) $fatal(1, "[GEN_FATAL] READ_ONLY randomization failed!");
            end
            default: begin
                if (!req.randomize())
                    $fatal(1, "[GEN_FATAL] Default randomization failed!");
            end
        endcase
        req_copy = new();
        req_copy.copy(req);
        gen2drv_mbx.put(req_copy);
    endtask

    virtual task run();
        int remaining;
        remaining = num_trans;

        if (remaining > 0) begin gen_and_put(); remaining--; end
        if (remaining > 0) begin gen_and_put(); remaining--; end

        repeat (num_trans) begin
            @(apb_pkg::drv_done);           // driver finished one
            if (remaining > 0) begin
                gen_and_put();              // immediately queue the next
                remaining--;
            end
        end

        $display("[GEN] Done generating %0d transactions (mode=%0s)",
                 num_trans, gen_mode.name());
    endtask

endclass
`endif
*/
