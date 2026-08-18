`ifndef APB_SCOREBOARD_SV
`define APB_SCOREBOARD_SV

class apb_scoreboard;

    apb_trans actual_q[$];
    apb_trans expected_q[$];

    mailbox #(apb_trans) mon2sb_mbx;
    mailbox #(apb_trans) ref2sb_mbx;

    int match_count    = 0;
    int mismatch_count = 0;

    apb_coverage cov_h;

    function new();
        cov_h = new();
    endfunction

    function void connect(mailbox #(apb_trans) mon2sb_mbx,
                          mailbox #(apb_trans) ref2sb_mbx);
        this.mon2sb_mbx = mon2sb_mbx;
        this.ref2sb_mbx = ref2sb_mbx;
    endfunction

    task run();
        fork
            // Collect actual transactions from monitor
            forever begin
                apb_trans t;
                mon2sb_mbx.get(t);
                actual_q.push_back(t);
                compare();
            end

            // Collect expected transactions from ref model
            forever begin
                apb_trans t;
                ref2sb_mbx.get(t);
                expected_q.push_back(t);
            end
        join
    endtask

    task compare();
        wait (actual_q.size() > 0 && expected_q.size() > 0) begin 
            apb_trans act = actual_q.pop_front();
            apb_trans exp = expected_q.pop_front();

            bit is_match = 1;

            // CHECK for PSLVERR
            if (act.PSLVERR  !== exp.PSLVERR)    is_match = 0;

            // CHECK for WRITE 
            if (act.PWRITE === 1'b1 && exp.PWRITE === 1'b1) begin 
                if (act.PADDR    !== exp.PADDR)      is_match = 0;
                if (act.PWDATA   !== exp.PWDATA)     is_match = 0;
                if (act.PSTRB    !== exp.PSTRB)      is_match = 0;
            end

            // CHECK for READ
            else if (act.PWRITE === 1'b0 && exp.PWRITE === 1'b0) begin
                if (act.PADDR    !== exp.PADDR)      is_match = 0;
                if (act.PRDATA   !== exp.PRDATA)     is_match = 0;
            end

            if (is_match) begin
                match_count++;
                cov_h.sample(act, is_match);
                act.print("SCOREBOARD MATCH", exp);
            end 
            else begin
                mismatch_count++;
                $display("[SCOREBOARD MISMATCH] Trans ID %0d failed comparison at time %0t",
                         act.trans_id, $time);
                act.print("MISMATCH ACTUAL", exp);
            end
        end
    endtask 

    // Called from final block
    function void final_check();
        int act_size = actual_q.size();
        int exp_size = expected_q.size();

        $display("\n--------------------------------------------------------------------------------");
        $display("                         SCOREBOARD FINAL QUEUE CHECK                           ");
        $display("--------------------------------------------------------------------------------");

        if (act_size > 0) begin
            $display("  [SCOREBOARD FAIL] actual_q has %0d unmatched transactions remaining!", act_size);
        foreach (actual_q[i])
                actual_q[i].print($sformatf("LEFTOVER ACTUAL [%0d]", i));
        end

        if (exp_size > 0) begin
            $display("  [SCOREBOARD FAIL] expected_q has %0d unmatched transactions remaining!", exp_size);
        foreach (expected_q[i])
                expected_q[i].print($sformatf("LEFTOVER EXPECTED [%0d]", i));
        end

        if (act_size == 0 && exp_size == 0)
            $display("  [SCOREBOARD PASS] Both queues are empty all transactions matched in-order.");
        else
            $display("  [SCOREBOARD FAIL] Queue size > 0 — TEST FAILED");

        $display("--------------------------------------------------------------------------------");
    endfunction

    function void report();
        cov_h.report();
    endfunction
endclass
`endif
