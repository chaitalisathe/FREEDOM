module myadder_redacted (
    B,
    CI,
    A,
    CO
);
input [0:0] B;
input [0:0] CI;
input [0:0] A;
output [0:0] CO;
assign CO = (A & B) | (A & CI) | (B & CI);
endmodule

