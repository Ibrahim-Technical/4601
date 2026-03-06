parameter int MAX_COUNT = 1_000_000;  // 10ms @ 100MHz
reg [19:0] count;
wire timer_MAX;

always @(posedge clk) begin
  if (reset || clr) begin
    count <= 0;
  end else if (en) begin
    if (count == MAX_COUNT-1)
      count <= 0;          
    else
      count <= count + 1;
  end else begin
    count <= 0;            
  end
end

assign timer_MAX = en && (count == MAX_COUNT-1);   