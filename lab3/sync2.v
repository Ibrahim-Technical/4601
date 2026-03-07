// File: sync2.v
// Purpose: Two-flop synchronizer for asynchronous inputs (e.g., push-buttons / switches).
// Notes:  - Marked with ASYNC_REG to guide Vivado's physical synthesis
//         - Single clock domain (clk)
//         - Active-high async input -> clean, debounced/filtered elsewhere
module sync2 (
    input  wire clk,        // 100 MHz system clock (single domain)
    input  wire async_in,   // asynchronous signal (e.g., raw push-button)
    output wire sync_out    // synchronized version (safe for FSM logic)
);
    // Synthesis attribute hints for metastability hardening
    (* ASYNC_REG = "TRUE" *) reg s1 = 1'b0;
    (* ASYNC_REG = "TRUE" *) reg s2 = 1'b0;

    always @(posedge clk) begin
        s1 <= async_in;
        s2 <= s1;
    end

    assign sync_out = s2;
endmodule
