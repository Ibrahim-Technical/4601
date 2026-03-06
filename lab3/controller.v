`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Course:  ELEC4601 - Lab 3: FPGA Design Flow and RTL Implementation
// Module:  controller
//
// Adapted from Lab 2 debouncer_fsm. Changes made for Lab 3:
//   1. Module renamed:   debouncer_fsm  → controller
//   2. Clock renamed:    clk            → clk  (matches lab3_top internal wiring)
//   3. Reset:            active-HIGH reset removed; replaced with active-LOW rst_n.
//                        In lab3_top, sw0_sync drives rst_n inverted:
//                        rst_n = ~sw0_sync (SW0 slider UP = reset, DOWN = running).
//   4. Button port:      btn_in → btnc   (matches lab3_top wiring name)
//   5. Output port:      btn_out → led1_out  (drives led1 in lab3_top)
//   6. PRESSED (1-cycle pulse) → DEBOUNCED (held HIGH while button pressed)
//                        Lab 2 PRESSED was only 10 ns — invisible on an LED.
//                        DEBOUNCED holds output HIGH for the full press duration.
//   7. (* mark_debug = "true" *) added on state, counter, btnc_probe
//                        so Vivado keeps these nets alive for ILA probing.
//
// States:
//   IDLE         — No press detected.         led1_out = 0
//   WAIT_PRESS   — Rising edge seen; counting. led1_out = 0
//                  Counter resets on any bounce (btnc drops before threshold).
//   DEBOUNCED    — Stable press confirmed.     led1_out = 1  ← LED1 ON
//                  Stays here while button held.
//   WAIT_RELEASE — Button released; counting.  led1_out = 1  ← LED1 ON
//                  Counter resets if btnc rises again (release bounce).
//                  Returns to IDLE once stable-low window completes.
//
// Parameters:
//   MAX_COUNT — Debounce window in clock cycles.
//               100 MHz hardware : 1_000_000  (10 ms)
//               XSim simulation  : 20         (fits in waveform window)
//               ILA capture      : 20–40      (fits within ILA sample depth)
//
// ILA Probes (mark_debug = "true" prevents synthesis from removing these nets):
//   state      [1:0]  — FSM state register
//   counter    [N:0]  — Debounce counter (multi-bit datapath signal)
//   btnc_probe [0:0]  — Synchronised button input (shows 2-FF delay on ILA)
//////////////////////////////////////////////////////////////////////////////////

module controller #(
    parameter MAX_COUNT = 20     // Use 20 for XSim/ILA, 1_000_000 for hardware
)(
    input  wire clk,
    input  wire rst_n,          // Active-LOW synchronous reset (driven by ~sw0_sync)
    input  wire btnc,           // Pre-synchronised button input (from btnc_sync)
    output reg  led1_out        // Moore output → LED1
);

    // ─── State Encoding ──────────────────────────────────────────────────────
    localparam [1:0] IDLE         = 2'b00,
                     WAIT_PRESS   = 2'b01,
                     DEBOUNCED    = 2'b10,
                     WAIT_RELEASE = 2'b11;

    // ─── ILA-visible registers ────────────────────────────────────────────────
    // mark_debug = "true" prevents Vivado from optimising these nets away.
    // Without this attribute, synthesis may fold or remove internal signals
    // that are not directly connected to top-level ports.
    (* mark_debug = "true" *) reg [1:0]                 state;
    (* mark_debug = "true" *) reg [$clog2(MAX_COUNT):0] counter;

    // Wire probe for btnc — ILA cannot probe input ports directly
    (* mark_debug = "true" *) wire btnc_probe;
    assign btnc_probe = btnc;

    // Combinational next-state
    reg [1:0] next_state;

    // timer_done goes HIGH when counter reaches the end of the debounce window
    wire timer_done = (counter == MAX_COUNT - 1);

    // ══════════════════════════════════════════════════════════════════════════
    // BLOCK 1 — State Register  (sequential, non-blocking <=)
    //
    // All FFs update simultaneously at the rising clock edge.
    // Non-blocking <= ensures next_state from Block 3 this cycle is
    // registered and becomes state on the NEXT cycle — no combinational loop.
    // ══════════════════════════════════════════════════════════════════════════
    always @(posedge clk) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ══════════════════════════════════════════════════════════════════════════
    // BLOCK 2 — Counter Logic  (sequential, non-blocking <=)
    //
    // Measures CONTINUOUS stable-signal time (not accumulated across bounces).
    //   WAIT_PRESS  : counts while btnc=1; resets immediately on any drop.
    //   WAIT_RELEASE: counts while btnc=0; resets immediately on any rise.
    //   All other states: always hold at 0, ready for next use.
    // ══════════════════════════════════════════════════════════════════════════
    always @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0;
        end else begin
            case (state)
                WAIT_PRESS: begin
                    if (!btnc)          counter <= 0;             // bounce — restart
                    else if (timer_done) counter <= 0;            // threshold reached — clear
                    else                counter <= counter + 1;   // stable high — keep counting
                end

                WAIT_RELEASE: begin
                    if (btnc)           counter <= 0;             // bounce — restart
                    else if (timer_done) counter <= 0;            // threshold reached — clear
                    else                counter <= counter + 1;   // stable low — keep counting
                end

                default: counter <= 0;  // IDLE / DEBOUNCED — always reset
            endcase
        end
    end

    // ══════════════════════════════════════════════════════════════════════════
    // BLOCK 3 — Next-State Logic  (combinational, blocking =)
    //
    // Default assignment (next_state = state) at the top of the always block
    // covers every path not explicitly handled by the case statement.
    // This single line is what prevents Vivado from inferring latches.
    // ══════════════════════════════════════════════════════════════════════════
    always @(*) begin
        next_state = state;             // Default: stay — no latch inferred

        case (state)
            IDLE:
                if (btnc)
                    next_state = WAIT_PRESS;        // rising edge detected

            WAIT_PRESS:
                if (!btnc)
                    next_state = IDLE;              // dropped too early — bounce
                else if (timer_done)
                    next_state = DEBOUNCED;         // stable for full window ✓

            DEBOUNCED:
                if (!btnc)
                    next_state = WAIT_RELEASE;      // button released — start release timer

            WAIT_RELEASE:
                if (btnc)
                    next_state = DEBOUNCED;         // re-pressed during release bounce
                else if (timer_done)
                    next_state = IDLE;              // stable release confirmed — done

            default: next_state = IDLE;
        endcase
    end

    // ══════════════════════════════════════════════════════════════════════════
    // BLOCK 4 — Moore Output Logic  (combinational, blocking =)
    //
    // Output depends ONLY on current state (Moore).
    // Default assignment (led1_out = 0) prevents latch inference.
    // LED1 stays ON in both DEBOUNCED and WAIT_RELEASE so it is visible
    // for the full duration of a confirmed press.
    // ══════════════════════════════════════════════════════════════════════════
    always @(*) begin
        led1_out = 1'b0;                // Default — no latch inferred

        case (state)
            IDLE:         led1_out = 1'b0;
            WAIT_PRESS:   led1_out = 1'b0;
            DEBOUNCED:    led1_out = 1'b1;  // confirmed press → LED1 ON
            WAIT_RELEASE: led1_out = 1'b1;  // still held/releasing → LED1 ON
            default:      led1_out = 1'b0;
        endcase
    end

endmodule
