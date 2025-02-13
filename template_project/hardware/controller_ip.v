// This a state machine does following task-
//1)configuration of OpenFPGA architecture (design under test), 
//2)runs simulation on openfpga and actual design 
//3)compares result with actual design (for now) 
// future- sends results back to HPS, HPS compares results with golden output



module controller_ip( 

		input 				clock,
		input  [31:0]		HPS_2_FPGA_axi,    //(pp_out_axi)
		input [31:0]  		HPS_2_FPGA_lw_axi,// (pp_out_lw_axi)
		// output from controller flags for HPS
		//FPGA_2_HPS_axi(pp_in_axi),
		output  [31:0] FPGA_2_HPS_lw_axi,    //(pp_in_lw_axi)
		
		// output Signals connecting to FPGA_dut
		output [INPUT_LENGTH -1 :0] 		test_input,
		output 				reset,
		output 				op_clk,
		output 				prog_clk,
		output 				ccff_head,
		//output [2:0]     out_counter,
		// input Signals from open FPGA_dut
		input 				ccff_tail );

// defining flags from FPGA to HPS as constants
// defining flags from HPS  o FPGA as constants


//localparam  FLAGF2H_0 = 32'd992;   // Waiting for HPS to generate new bitstream, reset state FPGA is ready to copy bitstream
//localparam  FLAGF2H_1 = 32'd32;  // Copy bitstream from AXI bus
//localparam  FLAGF2H_2 = 32'd64;  // configuration start
//localparam  FLAGF2H_3 = 32'd96;// continue configuration for 32 bits
//localparam  FLAGF2H_4 = 32'd128;// Done FPGA configuration. Ready to receive inputs in next 
//localparam  FLAGF2H_5 = 32'd160;// copy test inputs
//localparam  FLAGF2H_6 = 32'd192;// send test inputs to FPGA-DUT - Start simulation
//localparam  FLAGF2H_7 = 32'd224;// continue simulation for #clocks latency period
//localparam  FLAGF2H_8 = 32'd256;// done simulation
// 
//localparam  FLAGH2F_0 = 32'd31; // generating the bitstream
//localparam  FLAGH2F_1 = 32'd1; // bitstream is ready to send 32 bits of bitstream is written on pp_out_axi
//localparam  FLAGH2F_2 = 32'd2; // waiting for FPGA to load 32 bits onto the test design
//localparam  FLAGH2F_3 = 32'd3; // 
//localparam  FLAGH2F_4 = 32'd4; // entire bitstream is sent
//localparam  FLAGH2F_5 = 32'd5; // sending test input
//localparam  FLAGH2F_6 = 32'd6; // Start simulation
//localparam  FLAGH2F_7 = 32'd7; // waiting during simulation  
//localparam  FLAGH2F_8 = 32'd8; //done all inputs, {next -generatng new bitstream}


// Defining wires and registers for Open FPGA design and test design
//
//parameter BITSTREAM_LENGTH = 'd2626;
//parameter LATENCY = 4;
reg [31:0] bit_mem ; // to copy bitstream in temp array
reg [$clog2(BITSTREAM_LENGTH):0] total_bit_index; // 
//reg [4:0] bit_index; // i
reg config_phase; // 1 when cin config_phase
reg config_phase_clock; // 1 when cin config_phase
reg testing_phase; // 1 when in testing phase
reg bit_copy;// copy bitstream onto local mem if 1
reg testinput_copy;// copy test inputs onto local mem if 1
reg prog_bit; // connection with ccff_head
reg [7:0] input_a;

reg [INPUT_LENGTH -1 :0]  test_reg; // same as a size of test_input
reg [31:0] f2h_flag; // fpga to HPS output
reg done_config;
reg reset_w;
integer  j;
reg [5:0] i; // 32 bits are sent at a time 
reg initialize_total_bit_index;
reg [1:0]gpio_set ;
reg new_input;
reg done_testing;
reg [31:0] latency_counter;
assign test_input = test_reg;
assign reset = reset_w;
assign op_clk = (testing_phase) ? ~clock : 1'b0;
assign ccff_head = prog_bit;
assign FPGA_2_HPS_lw_axi = f2h_flag;
assign prog_clk = (config_phase_clock) ? ~clock : 1'b0;


/**************
always @(posedge clock) begin
if ( HPS_2_FPGA_lw_axi == FLAGH2F_0) begin // FPGA is on
				
				total_bit_index 	<= 'd0; // check this through-out the design
				config_phase 		<= 1'b0;
				testing_phase		<= 1'b0;
				bit_copy 			<= 1'b0;
				testinput_copy		<= 1'b0;
				f2h_flag 			<= FLAGF2H_0 ;
	
	end

	else	begin
			if ( HPS_2_FPGA_lw_axi == FLAGH2F_1) begin // FPGA is ready to receive bitstream, bit_copy =1
					
					
					
					config_phase	 	<= 1'b0;
					testing_phase 		<= 1'b0;					
					bit_copy 			<= 1'b1; /// bitstream is copied onto local memory
					testinput_copy		<= 1'b0;
					f2h_flag 			<= FLAGF2H_1 ; 
			end
			
			else begin
					if ( HPS_2_FPGA_lw_axi == FLAGH2F_2) begin // copy input data onto temp array
					
							
							config_phase	 	<= 1'b1; // start configuration
							
							testing_phase 		<= 1'b0;
							i 						<= 'd0;							
							bit_copy 			<= 1'b0;
							testinput_copy		<= 1'b0;
							f2h_flag 			<= FLAGF2H_2 ; // FPGA is being configured
					end
					
					else begin
					
						if (HPS_2_FPGA_lw_axi == FLAGH2F_3) begin // 
						// shifting until config is done
							if ( done_config == 1'b1 ) begin
								
								
								config_phase 		<= 1'b0;
								bit_copy 			<= 1'b0;
								testing_phase 		<= 1'b0;
								testinput_copy		<= 1'b0;
								f2h_flag 			<= FLAGF2H_3 ;	// FPGA is done with configuration of 32 bits
							end	
							else begin
								
								
								bit_copy 			<= 1'b0;
								config_phase 		<= 1'b1;
								testing_phase 		<= 1'b0;
								testinput_copy		<= 1'b0;
								f2h_flag 			<= FLAGF2H_2 ; // FPGA is being configured
							
							end
							
						end
						else begin
						
							if (HPS_2_FPGA_lw_axi == FLAGH2F_4) begin
									// entire bitstream is loaded onto FPGA design - 
									
									config_phase 		<= 1'b0;
									i 						<= 'd0;
									bit_copy 			<= 1'b0;
									testing_phase 		<= 1'b0;
									testinput_copy		<= 1'b0;
									f2h_flag 			<= FLAGF2H_4 ; 
							
						
							end
							
							else begin
								if (HPS_2_FPGA_lw_axi == FLAGH2F_5) begin
								
										// loading inputs on local memory
										config_phase 		<= 1'b0;
										i 						<= 'd0;
										bit_copy 			<= 1'b0;
										testing_phase 		<= 1'b0;
										testinput_copy		<= 1'b1; // copying inputs from AXI
										f2h_flag 			<= FLAGF2H_5 ; 
								
								
								
								end
								
								else begin
									if (HPS_2_FPGA_lw_axi == FLAGH2F_6)begin // done sennding one test input
										config_phase 		<= 1'b0;
										i 						<= 'd0;
									   bit_copy 			<= 1'b0;
									   testing_phase 		<= 1'b1; // Running FPGA , loading inputs on FPGA
									   testinput_copy		<= 1'b0;
									   f2h_flag 			<= FLAGF2H_6 ; // check output on AXI line
									
									
									
									
									end
									else begin
										if (HPS_2_FPGA_lw_axi == FLAGH2F_7) begin // done with all test inputs
										
											config_phase 		<= 1'b0;
											i 						<= 'd0;
											bit_copy 			<= 1'b0;
											testing_phase 		<= 1'b0; // 
											testinput_copy		<= 1'b0;
											f2h_flag 			<= FLAGF2H_0 ; //  go back to initial state
										
										
										end

									end
									
								end
							end
							
						end
					
					end
				
		end
	
	end
end

**********/
always @(*) begin

	if ( HPS_2_FPGA_lw_axi == FLAGH2F_0) begin // FPGA is on
				
				initialize_total_bit_index 	= 1'b0; // check this through-out the design
				config_phase 		= 1'b0;
				testing_phase		= 1'b0;
				bit_copy 			= 1'b0;
				testinput_copy		= 1'b0;
				f2h_flag 			= FLAGF2H_0 ;
				reset_w 				= 1'b1;
				//out_set           = 3'd0;
	
	end //  if1

	else	begin
			if ( HPS_2_FPGA_lw_axi == FLAGH2F_1) begin // FPGA is ready to receive bitstream, bit_copy =1
					
					
					initialize_total_bit_index 	= 1'b1;
					config_phase	 	= 1'b0;
					testing_phase 		= 1'b0;					
					bit_copy 			= 1'b1; /// bitstream is copied onto local memory
					testinput_copy		= 1'b0;
					f2h_flag 			= FLAGF2H_1 ;
					reset_w 				= 1'b1;
					//out_set           = 3'd0;
			end // if 2
			
			else begin
					if ( HPS_2_FPGA_lw_axi == FLAGH2F_2) begin // HPS is waiting- configuration start
					
							initialize_total_bit_index 	= 1'b1;
							config_phase	 	= 1'b1; // start configuration
							
							testing_phase 		= 1'b0;
							//i 						= 'd0;							
							bit_copy 			= 1'b0;
							testinput_copy		= 1'b0;
							f2h_flag 			= FLAGF2H_2 ; // FPGA is being configured
							reset_w 				= 1'b1;
							new_input			= 1'b0;
							//out_set           = 3'd0;
					end // if3
					
					else begin
					
						if (HPS_2_FPGA_lw_axi == FLAGH2F_3) begin // continue configuration
						// shifting until config is done
							if ( done_config == 1'b1 ) begin
								
								initialize_total_bit_index 	= 1'b1;
								config_phase 		= 1'b0;
								bit_copy 			= 1'b0;
								testing_phase 		= 1'b0;
								testinput_copy		= 1'b0;
								f2h_flag 			= FLAGF2H_3 ;	// FPGA is done with configuration of 32 bits
								reset_w 				= 1'b1;
								new_input			= 1'b1;
								//out_set           = 3'd0;
							end	// if 5
							else begin
								
								initialize_total_bit_index 	= 1'b1;
								bit_copy 			= 1'b0;
								config_phase 		= 1'b1;
								testing_phase 		= 1'b0;
								testinput_copy		= 1'b0;
								f2h_flag 			= FLAGF2H_2 ; // FPGA is being configured
								reset_w 				= 1'b1;
								new_input			= 1'b1;
								//out_set           = 3'd0;
							end // else 4
							
						end // if 4
						else begin
						
							if (HPS_2_FPGA_lw_axi == FLAGH2F_4) begin
									// entire bitstream is loaded onto FPGA design - 
									initialize_total_bit_index 	= 1'b1;
									config_phase 		= 1'b0;
									bit_copy 			= 1'b0;
									testing_phase 		= 1'b0;
									testinput_copy		= 1'b0;
									f2h_flag 			= FLAGF2H_4 ; 
									reset_w 				= 1'b1;
									new_input			= 1'b1;
									//out_set           = 3'd0;
						
							end // if 6
							
							else begin
								if (HPS_2_FPGA_lw_axi == FLAGH2F_5) begin 	// copying a set of input from AXI bus
								
									
										config_phase 		= 1'b0;
										//i 						= 'd0;
										bit_copy 			= 1'b0;
										testing_phase 		= 1'b0;
										testinput_copy		= 1'b1; // copying inputs from AXI
										f2h_flag 			= FLAGF2H_5 ; 
										reset_w 				= 1'b1;
										initialize_total_bit_index 	= 1'b1;
										new_input			= 1'b0;
										//out_set           = 3'd0;
								
								end // if 7
								
								else begin
									if (HPS_2_FPGA_lw_axi == FLAGH2F_6)begin // send one test input
										config_phase 		= 1'b0;
										//i 						= 'd0;
									   bit_copy 			= 1'b0;
									   testing_phase 		= 1'b1; // Running FPGA , loading inputs on FPGA
									   testinput_copy		= 1'b0;
									   f2h_flag 			= FLAGF2H_6 ; // 
										reset_w 				= 1'b0;
										initialize_total_bit_index 	= 1'b1;
										new_input			= 1'b0;
										//out_set           = 3'd0;
									
									
									end // if 8
									else begin
										if (HPS_2_FPGA_lw_axi == FLAGH2F_7) begin // Read output after #clock cycles- go back to read new set of test inputs
											if (done_testing == 1'b1)begin // checks output after # clock cycles (latency counter)
												
																								
													config_phase 		= 1'b0;
													bit_copy 			= 1'b0;
													testing_phase 		= 1'b1; // run simulation
													testinput_copy		= 1'b0;
													f2h_flag 			= FLAGF2H_7 ; // check output on AXI line, read output
													reset_w					= 1'b0;
													initialize_total_bit_index 	= 1'b1;
													new_input			= 1'b0;
													//out_set           = out_set + 'd1;
												
																
											end // if 10
											else begin // continue waiting
											
											
													config_phase 		= 1'b0;
													bit_copy 			= 1'b0;
													testing_phase 		= 1'b1; // run simulation
													testinput_copy		= 1'b0;
													f2h_flag 			= FLAGF2H_6 ; //  Running simulation, until output is ready
													reset_w				= 1'b0;
													initialize_total_bit_index 	= 1'b1;
													new_input			= 1'b0;
													//out_set           = 3'd0;
											end // else 9
																				
										
										
										end// if 9
								
								// condition for h8
										else begin
											
											
												if (HPS_2_FPGA_lw_axi == FLAGH2F_8) begin //done with testing of a test input, ready to receive next test inputs done with testing of one test input , wait for next set of inputs
														initialize_total_bit_index 	= 1'b1;
																		config_phase 		= 1'b0;
																		bit_copy 			= 1'b0;
																		testing_phase 		= 1'b0;
																		testinput_copy		= 1'b0;
																		f2h_flag 			= FLAGF2H_4 ; 
																		reset_w 				= 1'b0;
																		new_input			= 1'b1;
																		//out_set           = 3'd0;
													
												end // if 11
											
											
										end // else 10
	
								
										
									end //else 8
									
								end // esle 7
							end // else 6
							
						end // else 5
					
					
					end // else 3
		
				
		end // else 2
	
	end // else 1
end // always

// copy 32 bits of bitstream onto local memory
always @(posedge clock) begin

	if (bit_copy == 1) 	bit_mem <= HPS_2_FPGA_axi;
	

end // always
 

// Shift bitstream into efpga

always @(posedge clock) begin
	if (initialize_total_bit_index == 0)
				total_bit_index <= 'd0;

	if (config_phase == 1) begin
			
		if (i < 32 && total_bit_index < BITSTREAM_LENGTH ) begin
			
			prog_bit <= bit_mem[i];
			
			i <= i + 1;
			total_bit_index <= total_bit_index + 'd1;
			
			config_phase_clock <= 1'b1;

			done_config <= 1'b0;
			
		end // if
		
		else begin
				done_config <= 1'b1;
				config_phase_clock <= 1'b0;
				//config_phase <= 1'b0;
		end // else
		
		
	
	//else prog_bit <=0;
 	
	end // if
	else begin// to initialize i


		i <= 0;

	end // else
end // always


// shift test data from AXI to test register
always @(posedge clock) begin 
	if (new_input == 1'b1) begin
		gpio_set <= 'd0;
	end
	if (testinput_copy == 1'b1) 	begin
		test_reg[gpio_set*32 +: 32] <= HPS_2_FPGA_axi;
		gpio_set <= gpio_set + 'd1;
	end
 
end // always
 
 
 // Shift test data onto efpga - asssuming test data is already in test_reg
//always @(posedge clock) begin
//
//	if (testing_phase == 1) begin
//			
//		input_a[7:0] <= test_reg[7:0];
//		//input_a[1] <= test_reg[1];
//		
//	end // if
//	else begin
//		//input_a[0] <= 1'bz;
//		input_a[7:0] <= 8'bz;
//	
//	end
//
//end // always
 
//Latency wait cycles == need to update properly

always @(posedge clock) begin

// condition to initialize latency counter
	if (new_input == 1'b1) begin
	
		latency_counter <= 32'd0;
	end
	if (testing_phase == 1) begin
		if(latency_counter < LATENCY) begin
			latency_counter <= latency_counter + 32'd1;
			done_testing <= 1'b0;
		end // if
		else begin
			done_testing <= 1'b1;
			latency_counter <= 32'd0;
		end//else
	end // if

end // always
 
 
// shift test data from AXI to test register
//always @(posedge clock) begin 
//	if (HPS_2_FPGA_lw_axi == FLAGH2F_6) begin
//		out_set <= 3'd0;
//	end
//	if (HPS_2_FPGA_lw_axi == FLAGH2F_8) 	begin
//		
//		out_set <= out_set + 'd1;
//	end
// 
//end // always

 
 
 
 
endmodule