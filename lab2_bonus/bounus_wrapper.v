`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Course: ELEC4601 - Digital and Embedded Systems Design
// Laboratory 2: Bonus Task — Short Press vs Long Press Detection
// Module: bonus_wrapper
//
// Description:
//   Top-level wrapper for short/long press detection.
//   Uses the existing debouncer_fsm for debouncing, then measures
//   how long the button is held after a valid press is confirmed.
//
//   Short Press (< 1 second): LD0 lights up for 0.5 seconds
//   Long  Press (> 1 second): LD1 lights up for 0.5 seconds
//
// Parameters:
//   LONG_THRESHOLD = 100_000_000 cycles = 1 second at 100MHz
//   LED_HOLD       = 50_000_000  cycles = 0.5 seconds at 100MHz
//   For simulation use LONG_THRESHOLD=200, LED_HOLD=100, MAX_COUNT=20
//////////////////////////////////////////////////////////////////////////////////
// parameter MAX_COUNT      = 1_000_000,
// parameter LONG_THRESHOLD = 100_000_000,
// parameter LED_HOLD       = 50_000_000

module bonus_wrapper #(
    parameter MAX_COUNT      = 20,           // debounce window  (20 for sim, 1_000_000 for hw)
    parameter LONG_THRESHOLD = 200,          // long press threshold (200 for sim, 100_000_000 for hw)
    parameter LED_HOLD       = 100           // LED on duration (100 for sim, 50_000_000 for hw)
)(
    input  wire clk,
    input  wire reset_btn,
    input  wire btn_in,
    output reg  led_short,      // LD0 — short press indicator
    output reg  led_long        // LD1 — long press indicator
);

    // -------------------------------------------------------------------------
    // 1) Input Synchronizer — 2-FF chain
    // -------------------------------------------------------------------------
    (* ASYNC_REG = "TRUE" *) reg btn_sync_0;
    (* ASYNC_REG = "TRUE" *) reg btn_sync_1;

    always @(posedge clk) begin
        if (reset_btn) begin
            btn_sync_0 <= 1'b0;
            btn_sync_1 <= 1'b0;
        end else begin
            btn_sync_0 <= btn_in;
            btn_sync_1 <= btn_sync_0;
        end
    end

    // -------------------------------------------------------------------------
    // 2) Debouncer FSM instantiation
    //    btn_out = single 1-cycle pulse when valid press confirmed
    // -------------------------------------------------------------------------
    wire btn_out;

    debouncer_fsm #(
        .MAX_COUNT(MAX_COUNT)
    ) u_debouncer (
        .clk     (clk),
        .reset   (reset_btn),
        .btn_in  (btn_sync_1),
        .btn_out (btn_out)
    );

    // -------------------------------------------------------------------------
    // 3) Hold Duration Counter
    //    Starts counting when btn_out fires (valid press confirmed).
    //    Keeps counting while btn_sync_1 stays HIGH.
    //    Stops when button is released.
    // -------------------------------------------------------------------------
    reg [27:0] hold_counter;
    reg        counting;        // 1 = currently measuring hold duration

    always @(posedge clk) begin
        if (reset_btn) begin
            hold_counter <= 0;
            counting     <= 0;
        end else if (btn_out) begin
            // Valid press just confirmed — start counting hold duration
            hold_counter <= 0;
            counting     <= 1;
        end else if (counting && btn_sync_1) begin
            // Button still held — keep counting
            hold_counter <= hold_counter + 1;
        end else if (counting && !btn_sync_1) begin
            // Button just released — stop counting, decision made below
            counting <= 0;
        end
    end

    // -------------------------------------------------------------------------
    // 4) Short / Long Press Decision + LED Hold
    //    On release (counting falls to 0):
    //      hold_counter < LONG_THRESHOLD → short press → LD0
    //      hold_counter >= LONG_THRESHOLD → long press → LD1
    //    LED stays on for LED_HOLD cycles
    // -------------------------------------------------------------------------
    reg [27:0] short_counter;
    reg [27:0] long_counter;

    // Detect the falling edge of 'counting' = moment of release
    reg counting_prev;
    wire released = (counting_prev && !counting);

    always @(posedge clk) begin
        counting_prev <= counting;
    end

    // Short press LED
    always @(posedge clk) begin
        if (reset_btn) begin
            short_counter <= 0;
            led_short     <= 0;
        end else if (released && (hold_counter < LONG_THRESHOLD)) begin
            // Short press confirmed on release
            short_counter <= LED_HOLD;
            led_short     <= 1;
        end else if (short_counter > 0) begin
            short_counter <= short_counter - 1;
        end else begin
            led_short <= 0;
        end
    end

    // Long press LED
    always @(posedge clk) begin
        if (reset_btn) begin
            long_counter <= 0;
            led_long     <= 0;
        end else if (released && (hold_counter >= LONG_THRESHOLD)) begin
            // Long press confirmed on release
            long_counter <= LED_HOLD;
            led_long     <= 1;
        end else if (long_counter > 0) begin
            long_counter <= long_counter - 1;
        end else begin
            led_long <= 0;
        end
    end

endmodule
