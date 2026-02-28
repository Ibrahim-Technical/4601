module FSM_sequence_detecter (
    input  wire x,
    input  wire clk,
    input  wire rst,
    output wire y
);

    // detect a sequence of 10011 without overlapping
    localparam [5:0]
        S0 = 6'b000001,
        S1 = 6'b000010,
        S2 = 6'b000100,
        S3 = 6'b001000,
        S4 = 6'b010000,
        S5 = 6'b100000;

    reg [5:0] state;
    reg [5:0] next_state;

    // Block 1: state register (memory)
    always @(posedge clk) begin
        if (rst)
            state <= S0;
        else
            state <= next_state;
    end

    // Block 2: next-state logic
    always @(*) begin
        next_state = S0;

        case (state)
            S0: next_state = x ? S1 : S0;
            S1: next_state = x ? S1 : S2;
            S2: next_state = x ? S1 : S3;
            S3: next_state = x ? S4 : S0;   
            S4: next_state = x ? S5 : S2;   
            S5: next_state = S0;            
            default: next_state = S0;
        endcase
    end

    // Block 3: Moore output
    assign y = (state == S5);

endmodule