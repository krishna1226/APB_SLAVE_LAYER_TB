/////////////////////////////////////////////////////////
//                                                     //
//   FILE_NAME ---------------------apb_driver.sv      //
//   AUTHOR_NAME--------------------KRISHNA PATEL      //
//   CLASS NAME --------------------apb_driver         //
//   DESCRIPTION--------------------APB driver         //
//   VERSION------------------------V1.0               //
//   DATE --------------------------27/07/2026         //
//   TIME --------------------------16:00:00           //
//                                                     //
/////////////////////////////////////////////////////////

`ifndef APB_DRIVER_SV
`define APB_DRIVER_SV

class apb_driver;
    mailbox #(apb_trans) gen2drv_mbx;
    virtual apb_inf.DRIVER vif;
    int dropped_count = 0;

    function void connect(mailbox #(apb_trans) gen2drv_mbx,
                          virtual apb_inf.DRIVER vif);
        this.gen2drv_mbx = gen2drv_mbx;
        this.vif         = vif;
    endfunction

    task reset_interface();
        vif.drv_cb.PSEL    <= 1'b0;
        vif.drv_cb.PENABLE <= 1'b0;
        vif.drv_cb.PADDR   <= '0;
        vif.drv_cb.PWRITE  <= 1'b0;
        vif.drv_cb.PWDATA  <= '0;
        vif.drv_cb.PSTRB   <= '0;
    endtask

    task run();
        reset_interface();
        forever begin
            apb_trans trans_h;
            bit reset_seen;
            reset_seen = 1'b0;
            fork
                begin
                    gen2drv_mbx.get(trans_h);
                    drive_chain(trans_h);
                end
                begin
                    @(apb_pkg::global_reset_start);
                    reset_seen = 1'b1;
                    dropped_count++;
                    -> apb_pkg::drv_done;
                    apb_pkg::drop_objection();
                    $display("[DRIVER] Reset at %0t dropped in-flight transaction (total dropped: %0d)",
                             $time, dropped_count);
                end
            join_any
            disable fork;
            // reset handling
            if (reset_seen) begin
                fork : reset_hold
                    forever begin
                        reset_interface();
                        @(vif.drv_cb);
                    end
                join_none
                @(apb_pkg::global_reset_done);
                disable reset_hold;
                repeat (2) begin
                    reset_interface();
                    @(vif.drv_cb);
                end
                $display("[DRIVER] Reset released at %0t, held 2 cycles, resuming drive", $time);
            end
        end
    endtask

    task drive_chain(apb_trans first_trans_h);
        apb_trans cur_trans_h;
        bit       pending;

        cur_trans_h = first_trans_h;

        // SETUP phase for the first transfer in the chain
        @(vif.drv_cb);
        vif.drv_cb.PSEL    <= 1'b1;
        vif.drv_cb.PENABLE <= 1'b0;
        vif.drv_cb.PADDR   <= cur_trans_h.PADDR;
        vif.drv_cb.PWRITE  <= cur_trans_h.PWRITE;
        vif.drv_cb.PWDATA  <= cur_trans_h.PWDATA;
        vif.drv_cb.PSTRB   <= cur_trans_h.PSTRB;

        forever begin
            // ACCESS phase
            @(vif.drv_cb);
            vif.drv_cb.PENABLE <= 1'b1;
            @(vif.drv_cb iff vif.drv_cb.PREADY);

            -> apb_pkg::drv_done;
            apb_pkg::drop_objection();

            @(vif.drv_cb);

            pending = (gen2drv_mbx.num() > 0);
            if (pending) begin
                gen2drv_mbx.get(cur_trans_h);
                // Next transfer's SETUP
                vif.drv_cb.PSEL    <= 1'b1;
                vif.drv_cb.PENABLE <= 1'b0;
                vif.drv_cb.PADDR   <= cur_trans_h.PADDR;
                vif.drv_cb.PWRITE  <= cur_trans_h.PWRITE;
                vif.drv_cb.PWDATA  <= cur_trans_h.PWDATA;
                vif.drv_cb.PSTRB   <= cur_trans_h.PSTRB;
            end
            else begin
                vif.drv_cb.PSEL    <= 1'b0;
                vif.drv_cb.PENABLE <= 1'b0;
                break;
            end
        end
    endtask
endclass

`endif
