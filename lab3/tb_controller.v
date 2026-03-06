// File: tb_controller.v
// Purpose: Directed testbench for Lab 3 — extends professor's skeleton
//
// IMPORTANT — Before running simulation:
//   Set MAX_COUNT = 20 inside controller.v
//   Restore MAX_COUNT = 1_000_000 before generating hardware bitstream.
//
// Reset convention (matches lab3_top.v):
//   sw0_raw = 1 → sw0_sync = 1 → rst_n = 0 → controller RESET
//   sw0_raw = 0 → sw0_sync = 0 → rst_n = 1 → controller RUNNING
//
// Signals to add in XSim waveform window:
//   dut/btnc_sync              — after sync2 (shows 2-cycle delay vs btnc_raw)
//   dut/sw0_sync               — after sync2 (shows reset going low)
//   dut/u_ctrl/state           — FSM state register
//   dut/u_ctrl/counter         — debounce counter
//   dut/u_ctrl/timer_done      — threshold flag
//   led0                       — raw bounce (mirrors btnc_raw directly)
//   led1                       — debounced output (FSM result)
//
// Test Sequence:
//   0. RESET          — SW0=1 for 5 cycles → all registers → IDLE/0
//   1. BOUNCY PRESS   — chatter then stable hold    → expect led1 HIGH
//   2. CLEAN PRESS    — no bounce at all            → expect led1 HIGH
//   3. DOUBLE-TAP     — held shorter than MAX_COUNT → expect led1 stays LOW
//                       (the corner case required by the lab spec)

`timescale 1ns/1ps

module tb_controller;

    // ── DUT I/O ──────────────────────────────────────────────────────────────
    reg  clk_100mhz = 1'b0;
    reg  btnc_raw   = 1'b0;
    reg  sw0_raw    = 1'b0;     // sw0_raw=1 asserts reset inside lab3_top
    wire led0;
    wire led1;

    // ── 100 MHz clock ─────────────────────────────────────────────────────────
    always #5 clk_100mhz = ~clk_100mhz;

    // ── Instantiate lab3_top ──────────────────────────────────────────────────
    lab3_top dut (
        .clk_100mhz (clk_100mhz),
        .btnc_raw   (btnc_raw),
        .sw0_raw    (sw0_raw),
        .led0       (led0),
        .led1       (led1)
    );

    // ── Stimulus ──────────────────────────────────────────────────────────────
    initial begin

        // =====================================================================
        // RESET SEQUENCE
        // sw0_raw = 1 → sync2 propagates → sw0_sync=1 → rst_n=0 → FSM held in IDLE
        // Hold for 5 active clock cycles (lab spec requires >= 2-3 cycles).
        // Then release: sw0_raw = 0 → rst_n = 1 → FSM starts running.
        // =====================================================================
        btnc_raw = 1'b0;
        sw0_raw  = 1'b1;        // assert reset

        $display("[%0t ns] RESET: sw0_raw=1 → rst_n=0 asserted", $time);
        repeat(5) @(posedge clk_100mhz);

        sw0_raw = 1'b0;         // release reset — controller now running
        $display("[%0t ns] RESET released: sw0_raw=0 → rst_n=1 → FSM in IDLE", $time);

        // Small settle gap so sync2 propagates reset-release cleanly
        repeat(5) @(posedge clk_100mhz);

        // =====================================================================
        // TEST 1 — BOUNCY PRESS
        // Simulates mechanical contact chatter on press, then stable hold.
        // The FSM must absorb all bounces and only assert led1 after btnc_sync
        // has been continuously high for MAX_COUNT cycles (20 with sim value).
        // Expected: led1 goes HIGH and stays HIGH while button is held.
        // =====================================================================
        #50;
        $display("[%0t ns] TEST 1: Bouncy press — chatter then stable hold", $time);

        // Bounce 1 — 2 cycles high then drops (counter never reaches 20)
        btnc_raw = 1'b1; #20;   // → WAIT_PRESS
        btnc_raw = 1'b0; #15;   // → back to IDLE, counter resets

        // Bounce 2 — 1 cycle high
        btnc_raw = 1'b1; #10;
        btnc_raw = 1'b0; #10;   // → IDLE, counter resets

        // Bounce 3 — ~1 cycle high
        btnc_raw = 1'b1; #15;
        btnc_raw = 1'b0; #10;   // → IDLE, counter resets

        // Stable hold — 400 ns = 40 cycles >> MAX_COUNT=20
        // counter reaches 19 → timer_done → DEBOUNCED → led1=1
        btnc_raw = 1'b1; #400;

        // Bouncy release
        btnc_raw = 1'b0; #15;
        btnc_raw = 1'b1; #10;
        btnc_raw = 1'b0; #15;
        btnc_raw = 1'b1; #10;

        // Stable release — 400 ns so FSM times out and returns to IDLE
        btnc_raw = 1'b0; #400;

        $display("[%0t ns] TEST 1 complete — led1 should have gone HIGH during stable hold", $time);
        #100;

        // =====================================================================
        // TEST 2 — CLEAN PRESS (no bounce)
        // Perfect press and release with zero chatter.
        // Expected: led1 HIGH during full press, LOW after stable release.
        // =====================================================================
        $display("[%0t ns] TEST 2: Clean press — no bounce", $time);

        btnc_raw = 1'b1; #400;  // stable press  → DEBOUNCED → led1=1
        btnc_raw = 1'b0; #400;  // stable release → IDLE → led1=0

        $display("[%0t ns] TEST 2 complete — led1 HIGH then LOW", $time);
        #100;

        // =====================================================================
        // TEST 3 — DOUBLE-TAP / SUB-THRESHOLD GLITCH  (required corner case)
        // Button pressed for only 100 ns = 10 cycles.
        // With MAX_COUNT=20, the counter never reaches timer_done.
        // FSM enters WAIT_PRESS but on early release returns silently to IDLE.
        // Expected: led1 stays LOW throughout — no output pulse at all.
        //
        // This is exactly the "double-tap" scenario described in the lab spec:
        // "a pulse that is only 2 ms high then returns low — FSM should
        //  transition to WAIT_PRESS but return to IDLE upon premature release,
        //  without ever asserting debounced_out."
        // =====================================================================
        $display("[%0t ns] TEST 3: Sub-threshold glitch (double-tap corner case)", $time);

        btnc_raw = 1'b1; #100;  // only 10 cycles — threshold NOT reached (need 20)
        btnc_raw = 1'b0; #400;  // release → FSM returns to IDLE — led1 must stay LOW

        $display("[%0t ns] TEST 3 complete — verify led1 stayed LOW the entire time", $time);

        // ── Final idle period ─────────────────────────────────────────────────
        #200;
        $display("[%0t ns] ===== Simulation complete =====", $time);
        $stop;
    end

endmodule
