`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Course: ELEC4601 - Digital and Embedded Systems Design
// Laboratory 2: Bonus Task Testbench
// Module: bonus_tb
//
// Description:
//   Testbench for bonus_wrapper.
//   Tests short press, long press, and sub-threshold glitch.
//
// Simulation parameters (inside bonus_wrapper):
//   MAX_COUNT      = 20   (debounce: 20 cycles)
//   LONG_THRESHOLD = 200  (long press: 200 cycles = 2000 ns)
//   LED_HOLD       = 100  (LED on: 100 cycles = 1000 ns)
//
// Expected results:
//   TEST 1 — Short press (held 100 cycles < 200 threshold) → led_short pulses
//   TEST 2 — Long  press (held 300 cycles > 200 threshold) → led_long  pulses
//   TEST 3 — Glitch      (held 10  cycles < 20  debounce)  → nothing
//////////////////////////////////////////////////////////////////////////////////

module bonus_tb();

    reg  tb_clk;
    reg  tb_reset;
    reg  tb_btn_in;
    wire tb_led_short;
    wire tb_led_long;

    // -------------------------------------------------------------------------
    // Instantiate DUT
    // -------------------------------------------------------------------------
    bonus_wrapper #(
        .MAX_COUNT      (20),
        .LONG_THRESHOLD (200),
        .LED_HOLD       (100)
    ) DUT (
        .clk       (tb_clk),
        .reset_btn (tb_reset),
        .btn_in    (tb_btn_in),
        .led_short (tb_led_short),
        .led_long  (tb_led_long)
    );

    // -------------------------------------------------------------------------
    // 100 MHz clock
    // -------------------------------------------------------------------------
    initial tb_clk = 0;
    always  #5 tb_clk = ~tb_clk;

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin

        // Reset
        tb_reset  = 1;
        tb_btn_in = 0;
        #100;
        tb_reset = 0;
        #50;

        // =====================================================================
        // TEST 1 — SHORT PRESS
        //   Bouncy press, then hold for 100 cycles (1000 ns) < LONG_THRESHOLD=200
        //   Expected: led_short lights up, led_long stays dark
        // =====================================================================
        $display("[%0t ns] TEST 1: Short press started", $time);

        // Bounces
        tb_btn_in = 1; #20;
        tb_btn_in = 0; #15;
        tb_btn_in = 1; #10;
        tb_btn_in = 0; #10;

        // Stable press — hold for 400ns (40 cycles) to pass debounce (MAX_COUNT=20)
        // Then keep holding for 100 more cycles total hold = short press
        tb_btn_in = 1; #1000;    // 100 cycles total hold — less than LONG_THRESHOLD=200

        // Release
        tb_btn_in = 0; #400;     // stable release

        $display("[%0t ns] TEST 1 complete — led_short should pulse, led_long stays 0", $time);
        #500;

        // =====================================================================
        // TEST 2 — LONG PRESS
        //   Stable press held for 300 cycles (3000 ns) > LONG_THRESHOLD=200
        //   Expected: led_long lights up, led_short stays dark
        // =====================================================================
        $display("[%0t ns] TEST 2: Long press started", $time);

        // Stable press — hold for 3000ns (300 cycles) > LONG_THRESHOLD=200
        tb_btn_in = 1; #3000;

        // Release
        tb_btn_in = 0; #400;

        $display("[%0t ns] TEST 2 complete — led_long should pulse, led_short stays 0", $time);
        #500;

        // =====================================================================
        // TEST 3 — SUB-THRESHOLD GLITCH
        //   Held for only 10 cycles — less than MAX_COUNT=20
        //   FSM never leaves WAIT_PRESS, no press confirmed
        //   Expected: nothing fires
        // =====================================================================
        $display("[%0t ns] TEST 3: Sub-threshold glitch started", $time);

        tb_btn_in = 1; #100;     // 10 cycles only — below debounce threshold
        tb_btn_in = 0; #400;

        $display("[%0t ns] TEST 3 complete — both LEDs should stay dark", $time);

        #200;
        $display("[%0t ns] ===== Bonus simulation complete =====", $time);
        $finish;
    end

endmodule