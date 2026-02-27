module addsub_alu #(
    parameter N = 4
)(
    input  wire [N-1:0] A,
    input  wire [N-1:0] B,
    input  wire         sub_en,
    output wire [N-1:0] Result,
    output wire         Carry,         // ADD: carry-out | SUB: 1=no borrow (A >= B unsigned)
    output wire         NoBorrow,      // SUB alias for Carry
    output wire         SignedOverflow,
    output wire         Zero,
    output wire         Negative
);

    // -----------------------------------------------------------------------
    // Core adder: A + (B XOR sub_en) + sub_en
    //   sub_en=0 → A + B       (addition)
    //   sub_en=1 → A + ~B + 1  (subtraction, two's complement)
    // -----------------------------------------------------------------------
    wire [N-1:0] Bx      = B ^ {N{sub_en}};
    wire [N:0]   sum_ext = {1'b0, A} + {1'b0, Bx} + {{N{1'b0}}, sub_en};

    assign Result   = sum_ext[N-1:0];
    assign Carry    = sum_ext[N];
    assign NoBorrow = sum_ext[N];

    // -----------------------------------------------------------------------
    // Signed overflow: carry into MSB XOR carry out of MSB
    // -----------------------------------------------------------------------
    wire [N-1:0] sum_lower = A[N-2:0] + Bx[N-2:0] + sub_en;  // lower N-1 bits
    wire         carry_in_msb = sum_lower[N-1];                // carry into MSB

    assign SignedOverflow = carry_in_msb ^ Carry;

    // -----------------------------------------------------------------------
    // Flags
    // -----------------------------------------------------------------------
    assign Zero     = ~|Result;   // reduction NOR: 1 if all bits zero
    assign Negative = Result[N-1];

endmodule