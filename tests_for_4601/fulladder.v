module addsub_alu #(
    parameter int N = 4
)(
    input  wire [N-1:0] A,
    input  wire [N-1:0] B,
    input  wire         sub_en,          // 0 = add, 1 = subtract (A - B)
    output wire [N-1:0] Result,
    output wire         CarryOut,         // add: carry-out, sub: 1=no-borrow, 0=borrow
    output wire         UnsignedOverflow, // same as CarryOut for ADD; for SUB it's "no borrow"
    output wire         SignedOverflow,   // valid for signed interpretation
    output wire         Zero,
    output wire         Negative
);

    // Conditional invert of B for subtraction: Bx = B XOR sub_en
    wire [N-1:0] Bx = B ^ {N{sub_en}};

    // Do one unified addition: A + Bx + sub_en
    wire [N:0] sum_ext = {1'b0, A} + {1'b0, Bx} + {{N{1'b0}}, sub_en};

    assign Result   = sum_ext[N-1:0];
    assign CarryOut = sum_ext[N];

    // Unsigned overflow for ADD is carry-out. For SUB, CarryOut indicates "no borrow".
    assign UnsignedOverflow = CarryOut;

    // Signed overflow:
    // ADD: overflow if A and B have same sign, but Result has different sign.
    // SUB: overflow if A and B have different sign, and Result has different sign than A.
    wire a_sign = A[N-1];
    wire b_sign = B[N-1];
    wire r_sign = Result[N-1];

    assign SignedOverflow =
        (!sub_en && (a_sign == b_sign) && (r_sign != a_sign)) ||
        ( sub_en && (a_sign != b_sign) && (r_sign != a_sign));

    // Flags
    assign Zero     = (Result == {N{1'b0}});
    assign Negative = r_sign;

endmodule