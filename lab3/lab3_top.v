// File: lab3_top.v
// Board: ZedBoard (Zynq-7000)
// Lab 3: Full FPGA flow + ILA instrumentation
//
// What this provides:
//  - 100 MHz clock port
//  - 2-FF synchronizer for async inputs (BTNC, SW0)
//  - RAW LED path on led0 to visualize mechanical bounce (no sync)
//  - SW0 used as synchronous active-LOW reset for the controller:
//      SW0 slider UP   (sw0_sync = 1) → rst_n = 0 → controller in RESET
//      SW0 slider DOWN (sw0_sync = 0) → rst_n = 1 → controller RUNNING
//  - controller instance driving led1
//  - ILA probe comments (connect after generating ILA IP in Vivado)
//
// IMPORTANT:
//  - Keep ALL logic in the 100 MHz domain for this lab.
//  - ILA MUST be clocked with the same clk_100mhz clock.
//  - Before hardware: restore MAX_COUNT = 1_000_000 in controller.v

module lab3_top (
    input  wire clk_100mhz,   // 100 MHz PL clock (XDC maps this to Y9)
    input  wire btnc_raw,     // Asynchronous push-button (Center, BTNC)
    input  wire sw0_raw,      // Asynchronous slide switch (SW0)
    output wire led0,         // LED0 — RAW button path (shows bounce)
    output wire led1          // LED1 — debounced controller output
);

    // ----------------------------------------------------------------
    // RAW path for real-time visualization of mechanical bounce.
    // DO NOT use btnc_raw directly in control logic. LED only.
    // ----------------------------------------------------------------
    assign led0 = btnc_raw;

    // ----------------------------------------------------------------
    // Synchronizers: make async inputs safe for FSM/control logic.
    // sync2 port names: .async_in / .sync_out (professor's module).
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
    // Reset logic
    // SW0 slider UP   (sw0_sync = 1) → rst_n = 0 → RESET asserted
    // SW0 slider DOWN (sw0_sync = 0) → rst_n = 1 → running normally
    //
    // In hardware: flip SW0 UP to reset the FSM, then DOWN to run.
    // In simulation: drive sw0_raw = 1 for reset, then sw0_raw = 0.
    // ----------------------------------------------------------------
    wire rst_n;
    assign rst_n = ~sw0_sync;

    // ----------------------------------------------------------------
    // Controller (3-block FSM debouncer)
    //
    // MAX_COUNT = 1_000_000 → 10 ms debounce window at 100 MHz.
    //
    // *** SIMULATION / ILA REMINDER ***
    // Set MAX_COUNT = 20 when running XSim or capturing ILA traces.
    // ALWAYS restore to 1_000_000 before generating the final bitstream.
    // ----------------------------------------------------------------
    wire        led1_out;

    // ILA-visible signals exposed from controller (wired to ILA probes below)
    // These are internal to controller.v and kept alive by mark_debug attribute
    // Wire declarations here for ILA instantiation reference:
    //   controller/state      [1:0]
    //   controller/counter    [N:0]
    //   controller/btnc_probe [0:0]

    controller #(
        .MAX_COUNT (1000000)      // ← Restore to 1_000_000 for hardware!
    ) u_ctrl (
        .clk      (clk_100mhz),
        .rst_n    (rst_n),          // SW0 slider drives reset
        .btnc     (btnc_sync),      // synchronized input — NEVER use btnc_raw here
        .led1_out (led1_out)
    );

    assign led1 = led1_out;

    // ----------------------------------------------------------------
    // ILA Probing
    // After running Synthesis → Set Up Debug wizard in Vivado:
    //
    // 1) The wizard will detect signals marked (* mark_debug = "true" *)
    //    inside controller.v: state, counter, btnc_probe.
    // 2) Drag these into the "Nets to Debug" panel.
    // 3) Vivado will auto-insert an ILA core and add entries to lab3.xdc.
    // 4) Re-run Synthesis + Implementation + Generate Bitstream.
    //
    // Alternatively, instantiate ILA manually here after generating
    // ILA IP from IP Catalog:
    //
    // ila_0 u_ila (
    //   .clk    (clk_100mhz),
    //   .probe0 (u_ctrl.state),       // [1:0]
    //   .probe1 (u_ctrl.counter),     // [$clog2(MAX_COUNT):0]
    //   .probe2 (u_ctrl.btnc_probe),  // [0:0]
    //   .probe3 (led1_out)            // [0:0]
    // );
    //
    // NOTE: Use "Set Up Debug" wizard (Step A3 in lab guide) — it is
    // simpler than manual IP instantiation for this lab.
    // ----------------------------------------------------------------

endmodule
