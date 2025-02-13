module myadder_redacted (
    B,
    CI,
    A,
    CO
);
input  B;
input CI;
input A;
output CO;
assign CO = (A & B) | (A & CI) | (B & CI);
endmodule

