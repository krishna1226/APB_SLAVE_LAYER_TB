`ifndef APB_GEN_STRB_SV
`define APB_GEN_STRB_SV

class apb_gen_strb extends apb_gen;

  // Fixed PSTRB patterns to cycle through
  logic [`STRB_WIDTH-1:0] strb_patterns[$] = '{
    4'b0001, 4'b0010,4'b0100,4'b1000,
    4'b0011, 4'b0111,4'b1111,4'b1110,
    4'b1100, 4'b1100
  };

  virtual task run();
    int idx = 0;
    int pairs   = num_trans / 2;

    repeat (pairs) begin
      logic [`STRB_WIDTH-1:0] target_strb;
      logic [`ADDR_WIDTH-1:0] target_addr;

      target_strb = strb_patterns[idx % strb_patterns.size()];
      idx++;

      // WRITE with specific PSTRB pattern
      apb_pkg::raise_objection();
      req = new();
      req.valid_strb_c.constraint_mode(0);  // Disable default strobe constraint
      
      if (!req.randomize() with {
        PWRITE == 1;
        PSTRB  == local::target_strb;
        PADDR  < `MEM_DEPTH;
      }) $fatal(1, "[GEN_STRB_FATAL] WRITE randomization failed for PSTRB=4'b%4b", target_strb);

      target_addr = req.PADDR;

      $display("[GEN_STRB] WRITE trans_id=%0d PADDR=0x%02h PSTRB=4'b%4b PWDATA=0x%08h",
                req.trans_id, req.PADDR, req.PSTRB, req.PWDATA);

      req_copy = new();
      req_copy.copy(req);
      gen2drv_mbx.put(req_copy);
      @(apb_pkg::drv_done);

      // READ back same address
      apb_pkg::raise_objection();
      req = new();
      if (!req.randomize() with {
        PWRITE == 0;
        PADDR  == local::target_addr;
      }) $fatal(1, "[GEN_STRB_FATAL] READ randomization failed!");

      $display("[GEN_STRB] READ  trans_id=%0d PADDR=0x%02h",
                req.trans_id, req.PADDR);

      req_copy = new();
      req_copy.copy(req);
      gen2drv_mbx.put(req_copy);
      @(apb_pkg::drv_done);
    end

    $display("[GEN_STRB] Done -%0d strobe write-read pairs completed", pairs);
  endtask

endclass

`endif
