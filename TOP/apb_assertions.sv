`ifndef APB_ASSERTIONS_SV
`define APB_ASSERTIONS_SV

`include "apb_define.sv"

module apb_assertions#(
    parameter int ADDR_WIDTH = 8,
    parameter int DATA_WIDTH = 32,
    parameter int STRB_WIDTH = DATA_WIDTH / 8,
    parameter int MAX_DEPTH  = 256,
    parameter int MAX_WAIT   = 3
    )(
    input logic                   PCLK,
    input logic                   PRESETn,
    input logic                   PSEL,
    input logic                   PENABLE,
    input logic                   PWRITE,// WRITE = 1 , READ =0
    input logic [STRB_WIDTH-1:0]  PSTRB,
    input logic [ADDR_WIDTH-1:0]  PADDR,
    input logic [DATA_WIDTH-1:0]  PWDATA,
    input logic [DATA_WIDTH-1:0]  PRDATA,
    input logic                   PREADY,
    input logic                   PSLVERR
    );
/*
    // 1. No X/Z on Control Signals: PSEL, PENABLE, PWRITE, PREADY must not be X or Z when not in reset
    property p_no_x_on_ctrl;
        @(posedge PCLK)
        disable iff (!PRESETn)
        !$isunknown({PSEL, PENABLE, PWRITE, PREADY});
    endproperty

    assert_no_x_on_ctrl: assert property (p_no_x_on_ctrl)
        else $error("SVA Failure [1]: X/Z detected on control signals (PSEL/PENABLE/PWRITE/PREADY).");

    // 2. Reset Recovery: After reset deasserts, the bus should be idle (PSEL=1, PENABLE=0) on the first active clock edge
    property p_reset_recovery;
        @(posedge PCLK)
        $rose(PRESETn) |-> ##2 (PSEL && !PENABLE);
    endproperty

    assert_reset_recovery: assert property (p_reset_recovery)
        else $error("SVA Failure [2]: Bus not idle on first clock after reset deassert.");
*/

        // 1. No X/Z on Control Signals: PSEL, PENABLE, PWRITE, PREADY must not be X or Z when not in reset
    property p_no_x_on_ctrl;
        @(posedge PCLK)
        disable iff (!PRESETn || $isunknown(PRESETn))
        $past(PRESETn) |-> !$isunknown({PSEL, PENABLE, PWRITE, PREADY});
    endproperty

    assert_no_x_on_ctrl: assert property (p_no_x_on_ctrl)
        else $error("SVA Failure [1]: X/Z detected on control signals (PSEL/PENABLE/PWRITE/PREADY).");

    // 2. Reset Recovery: After reset deasserts, PENABLE must not be asserted on the first active clock edge
    property p_reset_recovery;
        @(posedge PCLK)
        $rose(PRESETn) |-> !PENABLE;
    endproperty

    assert_reset_recovery: assert property (p_reset_recovery)
        else $error("SVA Failure [2]: PENABLE is asserted on first clock after reset deassert.");

    // 3. Reset: Outputs must be cleared during reset PREADY=0, PSLVERR=0, PRDATA=0
    property p_reset_outputs;
        @(posedge PCLK)
        (!PRESETn) |-> (PREADY === 1'b0) && (PSLVERR === 1'b0) && (PRDATA === '0);
    endproperty

    assert_reset_outputs: assert property (p_reset_outputs)
        else $error("SVA Failure [3]: Slave outputs not cleared during reset (PREADY=%b, PSLVERR=%b).",PREADY, PSLVERR);

    // 4. SETUP -> ACCESS Handshake: PENABLE must assert 1 cycle after PSEL
    property p_setup_to_access;
        @(posedge PCLK)
        disable iff (!PRESETn)
        (PSEL && !PENABLE) |-> ##1 PENABLE;
    endproperty

    assert_setup_to_access: assert property (p_setup_to_access)
        else $error("SVA Failure [4]: PENABLE did not assert 1 cycle after PSEL.");

    // 5. No PENABLE without PSEL: PENABLE must never be high when PSEL is low
    property p_no_penable_without_psel;
        @(posedge PCLK)
        disable iff (!PRESETn)
        !PSEL |-> !PENABLE;
    endproperty

    assert_no_penable_without_psel: assert property (p_no_penable_without_psel)
        else $error("SVA Failure [5]: PENABLE is high while PSEL is low (illegal state).");

    // 6. PSLVERR on Out-Of-Bound Address: When address >= MEM_DEPTH and transfer completes, PSLVERR must be 1.
    property p_pslverr_on_oob;
        @(posedge PCLK)
        disable iff (!PRESETn)
        (PSEL && PENABLE && PREADY && (PADDR >= MAX_DEPTH)) |-> (PSLVERR === 1'b1);
    endproperty

    assert_pslverr_on_oob: assert property (p_pslverr_on_oob)
        else $error("SVA Failure [6]: PSLVERR not asserted for out-of-bound address 0x%02h.", PADDR);

    // 7. Bounded ACCESS Duration: Once in ACCESS phase (PSEL & PENABLE),PENABLE must deassert within MAX_WAIT+2 cycles
    property p_access_bounded;
        @(posedge PCLK)
        disable iff (!PRESETn)
        (PSEL && PENABLE) |-> ##[1:MAX_WAIT+2] !PENABLE;
    endproperty

    assert_access_bounded: assert property (p_access_bounded)
        else $error("SVA Failure [7]: ACCESS phase exceeded %0d cycles — PENABLE stuck high.", MAX_WAIT+2);

    // 8. PSEL Stability: PSEL must remain high from SETUP through ACCESS
    property p_psel_stable;
        @(posedge PCLK)
        disable iff (!PRESETn)
        (PSEL && !PENABLE) |=> PSEL;
    endproperty

    assert_psel_stable: assert property (p_psel_stable)
        else $error("SVA Failure [8]: PSEL dropped during SETUP->ACCESS transition.");

    // 9. PWRITE Stability: PWRITE must be stable from SETUP to ACCESS
    property p_pwrite_stable;
        @(posedge PCLK)
        disable iff (!PRESETn)
        (PSEL && !PENABLE) |=> $stable(PWRITE);
    endproperty

    assert_pwrite_stable: assert property (p_pwrite_stable)
        else $error("SVA Failure [9]: PWRITE changed during SETUP->ACCESS transition.");

    // 10. PADDR Stability: PADDR must be stable from SETUP to ACCESS
    property p_paddr_stable;
        @(posedge PCLK)
        disable iff (!PRESETn)
        (PSEL && !PENABLE) |=> $stable(PADDR);
    endproperty

    assert_paddr_stable: assert property (p_paddr_stable)
        else $error("SVA Failure [10]: PADDR changed during SETUP->ACCESS transition.");

    // 11. PWDATA Stability: PWDATA must be stable from SETUP to ACCESS on write transfers
    property p_pwdata_stable;
        @(posedge PCLK)
        disable iff (!PRESETn)
        (PSEL && !PENABLE && PWRITE) |=> $stable(PWDATA);
    endproperty

    assert_pwdata_stable: assert property (p_pwdata_stable)
        else $error("SVA Failure [11]: PWDATA changed during SETUP->ACCESS on a write transfer.");

    // 12. PSTRB Stability: PSTRB must be stable from SETUP to ACCESS
    property p_pstrb_stable;
        @(posedge PCLK)
        disable iff (!PRESETn)
        (PSEL && !PENABLE && PWRITE) |=> $stable(PSTRB);
    endproperty

    assert_pstrb_stable: assert property (p_pstrb_stable)
        else $error("SVA Failure [12]: PSTRB changed during SETUP->ACCESS transition.");

endmodule
`endif
