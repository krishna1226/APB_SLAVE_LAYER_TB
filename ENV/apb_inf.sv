`ifndef APB_INF_SV
`define APB_INF_SV
`include "apb_define.sv"
interface apb_inf (input logic PCLK, input logic PRESETn);

    // APB Bus signals
    // APB Bus signals initialized to known defaults at time 0
    logic [`ADDR_WIDTH-1:0] PADDR   = '0;
    logic                   PSEL    = 1'b0;
    logic                   PENABLE = 1'b0;
    logic                   PWRITE  = 1'b0;
    logic [`DATA_WIDTH-1:0] PWDATA  = '0;
    logic [`STRB_WIDTH-1:0] PSTRB   = '0;
    logic [`DATA_WIDTH-1:0] PRDATA;
    logic                   PREADY;
    logic                   PSLVERR;

    // Driver clocking block 
    clocking drv_cb @(posedge PCLK);
        default input #0 output #1;
        output PADDR, PSEL, PENABLE, PWRITE, PWDATA, PSTRB;
        input  PRDATA, PREADY, PSLVERR;
    endclocking

    //Monitor clocking block
    clocking mon_cb @(posedge PCLK);
        default input #0 output #1;
        input PADDR, PSEL, PENABLE, PWRITE, PWDATA, PSTRB, PRDATA, PREADY, PSLVERR;
    endclocking

    modport DRIVER  (clocking drv_cb, input PCLK, PRESETn);
    modport MONITOR (clocking mon_cb, input PCLK, PRESETn);

endinterface
`endif
