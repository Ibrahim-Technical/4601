`timescale 1ns / 1ps

module addsub_alu_tb;

    // -----------------------------------------------------------------------
    // Parameters
    // -----------------------------------------------------------------------
    parameter N = 4;

    // -----------------------------------------------------------------------
    // DUT signals
    // -----------------------------------------------------------------------
    reg  [N-1:0] A, B;
    reg          sub_en;
    wire [N-1:0] Result;
    wire         Carry, NoBorrow, SignedOverflow, Zero, Negative;

    // -----------------------------------------------------------------------
    // Instantiate DUT
    // -----------------------------------------------------------------------
    addsub_alu #(.N(N)) dut (
        .A             (A),
        .B             (B),
        .sub_en        (sub_en),
        .Result        (Result),
        .Carry         (Carry),
        .NoBorrow      (NoBorrow),
        .SignedOverflow (SignedOverflow),
        .Zero          (Zero),
        .Negative      (Negative)
    );

    // -----------------------------------------------------------------------
    // Task: print one result row
    // -----------------------------------------------------------------------
    task print_result;
        input [N-1:0] a, b;
        input         op;   // 0=ADD, 1=SUB
        begin
            $display("%s | A=%0d B=%0d | Result=%0d | Carry=%b NoBorrow=%b SignedOvf=%b Zero=%b Neg=%b",
                op ? "SUB" : "ADD",
                $signed(a), $signed(b),
                $signed(Result),
                Carry, NoBorrow, SignedOverflow, Zero, Negative);
        end
    endtask

    // -----------------------------------------------------------------------
    // Task: apply inputs, wait, then print
    // -----------------------------------------------------------------------
    task apply;
        input [N-1:0] a, b;
        input         op;
        begin
            A = a; B = b; sub_en = op;
            #10;
            print_result(a, b, op);
        end
    endtask

    // -----------------------------------------------------------------------
    // Stimulus
    // -----------------------------------------------------------------------
    initial begin
        $display("=== ADD/SUB ALU Testbench (N=%0d) ===\n", N);

        $display("--- Basic Addition ---");
        apply(4'd0,  4'd0,  0);   // 0 + 0 = 0          → Zero
        apply(4'd3,  4'd4,  0);   // 3 + 4 = 7
        apply(4'd7,  4'd1,  0);   // 7 + 1 = 8 (signed ovf: pos+pos=neg)
        apply(4'd15, 4'd1,  0);   // 15 + 1 = 0 (unsigned overflow, carry)

        $display("\n--- Basic Subtraction ---");
        apply(4'd5,  4'd3,  1);   // 5 - 3 = 2
        apply(4'd3,  4'd3,  1);   // 3 - 3 = 0          → Zero
        apply(4'd3,  4'd5,  1);   // 3 - 5 = -2 (borrow)
        apply(4'd0,  4'd1,  1);   // 0 - 1 = -1 (borrow)

        $display("\n--- Signed Overflow Cases ---");
        // ADD: pos + pos = neg  (overflow)
        apply(4'b0111, 4'b0001, 0);   //  7 +  1 =  8 → signed -8
        // ADD: neg + neg = pos  (overflow)
        apply(4'b1000, 4'b1000, 0);   // -8 + -8 = -16 → wraps to 0
        // SUB: pos - neg = neg  (overflow)
        apply(4'b0111, 4'b1000, 1);   //  7 - (-8) = 15 → signed -1
        // SUB: neg - pos = pos  (overflow)
        apply(4'b1000, 4'b0001, 1);   // -8 -  1 = -9 → wraps to 7

        $display("\n--- Edge Cases ---");
        apply(4'd15, 4'd15, 0);   // max + max
        apply(4'd15, 4'd15, 1);   // max - max = 0
        apply(4'd0,  4'd0,  1);   // 0 - 0 = 0
        apply(4'd1,  4'd0,  1);   // 1 - 0 = 1

        $display("\n=== Done ===");
        $finish;
    end

endmodule