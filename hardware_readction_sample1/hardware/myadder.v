//-----------------------------------------------------
// Function    : A 1-bit full adder
//-----------------------------------------------------
module myadder(
  input [0:0] A, // Input a
  input [0:0] B, // Input b
  input [0:0] CI, // Input cin
  output [0:0] CO, // Output carry
  output [0:0] SUM // Output sum
);
  assign SUM = A ^ B ^ CI;
  
  //startpragma
  assign CO = (A & B) | (A & CI) | (B & CI); 
  //endpragma
  
endmodule

