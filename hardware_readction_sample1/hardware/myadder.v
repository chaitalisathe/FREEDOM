//-----------------------------------------------------
// Function    : A 1-bit full adder
// This file has pragmas included for redaction process
// comment out pragma for RTL simulation.
//-----------------------------------------------------
module myadder_redacted (
    B,
    CI,
    A,
    CO
);
  input  A; // Input a
  input  B; // Input b
  input  CI; // Input cin
  output CO; // Output carry
  output SUM; // Output sum

  assign SUM = A ^ B ^ CI;
  
startpragma
  assign CO = (A & B) | (A & CI) | (B & CI); 
endpragma
  
endmodule

