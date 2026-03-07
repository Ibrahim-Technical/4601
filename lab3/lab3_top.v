`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Course:  ELEC4601 - Lab 3: FPGA Design Flow and RTL Implementation
// Module:  lab3_top (Top-level wrapper)
//
// What this provides:
//  - 100 MHz clock port
//  - 2-FF synchronizer for async inputs (BTNC, SW0) via sync2.v
//  - RAW LED path on led0 to visualize mechanical bounce (no sync)
//  - SW0 used as synchronous active-HIGH reset for the controller:
//      SW0 slider UP   (sw0_sync = 1) → rst = 1 → controller in RESET
//      SW0 slider DOWN (sw0_sync = 0) → rst = 0 → controller RUNNING
//  - controller instance driving led1 via debounced_pulse
//
// Reset behaviour:
//   In hardware  : Flip SW0 UP to reset the FSM, then DOWN to run.
//   In simulation: Drive sw0_raw = 1 for reset, then sw0_raw = 0.
//
// IMPORTANT:
//  - Keep ALL logic in the 100 MHz domain.
//  - ILA MUST be clocked with the same clk_100mhz clock.
//  - MAX_COUNT = 20  → XSim simulation
//  - MAX_COUNT = 40  → ILA hardware capture
//  - MAX_COUNT = 1_000_000 → timing closure bitstream (10 ms debounce)
//////////////////////////////////////////////////////////////////////////////////

module lab3_top (
    input  wire clk_100mhz,   // 100 MHz PL clock (XDC maps this to Y9)
    input  wire btnc_raw,     // Asynchronous push-button (Center, BTNC)
    input  wire sw0_raw,      // Asynchronous slide switch (SW0)
    output wire led0,         // LED0 - RAW button path (shows mechanical bounce)
    output wire led1          // LED1 - debounced pulse from controller
);

    // ----------------------------------------------------------------
    // RAW path for real-time visualization of mechanical bounce.
    // DO NOT use btnc_raw directly in control logic. LED only.
    // ----------------------------------------------------------------
    assign led0 = btnc_raw;

    // ----------------------------------------------------------------
    // Synchronizers: make async inputs safe for FSM/control logic.
    // Both BTNC and SW0 are mechanical - both must be synchronized.
    // ----------------------------------------------------------------
    wire btnc_sync;
    wire sw0_sync;

    sync2 u_sync_btnc (
        .clk      (clk_100mhz),
        .async_in (btnc_raw),
        .sync_out (btnc_sync)
    );

    sync2 u_sync_sw0 (
        .clk      (clk_100mhz),
        .async_in (sw0_raw),
        .sync_out (sw0_sync)
    );

    // ----------------------------------------------------------------
    // Reset logic - Active-HIGH synchronous reset
    // sw0_sync drives rst directly:
    //   SW0 slider UP   (sw0_sync = 1) → rst = 1 → RESET asserted
    //   SW0 slider DOWN (sw0_sync = 0) → rst = 0 → running normally
    // ----------------------------------------------------------------
    wire rst;
    assign rst = sw0_sync;

    // ----------------------------------------------------------------
    // Controller (4-state Moore debouncer)
    //
    // States: IDLE → WAIT_PRESS → PRESSED → WAIT_RELEASE → IDLE
    // Output: debounced_pulse - HIGH for exactly ONE clock cycle in PRESSED
    //
    // MAX_COUNT parameter:
    //   20        → XSim simulation
    //   40        → ILA hardware capture (fits in 1024-sample window)
    //   1_000_000 → Final hardware timing closure (10 ms debounce)
    // ----------------------------------------------------------------
    wire debounced_pulse;

    controller #(
        .MAX_COUNT (1000000)         // ← Change to 40 for ILA, 1_000_000 for timing
    ) u_ctrl (
        .clk            (clk_100mhz),
        .rst            (rst),          // active-HIGH: sw0_sync
        .btnc           (btnc_sync),    // synchronized - NEVER use btnc_raw here
        .debounced_pulse(debounced_pulse)
    );

    assign led1 = debounced_pulse;

    // ----------------------------------------------------------------
    // ILA Probing
    // Use Vivado "Set Up Debug" wizard after synthesis to insert ILA.
    // Signals marked (* mark_debug = "true" *) in controller.v:
    //   state      [1:0]   - FSM state register
    //   counter    [N:0]   - Debounce counter
    //   btnc_probe [0:0]   - Synchronized button input
    //
    // Do NOT manually instantiate ILA here - use the wizard (Step A3).
    // ----------------------------------------------------------------

endmodule
