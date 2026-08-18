`ifndef APB_GEN_FULL_MEM_SV
`define APB_GEN_FULL_MEM_SV

class apb_gen_full_mem extends apb_gen;

  virtual task run();
    //Write all DEPTH locations sequentially
    for (int i = 0; i < `MEM_DEPTH; i++) begin
      apb_pkg::raise_objection();
      req = new();
      if (!req.randomize() with {
        PWRITE  == 1'b1;
        PADDR   == local::i[`ADDR_WIDTH-1:0];
        PWDATA  >= local::this.min_data; 
        PWDATA  <= local::this.max_data;
      }) $fatal(1, "[GEN_FATAL] Full-mem WRITE[%0d] randomization failed!", i);

      req_copy = new();
      req_copy.copy(req);
      gen2drv_mbx.put(req_copy);
      @(apb_pkg::drv_done);
      end

    //Read all DEPTH locations back
    for (int i = 0; i < `MEM_DEPTH; i++) begin
      apb_pkg::raise_objection();
      req = new();
      if (!req.randomize() with {
        PWRITE  == 1'b0;
        PADDR   == local::i[`ADDR_WIDTH-1:0];
      }) $fatal(1, "[GEN_FATAL] Full-mem READ[%0d] randomization failed!", i);

      req_copy = new();
      req_copy.copy(req);
      gen2drv_mbx.put(req_copy);
      @(apb_pkg::drv_done);
       end
  endtask
endclass

`endif
