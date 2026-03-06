// this is a state regiter which is a flipflop and the number of flip flops depned on the state whidth
always @(posedge clk) begin
    if (reset)
        state <= IDLE;
    else
        state <= next_state;
end

//  this is the combunational logic , addressint every state and output possible


always @(*) begin
    next_state = state;    

    case (state)
        IDLE: begin
            if (btn_sync)
                next_state = WAIT_PRESS;
        end

        WAIT_PRESS: begin
            if (timer_MAX)
                next_state = PRESSED;
            else if (!btn_sync)
                next_state = IDLE;
        end

        PRESSED: begin
            next_state = WAIT_RELEASE;
        end

        WAIT_RELEASE: begin
            if (timer_MAX)
                next_state = IDLE;
        end
    endcase
end


// output in moore 
always @(*) begin
    case (state)
        PRESSED: debounced_out = 1;
        default: debounced_out = 0;
    endcase
end