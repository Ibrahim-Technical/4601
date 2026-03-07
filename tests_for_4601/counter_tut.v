module lut7_test(
    input a,b,c,d,e,f,g,
    output y
);

assign y = a ^ b ^ c ^ d ^ e ^ f ^ g;

endmodule