`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Course:  ELEC4601 - Lab 3: FPGA Design Flow and RTL Implementation
// Module:  controller (4-state Moore Debouncer)
//
// Spec (README.md):
//   States : IDLE → WAIT_PRESS → PRESSED → WAIT_RELEASE → IDLE
//   Output : debounced_pulse - asserted for EXACTLY ONE clock cycle in PRESSED
//   Reset  : Active-HIGH synchronous reset (rst), driven by sw0_sync in lab3_top
//   Timer  : Counter inside this module - no separate timer.v needed
//
// State descriptions:
//   IDLE         - Waiting for button press.        debounced_pulse = 0
//   WAIT_PRESS   - Rising edge seen; counting.      debounced_pulse = 0
//                  Counter resets if btnc drops before threshold (bounce).
//                  Moves to PRESSED when counter reaches MAX_COUNT-1.
//   PRESSED      - Stable press confirmed.          debounced_pulse = 1 ← ONE cycle only
//                  Unconditionally moves to WAIT_RELEASE next cycle.
//   WAIT_RELEASE - Waiting for button release.      debounced_pulse = 0
//                  Stays here while btnc=1 (button held).
//                  Returns to IDLE when btnc=0 (released).
//
// Parameters:
//   MAX_COUNT - Debounce window in clock cycles.
//               Hardware  : 1_000_000  (10 ms at 100 MHz)
//               Simulation: 20         (fits in XSim waveform window)
//               ILA build : 40         (fits within 1024-sample ILA window)
//
// ILA Probes (* mark_debug = "true" *):
//   state      [1:0]  - FSM state register
//   counter    [N:0]  - Debounce counter (multi-bit datapath signal)
//   btnc_probe [0:0]  - Synchronized button input (shows 2-FF sync delay)
//////////////////////////////////////////////////////////////////////////////////

module controller #(
    parameter MAX_COUNT = 1000000     // Use 20 for XSim, 40 for ILA, 1_000_000 for hardware timing
)(
    input  wire clk,
    input  wire rst,            // Active-HIGH synchronous reset (driven by sw0_sync)
    input  wire btnc,           // Pre-synchronised button input (from btnc_sync in lab3_top)
    output reg  debounced_pulse // Moore output: HIGH for exactly ONE clock cycle in PRESSED
);

    // ─── State Encoding ──────────────────────────────────────────────────────
    localparam [1:0] IDLE         = 2'b00,
                     WAIT_PRESS   = 2'b01,
                     PRESSED      = 2'b10,
                     WAIT_RELEASE = 2'b11;

    // ─── ILA-visible registers ────────────────────────────────────────────────
    (* mark_debug = "true" *) reg [1:0]                 state;
    (* mark_debug = "true" *) reg [$clog2(MAX_COUNT):0] counter;

    // Wire probe: ILA cannot directly probe module input ports
    (* mark_debug = "true" *) wire btnc_probe;
    assign btnc_probe = btnc;

    // Combinational next-state signal
    reg [1:0] next_state;

    // timer_done: HIGH when counter reaches end of debounce window
    wire timer_done = (counter == MAX_COUNT - 1);

    // ══════════════════════════════════════════════════════════════════════════
    // BLOCK 1 - State Register  (sequential, non-blocking <=)
    //
    // Active-HIGH synchronous reset. SW0 slider UP → rst=1 → FSM held in IDLE.
    // SW0 slider DOWN → rst=0 → FSM runs normally.
    // ══════════════════════════════════════════════════════════════════════════
    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ══════════════════════════════════════════════════════════════════════════
    // BLOCK 2 - Counter Logic  (sequential, non-blocking <=)
    //
    // Measures CONTINUOUS stable-HIGH time in WAIT_PRESS only.
    // Counter resets immediately if btnc drops during WAIT_PRESS (bounce).
    // Counter is not used in WAIT_RELEASE - release is handled by btnc level.
    // All other states hold counter at 0.
    // ══════════════════════════════════════════════════════════════════════════
    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
        end else begin
            case (state)
                WAIT_PRESS: begin
                    if (!btnc)              counter <= 0;           // bounce - restart
                    else if (timer_done)    counter <= 0;           // threshold reached - clear
                    else                    counter <= counter + 1; // stable HIGH - keep counting
                end
                default: counter <= 0;  // IDLE / PRESSED / WAIT_RELEASE - reset counter
            endcase
        end
    end

    // ══════════════════════════════════════════════════════════════════════════
    // BLOCK 3 - Next-State Logic  (combinational, blocking =)
    //
    // Default assignment prevents latch inference - every path is covered.
    // ══════════════════════════════════════════════════════════════════════════
    always @(*) begin
        next_state = state;                 // Default: stay in current state

        case (state)
            IDLE:
                if (btnc)
                    next_state = WAIT_PRESS;        // rising edge detected

            WAIT_PRESS:
                if (!btnc)
                    next_state = IDLE;              // dropped too early - bounce
                else if (timer_done)
                    next_state = PRESSED;           // stable for full window ✓

            PRESSED:
                next_state = WAIT_RELEASE;          // always move after exactly 1 cycle

            WAIT_RELEASE:
                if (!btnc)
                    next_state = IDLE;              // button released - ready for next press

            default: next_state = IDLE;
        endcase
    end

    // ══════════════════════════════════════════════════════════════════════════
    // BLOCK 4 - Moore Output Logic  (combinational, blocking =)
    //
    // Output depends ONLY on current state (Moore machine).
    // debounced_pulse = 1 ONLY in PRESSED - for exactly one clock cycle.
    // Default prevents latch inference.
    // ══════════════════════════════════════════════════════════════════════════
    always @(*) begin
        debounced_pulse = 1'b0;             // Default - no latch inferred

        case (state)
            PRESSED:  debounced_pulse = 1'b1;   // confirmed press → 1-cycle pulse
            default:  debounced_pulse = 1'b0;
        endcase
    end

endmodule

