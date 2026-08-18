`ifndef APB_TRANS_SV
`define APB_TRANS_SV

class apb_trans extends apb_sequence_item;

    static int trans_id_counter = 0;
    int trans_id;

    // Driven by TB (master side) -> DUT
    rand logic [`ADDR_WIDTH-1:0] PADDR;
    rand logic                   PWRITE;
    rand logic [`DATA_WIDTH-1:0] PWDATA;
    rand logic [`STRB_WIDTH-1:0] PSTRB;

    // Sampled from DUT (slave) -> TB
    logic [`DATA_WIDTH-1:0] PRDATA;
    logic                   PREADY;
    logic                   PSLVERR;

    // Constraints
    constraint valid_strb_c {
        PWRITE  -> (PSTRB != 0);    // At least one strobe for writes
        !PWRITE -> (PSTRB == 0);    // No strobes for reads
    }

    function new(string name = "apb_trans");
        trans_id = trans_id_counter++;
    endfunction

    // PRINT function 
    // By --> AI
    virtual function void print(string id = "TRANSACTION", apb_sequence_item exp = null);
        apb_trans exp_t;
        string trans_type;
        trans_type = PWRITE ? "WRITE" : "READ";
            $display("\n==================================================================================");
            $display("| [%-10s] | ID: %-4d | TRANS_TYPE: %-5s                              |", id, trans_id, trans_type);
            $display("+--------------------------------------------------------------------------------+");
            if (exp != null && $cast(exp_t, exp)) begin
            $display("|  [STATUS]   ACT_PSLVERR: %1b     (EXP: %1b)  |  PREADY: %1b                          |",this.PSLVERR, exp_t.PSLVERR, this.PREADY);
            $display("|  [CONTROL]  ACT_PWRITE:  %1b     (EXP: %1b)  |  ACT_PSTRB: 4'b%4b (EXP: 4'b%4b)  |",this.PWRITE, exp_t.PWRITE, this.PSTRB, exp_t.PSTRB);
            $display("|  [ADDRESS]  ACT_PADDR:   0x%02h  (EXP: 0x%02h)                                     |", this.PADDR, exp_t.PADDR);
            $display("|  [WRITE]    ACT_PWDATA:  0x%08h (EXP: 0x%08h)                          |", this.PWDATA, exp_t.PWDATA);
            $display("|  [READ]     ACT_PRDATA:  0x%08h (EXP: 0x%08h)                          |", this.PRDATA, exp_t.PRDATA);
            end 
            else begin
            $display("|  [STATUS]   PSLVERR: %1b  |  PREADY: %1b                                           |", this.PSLVERR, this.PREADY);
            $display("|  [CONTROL]  PWRITE:  %1b  |  PSTRB: 4'b%4b                                      |", this.PWRITE, this.PSTRB);
            $display("|  [ADDRESS]  PADDR:   0x%02h                                                      |", this.PADDR);
            $display("|  [WRITE]    PWDATA:  0x%08h                                                |", this.PWDATA);
            $display("|  [READ]     PRDATA:  0x%08h                                                |", this.PRDATA);
            end
            $display("==================================================================================");
        endfunction

  virtual function void copy(apb_sequence_item rhs);
    apb_trans temp;
    if (!$cast(temp, rhs)) begin
      $error("Type mismatch in copy");
      return;
    end
    this.trans_id = temp.trans_id;
    this.PADDR    = temp.PADDR;
    this.PWRITE   = temp.PWRITE;
    this.PWDATA   = temp.PWDATA;
    this.PSTRB    = temp.PSTRB;
    this.PRDATA   = temp.PRDATA;
    this.PREADY   = temp.PREADY;
    this.PSLVERR  = temp.PSLVERR;
  endfunction

endclass
`endif
