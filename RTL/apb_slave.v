module apb_slave #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter STRB_WIDTH = DATA_WIDTH / 8,
    parameter MEM_DEPTH  = 256,
    parameter MAX_WAIT   = 3
)(
    input  wire                  PCLK,
    input  wire                  PRESETn,
    input  wire [ADDR_WIDTH-1:0] PADDR,
    input  wire                  PSEL,
    input  wire                  PENABLE,
    input  wire                  PWRITE,
    input  wire [DATA_WIDTH-1:0] PWDATA,
    input  wire [STRB_WIDTH-1:0] PSTRB,
    output reg  [DATA_WIDTH-1:0] PRDATA,
    output wire                  PREADY,
    output wire                  PSLVERR
);

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    // APB FSM state
    localparam ST_IDLE   = 2'b00;
    localparam ST_SETUP  = 2'b01;
    localparam ST_ACCESS = 2'b10;

    reg [1:0] state;

    // Wait-state counter
    localparam WAIT_W     = $clog2(MAX_WAIT + 1);
    localparam [WAIT_W-1:0] MAX_WAIT_W = MAX_WAIT[WAIT_W-1:0];  

    reg [WAIT_W-1:0] wait_cnt;

    // Address error 
    wire addr_error = (PADDR >= 255);

    // Desired wait states from PADDR[3:2], clamped to MAX_WAIT
    wire [1:0]        paddr_waits      = PADDR[3:2];
    wire [WAIT_W-1:0] wanted_waits_raw = {{(WAIT_W-2){1'b0}}, paddr_waits};
    wire [WAIT_W-1:0] wanted_waits     = (wanted_waits_raw > MAX_WAIT_W)
                                          ? MAX_WAIT_W
                                          : wanted_waits_raw;

    wire ready_now = (wait_cnt >= wanted_waits);

    integer i;

    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            state    <= ST_IDLE;
            wait_cnt <= {WAIT_W{1'b0}};
            PRDATA   <= {DATA_WIDTH{1'b0}};
            for (i = 0; i < MEM_DEPTH; i = i + 1)
                mem[i] <= {DATA_WIDTH{1'b0}};
        end
        else begin
            case (state)

                // IDLE:
                ST_IDLE: begin
                    if (PSEL && !PENABLE)
                        state <= ST_SETUP;
                end

                // SETUP:
                ST_SETUP: begin
                    wait_cnt <= {WAIT_W{1'b0}};
                    if (PSEL && PENABLE)
                        state <= ST_ACCESS;
                    else if (!PSEL)
                        state <= ST_IDLE;
                end

               // ACCESS:
                ST_ACCESS: begin
                    if (!ready_now) begin
                        wait_cnt <= wait_cnt + 1'b1;
                    end
                    else begin
                        wait_cnt <= {WAIT_W{1'b0}};
                        if (PWRITE && !addr_error) begin
                            for (i = 0; i < STRB_WIDTH; i = i + 1) begin
                                if (PSTRB[i])
                                    mem[PADDR][i*8 +: 8] <= PWDATA[i*8 +: 8];
                            end
                        end
                        if (!PWRITE && !addr_error)
                            PRDATA <= mem[PADDR];
                        else
                            PRDATA <= {DATA_WIDTH{1'b0}};

                        if (PSEL)
                            state <= ST_SETUP;
                        else
                            state <= ST_IDLE;
                    end
                end

                default: begin
                    state    <= ST_IDLE;
                    wait_cnt <= {WAIT_W{1'b0}};
                end

            endcase
        end
    end

    // Combinational outputs
    assign PREADY  = (state == ST_ACCESS) && ready_now && PSEL && PENABLE;
    assign PSLVERR = (state == ST_ACCESS) && ready_now && PSEL && PENABLE
                     && addr_error;

endmodule
