module emulator_myadder_tb;



// defining flags from FPGA to HPS as constants
// defining flags from HPS  o FPGA as constants

localparam  FLAGF2H_0 = 32'd992;   // Waiting for HPS to generate new bitstream, reset state FPGA is ready to copy bitstream
localparam  FLAGF2H_1 = 32'd32;  // Copy bitstream from AXI bus
localparam  FLAGF2H_2 = 32'd64;  // configuration start
localparam  FLAGF2H_3 = 32'd96;// continue configuration for 32 bits
localparam  FLAGF2H_4 = 32'd128;// Done FPGA configuration. Ready to receive inputs in next 
localparam  FLAGF2H_5 = 32'd160;// copy test inputs
localparam  FLAGF2H_6 = 32'd192;// send test inputs to FPGA-DUT - Start simulation
localparam  FLAGF2H_7 = 32'd224;// continue simulation for #clocks latency period
localparam  FLAGF2H_8 = 32'd256;// done simulation
 
localparam  FLAGH2F_0 = 32'd31; // generating the bitstream
localparam  FLAGH2F_1 = 32'd1; // bitstream is ready to send 32 bits of bitstream is written on pp_out_axi
localparam  FLAGH2F_2 = 32'd2; // waiting for FPGA to load 32 bits onto the test design
localparam  FLAGH2F_3 = 32'd3; // 
localparam  FLAGH2F_4 = 32'd4; // entire bitstream is sent
localparam  FLAGH2F_5 = 32'd5; // sending test input
localparam  FLAGH2F_6 = 32'd6; // Start simulation
localparam  FLAGH2F_7 = 32'd7; // waiting during simulation  
localparam  FLAGH2F_8 = 32'd8; //done all inputs, {next -generatng new bitstream}

// Defining wires and registers for Open FPGA design and test design

// ----- Virtual memory to store the bitstream from HPS -----
parameter BITSTREAM_LENGTH = 'd432;
parameter REMAINDER = 'd13;
reg [0:0] bitstream [BITSTREAM_LENGTH-1:0];
reg [BITSTREAM_LENGTH-1:0] bit_mem;

reg [$clog2(BITSTREAM_LENGTH):0] bit_index; 
reg [$clog2(BITSTREAM_LENGTH >> 5):0] current_bit;

 
reg [31:0] testing ;
reg [0:0] clk;


wire [31:0] pp_in_axi; // This bus is used to send hamming distance between FPGA and design under test
wire [31:0] pp_in_lw_axi ; // We will send flags overs this bus pp_in_lw_axi
wire [31:0] F2H_flag;
//assign pp_in_lw_axi = F2H_flag;

// INPUTS to the FPGA, OUTPUT from HPS

reg [31:0] bits; // we are using pp_out_axi bus to receive bitstream from HPS to FPGA design
 
reg [31:0] H2F_flag; // Read flags from HPS pp_out_lw_axi ; 

// Our new PIO ports
//wire [31:0] my_new_pio_port; // extra output from FPGA to HPS which send EX-ORed data

// ----- Local wires for global ports of FPGA fabric -----
wire [0:0] fpga_prog_clk;
wire [0:0] fpga_set;
wire [0:0] fpga_reset;
wire [0:0] fpga_op_clk;
// ---- Configuration-chain head -----
wire [0:0] ccff_head;
// ---- Configuration-chain tail -----
wire [0:0] ccff_tail;
// ----- Shared inputs -------

wire [2:0] shared_input; // input to ave8
wire [1:0] design_output; 
wire [1:0] myadder_output; 



//-----------------signal initialization --------------------------------//
// #########################################################################

// ----- Begin raw programming clock signal generation -----
initial
	begin
		
		bits = 32'h00000000;
		
		clk = 1'b0;
		
		
	end
always
	begin
		#5	clk = ~ clk;
	end





// --------------------module instantiation ----------------
	controller_ip FSM1_DUT(
	// input signals from HPS
		.clock(clk),
		.HPS_2_FPGA_axi(bits),
		.HPS_2_FPGA_lw_axi(H2F_flag),
		// output from controller flags for HPS
		//.FPGA_2_HPS_axi(pp_in_axi),
		.FPGA_2_HPS_lw_axi(F2H_flag),
		
		// output Signals connecting to FPGA_dut
		
		.test_input(shared_input),
		.prog_clk(fpga_prog_clk),
		.reset(fpga_reset),
		.op_clk(fpga_op_clk),
		.ccff_head(ccff_head),
		
			//input from open FPGA to controller
		.ccff_tail(ccff_tail) );

	//wire [0:31] gfpga_pad_GPIO_PAD;	
		
//	or2_output_verilog TEST_DUT(
//		.a(a_shared_input),
//		.b(b_shared_input),
//		.c(c_fpga),
//		.prog_clk(fpga_prog_clk),
//		.reset(fpga_reset),
//		.clk(fpga_op_clk),
//		.ccff_head(ccff_head),
//		.ccff_tail(ccff_tail)		
//	);

//---- ASIC portion of the design----------------------------		
//############## update this


	
asic_fpga_myadder EMULATOR_DUT ( 
.clk (fpga_op_clk) ,
.f_prog_clk(fpga_prog_clk), 
.f_reset(fpga_reset) ,
.f_ccff_head(ccff_head),
.f_ccff_tail(ccff_tail),
.A(shared_input[0]),
.B(shared_input[1]),
.CI(shared_input[2]),
.SUM(design_output[0]),
.CO(design_output[1])
);	
	
myadder simulator_DUT(
.A(shared_input[0]),
.B(shared_input[1]),	
.CI(shared_input[2]),
.SUM(myadder_output[0]),	
.CO(myadder_output[1])
);

	//################## need to add conditions just like FSM ########################
	
	// ----- Begin bitstream loading during configuration phase -----
	integer i;
	initial begin
	//$readmemb("bitstream.bit", bitstream); //size =100
	$readmemb("/home/chaitali/share/working_emulators/hardware_redaction_sample1/software/fabric_bitstream.bit", bitstream);
// ----- Configuration chain default input -----
	//ccff_head <= 1'b0;
	bit_index = 0;
	
	H2F_flag = FLAGH2F_0 ; 
	
	
	$display("Bitstream is ready to send ");
	current_bit = 0;
	for (i = 0 ; i< BITSTREAM_LENGTH; i= i+ 1)
		bit_mem[i] = bitstream[i];




end
// ----- 'else if' condition is required by Modelsim to synthesis the Verilog correctly -----
always @(posedge clk)begin
	if (F2H_flag == FLAGF2H_0) begin 
		$display("Received Flag 0 from FPGA : requesting  32 bits");
		// sending 32 bts at a time
		
		bits <= bit_mem[current_bit*32 +: 32];
		testing <= 2'd0;
		H2F_flag <=  FLAGH2F_1;
		$display("Sent 32 bits and  Flag 1 raised from HPS ");
		$display("Waiting for FLAG 1 from FPGA- FPGA neeeds to copy 32bits on temp register \n");
		current_bit <= current_bit + 1;
	end	

	else begin
			if (F2H_flag == FLAGF2H_1) begin
				H2F_flag <=  FLAGH2F_2;
				$display(" Flag 1 is raised from FPGA and 32 bits are being configured on FPGA\n");
			end
			
			else if (F2H_flag == FLAGF2H_2) begin
				H2F_flag <=  FLAGH2F_3;
				$display(" Flag 2 is raised from FPGA and 32 bits are being configured on FPGA\n");
			
			end
			
			
			
			
			else begin
					if (F2H_flag == FLAGF2H_3) begin
						
						if (current_bit <= (BITSTREAM_LENGTH >> 5)) begin
		
								$display(" Flag 3 is raised from FPGA and 32 bits configured on FPGA and ready to accept next 32 bits\n");
						
						
								if (current_bit == (BITSTREAM_LENGTH >> 5)) begin
									bits <= bit_mem[current_bit*32 +: REMAINDER];// check the remainder
									H2F_flag <=  FLAGH2F_1;//FLAGH2F_1
									$display("Sent 32 bits and  Flag 2 raised from HPS ");
									$display("Waiting for FLAG 2 from FPGA- FPGA neeeds to copy 32bits on temp register \n");
									$display(" Entire bitstream data is transfered. waiting for FPGA to finish the configuration\n");
									current_bit <= current_bit + 1;
				
				
								end
								else begin
										
											bits <= bit_mem[current_bit*32 +: 32];
											H2F_flag <=  FLAGH2F_1;
											$display("Sent 32 bits and  Flag 2 raised from HPS ");
											$display("Waiting for FLAG 2 from FPGA- FPGA neeeds to copy 32bits on temp register \n");
											current_bit <= current_bit + 1;
										
								end
						end
						
						else begin
						//(current_bit > (BITSTREAM_LENGTH >> 5) ) begin
											H2F_flag <=  FLAGH2F_4;
											$display("FLAG 4 is raised. wait to send teat inputs ");
						end
									
			
					end
						
						// HERE ENDS IF FLAG3
						
						else  begin
										if (F2H_flag == FLAGF2H_4) begin
										
											if(testing < 32'd32) begin
												$display("Sending 32 bits of an input");
												bits <= testing;
												$display("input value %b",testing);
												testing <= testing+ 'd1;
												H2F_flag <= FLAGH2F_5 ; 
											end//if
											else begin
												$display("All test inputs are done, testing done, reset");	
												H2F_flag <= FLAGH2F_0;
												$finish;
											end//else
											
										end // if
										else begin
										// add condition when all inputs are finished
											if(F2H_flag == FLAGF2H_5) begin
											$display("All bits are sent");
											//testing <= testing+ 'd1;
											H2F_flag <= FLAGH2F_6 ; 
											end//if
										
											 else begin
												if(F2H_flag == FLAGF2H_6) begin
													$display("FPGA is running a test, HPS is waiting");
													H2F_flag <= FLAGH2F_7 ;
												end
												else begin
												
													if(F2H_flag == FLAGF2H_7) begin
													$display("read output now");
													$display("output value of C_fpga %b",design_output);
													H2F_flag <= FLAGH2F_8 ;
													end// if
												
												end// else
										
											
											
											
											end//else
										
										
										
										
										end// else
						
						
						
						
						
						
						
						end
					end		
					
					end
	
	end

			
   //end
	

	
 
initial begin
		$dumpfile("myadder_formal_emulator.vcd");
		$dumpvars(1, emulator_myadder_tb);
	end
// ----- END output waveform to VCD file -------

initial begin
	
	$timeformat(-9, 2, "ns", 20);
	$display("Simulation start");
	
// ----- Can be changed by the user for his/her need -------
	#5000
	
	$finish;
end

	
endmodule