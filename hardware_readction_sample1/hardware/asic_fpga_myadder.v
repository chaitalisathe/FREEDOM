module asic_fpga_myadder( A, B, CI, CO, SUM, f_op_clk, f_prog_clk, f_reset, f_ccff_head, f_ccff_tail);
input  	  A; 
input 	  B; 
input  	  CI; 
output 	  CO; 
output 	  SUM;
input     f_prog_clk;
input     f_reset;
input     f_ccff_head;
output    f_ccff_tail;
input 	  f_op_clk;




assign SUM = A ^ B ^ CI;
  

//fpga fpga_inst (.B(B), .CI(CI), .A(A), .CO(CO));
wire [0:31] gfpga_pad_GPIO_PAD;


fpga_top FPGA_DUT (.prog_clk(f_prog_clk),
.set(1'b0),
.reset(f_reset),
.clk(f_op_clk),
.gfpga_pad_GPIO_PAD(gfpga_pad_GPIO_PAD[0:31]),
.ccff_head(f_ccff_head),
.ccff_tail(f_ccff_tail));

assign gfpga_pad_GPIO_PAD[1] = (f_reset) ? 1'bz  : B;
assign gfpga_pad_GPIO_PAD[4] = (f_reset) ? 1'bz  : CI;
assign gfpga_pad_GPIO_PAD[30] = (f_reset) ? 1'bz : A;
assign CO[0] = gfpga_pad_GPIO_PAD[18];
  
endmodule
