`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Course: ELEC4601 - Digital and Embedded Systems Design
// Laboratory 2: Simulation Testbench
//
// Module: debouncer_tb
//
// Description:
//   Testbench for lab2_wrapper. Drives a realistic mechanical-bounce waveform
//   to verify the 4-state Moore FSM debouncer.
//
// IMPORTANT — Before running simulation:
//   Set MAX_COUNT = 20 inside debouncer_fsm.v so waveforms are visible.
//   Restore MAX_COUNT = 1_000_000 before generating the hardware bitstream.
//
// Signals to add in XSim waveform window:
//   tb_btn_in                      — raw stimulus you are driving
//   DUT/btn_sync_1                 — after 2-FF synchronizer (inside wrapper)
//   DUT/u_debouncer/state          — FSM state register
//   DUT/u_debouncer/counter        — debounce counter value
//   DUT/u_debouncer/timer_MAX      — counter threshold flag
//   tb_led_debounced               — clean single-pulse output  (key signal)
//   tb_led_raw                     — mirrors tb_btn_in directly
//
// Test Sequence:
//   1. Reset
//   2. BOUNCY PRESS   — rapid toggles before stable hold  → expect 1 pulse
//   3. CLEAN PRESS    — no bounce at all                  → expect 1 pulse
//   4. SHORT GLITCH   — held shorter than MAX_COUNT       → expect NO pulse
//////////////////////////////////////////////////////////////////////////////////

module debouncer_tb();

    // -------------------------------------------------------------------------
    // Testbench signals
    // -------------------------------------------------------------------------
    reg  tb_clk;
    reg  tb_reset;
    reg  tb_btn_in;
    wire tb_led_debounced;
    wire tb_led_raw;

    // -------------------------------------------------------------------------
    // Instantiate DUT (Device Under Test)
    // -------------------------------------------------------------------------
    lab2_wrapper DUT (
        .clk          (tb_clk),
        .reset_btn    (tb_reset),
        .btn_in       (tb_btn_in),
        .btn_raw      (tb_btn_in),        // tied to same signal for comparison
        .led_debounced(tb_led_debounced),
        .led_raw      (tb_led_raw)
    );

    // -------------------------------------------------------------------------
    // 100 MHz clock generator — period = 10 ns
    // -------------------------------------------------------------------------
    initial tb_clk = 0;
    always  #5 tb_clk = ~tb_clk;

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin

        // --- Initialise ---
        tb_reset  = 1;
        tb_btn_in = 0;

        // --- Hold reset for 10 clock cycles (100 ns) ---
        #100;
        tb_reset = 0;
        #50;                              // settle before any button activity

        // =====================================================================
        // TEST 1 — BOUNCY PRESS
        //   Simulates mechanical contact chatter on press.
        //   The FSM must ignore all bounces and only fire ONE pulse after the
        //   input has been stable for the full MAX_COUNT window.
        //   Expected: exactly one tb_led_debounced pulse.
        // =====================================================================
        $display("[%0t ns] TEST 1: Bouncy press started", $time);

        // Bounce 1 — too short, counter never reaches threshold
        tb_btn_in = 1; #20;               // 2 cycles high   → WAIT_PRESS
        tb_btn_in = 0; #15;               // drops back low  → IDLE, counter resets

        // Bounce 2
        tb_btn_in = 1; #10;               // 1 cycle high    → WAIT_PRESS
        tb_btn_in = 0; #10;               // drops back low  → IDLE, counter resets

        // Bounce 3
        tb_btn_in = 1; #15;               // 1.5 cycles high → WAIT_PRESS
        tb_btn_in = 0; #10;               // drops back low  → IDLE, counter resets

        // Stable hold — longer than MAX_COUNT (20 cycles x 10 ns = 200 ns)
        // Held for 400 ns (40 cycles) to be safe
        tb_btn_in = 1; #400;              // counter reaches 20 → PRESSED → pulse!

        // Bouncy release
        tb_btn_in = 0; #15;
        tb_btn_in = 1; #10;
        tb_btn_in = 0; #15;
        tb_btn_in = 1; #10;

        // Stable release — hold low for 400 ns so FSM returns to IDLE
        tb_btn_in = 0; #400;

        $display("[%0t ns] TEST 1 complete — check for exactly ONE pulse", $time);
        #100;

        // =====================================================================
        // TEST 2 — CLEAN PRESS (no bounce)
        //   A perfect press and release with no chatter.
        //   Expected: exactly one tb_led_debounced pulse.
        // =====================================================================
        $display("[%0t ns] TEST 2: Clean press started", $time);

        tb_btn_in = 1; #400;              // stable press  → PRESSED → pulse
        tb_btn_in = 0; #400;              // stable release → back to IDLE

        $display("[%0t ns] TEST 2 complete — check for exactly ONE pulse", $time);
        #100;

        // =====================================================================
        // TEST 3 — SUB-THRESHOLD GLITCH (should be IGNORED)
        //   Button held for only 100 ns (10 cycles) — less than MAX_COUNT=20.
        //   FSM enters WAIT_PRESS but counter never reaches threshold.
        //   Expected: NO output pulse at all.
        // =====================================================================
        $display("[%0t ns] TEST 3: Sub-threshold glitch started", $time);

        tb_btn_in = 1; #100;              // only 10 cycles — threshold NOT reached
        tb_btn_in = 0; #400;              // release — FSM returns to IDLE quietly

        $display("[%0t ns] TEST 3 complete — verify NO pulse on led_debounced", $time);

        // --- Final idle period ---
        #200;

        $display("[%0t ns] ===== Simulation complete =====", $time);
        $finish;
    end

endmodule