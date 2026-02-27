`timescale 1ns / 1ps
module lab2_wrapper(
    input  wire clk,            // 100 MHz PL clock     (Pin Y9)
    input  wire reset_btn,      // System Reset — BTND  (Pin R16)
    input  wire btn_in,         // Button to debounce — BTNC (Pin P16)
    input  wire btn_raw,        // Raw reference — BTNR (Pin R18)
    output wire led_debounced,  // FSM debounced output — LD0 (Pin T22)
    output wire led_raw         // Raw bouncing output  — LD1 (Pin T21)
);

    (* ASYNC_REG = "TRUE" *) reg btn_sync_0;
    (* ASYNC_REG = "TRUE" *) reg btn_sync_1;

    always @(posedge clk) begin
        if (reset_btn) begin
            btn_sync_0 <= 1'b0;
            btn_sync_1 <= 1'b0;
        end else begin
            btn_sync_0 <= btn_in;
            btn_sync_1 <= btn_sync_0;   // ← safe synchronised signal for FSM
        end
    end

    assign led_raw = btn_raw;
    debouncer_fsm #(
        .MAX_COUNT(20)               // Restore to 1_000_000 for hardware!
    ) u_debouncer (
        .clk     (clk),
        .reset   (reset_btn),
        .btn_in  (btn_sync_1),              // Synchronised input — NOT raw btn_in
        .btn_out (led_debounced)
    );

endmodule
