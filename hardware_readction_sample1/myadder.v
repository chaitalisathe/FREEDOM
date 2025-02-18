//-----------------------------------------------------
// Function    : A 1-bit full adder
//-----------------------------------------------------
module myadder( A, B, CI, CO, SUM );
  input A; // Input a
  input B;// Input b
  input CI; // Input cin
  output CO; // Output carry
  output SUM ;// Output sum
  
  
  assign SUM = A ^ B ^ CI;
  
startpragma
  assign CO = (A & B) | (A & CI) | (B & CI); 
endpragma
  
endmodule

