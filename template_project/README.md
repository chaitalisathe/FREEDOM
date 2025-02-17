Points to remember:

- Typical Benchmark module port declaration
  ```
  module myadder( A, B, CI, CO, SUM );
  input A; // Input a
  input B;// Input b
  input CI; // Input cin
  output CO; // Output carry
  output SUM ;// Output sum


  endmodule
  
  ```
- Do not include SRC/sub_module/user_defined_template.v file created from OpenFPGA to our project
- Check instantiation for D flip flop inside memories.v. It should be DFF_user instead of DFF.
