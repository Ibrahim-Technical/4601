`timescale 1ns / 1ps
module lab2_wrapper(
    input  wire clk,
    input  wire reset_btn,
    input  wire btn_in,
    input  wire btn_raw,
    output wire led_debounced,
    output wire led_raw
);
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
    assign led_raw = btn_raw;

    wire btn_out;   // <-- intermediate wire, NOT connected directly to LED

    debouncer_fsm #(
        .MAX_COUNT(100000000)        // 10ms debounce window at 100MHz
    ) u_debouncer (
        .clk     (clk),
        .reset   (reset_btn),
        .btn_in  (btn_sync_1),
        .btn_out (btn_out)           // goes to pulse stretcher, not LED directly
    );
    parameter HOLD_CYCLES = 100_000_000;  // 0.5 sec 

    reg [25:0] hold_counter;
    reg        led_held;

    always @(posedge clk) begin
        if (reset_btn) begin
            hold_counter <= 0;
            led_held     <= 0;
        end else if (btn_out) begin
            // Valid press detected — start holding LED on
            hold_counter <= HOLD_CYCLES;
            led_held     <= 1;
        end else if (hold_counter > 0) begin
            hold_counter <= hold_counter - 1;
        end else begin
            led_held <= 0;
        end
    end

    assign led_debounced = led_held;

endmodule