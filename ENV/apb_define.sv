`ifndef APB_DEFINE_SV
`define APB_DEFINE_SV

`define ADDR_WIDTH 8
`define DATA_WIDTH 32
`define STRB_WIDTH (`DATA_WIDTH / 8)
`define MEM_DEPTH  254 // change this to 240 for running "apb_error_test"
`define MAX_WAIT   3

typedef enum { WRITE_ONLY, READ_ONLY, ERROR_ADDR } trans_kind;

`endif
