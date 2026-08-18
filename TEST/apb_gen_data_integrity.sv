`ifndef APB_GEN_DATA_INTEGRITY_SV
`define APB_GEN_DATA_INTEGRITY_SV

class apb_gen_data_integrity extends apb_gen;

    virtual task run();
        //   pattern(addr) = addr * 0x0101_0101
        //   addr 0 → 0x0000_0000, addr 1 → 0x0101_0101, ..., addr 255 → 0xFFFF_FFFF
        for (int i = 0; i < `MEM_DEPTH; i++) begin
      apb_pkg::raise_objection();
      req = new();
      if (!req.randomize() with {
        PWRITE  == 1'b1;
        PADDR   == i[`ADDR_WIDTH-1:0];
        PWDATA  == 32'(i) * 32'h0101_0101;
        PSTRB   == 4'b1111;
      }) $fatal(1, "[GEN_FATAL] Full-mem WRITE[%0d] randomization failed!", i);

      req_copy = new();
      req_copy.copy(req);
      gen2drv_mbx.put(req_copy);
      @(apb_pkg::drv_done);
      end

        for (int i = 0; i < `MEM_DEPTH; i++) begin
      apb_pkg::raise_objection();
      req = new();
      if (!req.randomize() with {
        PWRITE  == 1'b0;
        PADDR   == i[`ADDR_WIDTH-1:0];
      }) $fatal(1, "[GEN_FATAL] Full-mem READ[%0d] randomization failed!", i);

      req_copy = new();
      req_copy.copy(req);
      gen2drv_mbx.put(req_copy);
      @(apb_pkg::drv_done);
       end
    endtask
endclass

`endif
