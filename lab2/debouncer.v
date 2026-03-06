`timescale 1ns / 1ps
module debouncer_fsm #(
    parameter MAX_COUNT = 100000000          // Use 20 for sim, 1_000_000 for hardware
)(
    input  wire clk,
    input  wire reset,
    input  wire btn_in,               // Must be btn_sync_1 from wrapper
    output wire btn_out
);

    localparam IDLE         = 2'b00;
    localparam WAIT_PRESS   = 2'b01;
    localparam PRESSED      = 2'b10;
    localparam WAIT_RELEASE = 2'b11;

    reg [1:0] state;
    reg [1:0] next_state;

    reg [$clog2(MAX_COUNT):0] counter;
    wire timer_MAX = (counter == MAX_COUNT - 1);
    always @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end
    always @(posedge clk) begin
        if (reset) begin
            counter <= 0;
        end else begin
            case (state)
                WAIT_PRESS: begin
                    if (!btn_in)
                        counter <= 0;           // bounce - restart count
                    else
                        counter <= counter + 1; // stable high - keep counting
                end
                WAIT_RELEASE: begin
                    if (btn_in)
                        counter <= 0;           // bounce back high - restart count
                    else
                        counter <= counter + 1; // stable low - keep counting
                end
                default: counter <= 0;          // IDLE / PRESSED - always reset
            endcase
        end
    end
    always @(*) begin
        next_state = state;

        case (state)

            IDLE: begin
                if (btn_in)
                    next_state = WAIT_PRESS;
            end

            WAIT_PRESS: begin
                if (!btn_in)
                    next_state = IDLE;          // bounce - go back to IDLE
                else if (timer_MAX)
                    next_state = PRESSED;       // stable for full window - confirmed!
            end

            PRESSED: begin
                next_state = WAIT_RELEASE;      // pulse lasts exactly ONE cycle
            end

            WAIT_RELEASE: begin
                if (timer_MAX)
                    next_state = IDLE;          // stable low for full window - done
                // If btn_in=1: counter resets in Block 2, stay here and wait
            end

            default: next_state = IDLE;

        endcase
    end
    assign btn_out = (state == PRESSED) ? 1'b1 : 1'b0;

endmodule