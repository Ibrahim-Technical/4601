`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: tb_controller
// DUT:       controller (4-state Moore Debouncer)
//
// Tests:
//   1. Bouncy press   → debounced_pulse fires once after stable window
//   2. Clean press    → debounced_pulse fires once immediately
//   3. Sub-threshold  → press shorter than MAX_COUNT → no pulse
//
// Parameters:
//   MAX_COUNT = 20 (simulation) → 20 cycles × 10ns = 200ns debounce window
//
// Reset: active-HIGH. Drive sw0_raw = 1 for reset, 0 to run.
//////////////////////////////////////////////////////////////////////////////////

module tb_controller;

    // ─── Clock and Stimulus ───────────────────────────────────────────────────
    reg clk_100mhz;
    reg btnc_raw;
    reg sw0_raw;

    // ─── Outputs ──────────────────────────────────────────────────────────────
    wire led0;
    wire led1;   // debounced_pulse - should go HIGH for exactly 1 cycle

    // ─── DUT ──────────────────────────────────────────────────────────────────
    lab3_top #() uut (
        .clk_100mhz (clk_100mhz),
        .btnc_raw   (btnc_raw),
        .sw0_raw    (sw0_raw),
        .led0       (led0),
        .led1       (led1)
    );

    // ─── 100 MHz Clock ────────────────────────────────────────────────────────
    initial clk_100mhz = 0;
    always #5 clk_100mhz = ~clk_100mhz;   // 10ns period

    // ─── Stimulus ─────────────────────────────────────────────────────────────
    initial begin
        // Initialise inputs
        btnc_raw = 0;
        sw0_raw  = 0;

        // ── Reset sequence ───────────────────────────────────────────────────
        // Assert active-HIGH reset for 5 cycles (SW0 slider UP)
        sw0_raw = 1;
        repeat(5) @(posedge clk_100mhz);
        sw0_raw = 0;    // Release reset - FSM now running
        @(posedge clk_100mhz);

        // ════════════════════════════════════════════════════════════════════
        // TEST 1: Bouncy press
        // Simulate mechanical bounce then stable hold.
        // Expect: debounced_pulse fires ONCE after counter reaches MAX_COUNT.
        // ════════════════════════════════════════════════════════════════════
        $display("--- TEST 1: Bouncy press ---");

        // Bounce pattern: rise/fall 3 times
        btnc_raw = 1; #30; btnc_raw = 0; #20;
        btnc_raw = 1; #20; btnc_raw = 0; #20;
        btnc_raw = 1; #20; btnc_raw = 0; #20;

        // Now stable HIGH - hold for longer than MAX_COUNT (20 cycles = 200ns)
        btnc_raw = 1;
        #300;   // 300ns >> 200ns debounce window → PRESSED state reached

        // Release button
        btnc_raw = 0;
        #200;

        // ════════════════════════════════════════════════════════════════════
        // TEST 2: Clean press (no bounce)
        // Expect: debounced_pulse fires ONCE after exactly MAX_COUNT cycles.
        // ════════════════════════════════════════════════════════════════════
        $display("--- TEST 2: Clean press ---");

        btnc_raw = 1;
        #300;   // stable hold well past debounce window

        btnc_raw = 0;
        #200;

        // ════════════════════════════════════════════════════════════════════
        // TEST 3: Sub-threshold glitch
        // Press shorter than MAX_COUNT (< 200ns at simulation speed).
        // Expect: debounced_pulse stays LOW - no pulse generated.
        // ════════════════════════════════════════════════════════════════════
        $display("--- TEST 3: Sub-threshold glitch ---");

        btnc_raw = 1;
        #80;    // 80ns = 8 cycles < MAX_COUNT=20 → timer never fires
        btnc_raw = 0;
        #200;

        $display("--- All tests complete ---");
        $finish;
    end

endmodule
