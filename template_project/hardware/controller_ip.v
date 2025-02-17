//-----------------------------------------------------
// Design Name : Controller file
// File Name   : controller_ip.v
//-----------------------------------------------------

//-----------------------------------------------------
// Function    : To control HPS and FPGA
//-----------------------------------------------------
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


reg [31:0] bit_mem ; // to copy bitstream in temp array
reg [$clog2(BITSTREAM_LENGTH):0] total_bit_index; // 
reg config_phase; // 1 when cin config_phase
reg config_phase_clock; // 1 when cin config_phase
reg testing_phase; // 1 when in testing phase
reg bit_copy;// copy bitstream onto local mem if 1
reg testinput_copy;// copy test inputs onto local mem if 1
reg prog_bit; // connection with ccff_head


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



always @(*) begin

	if ( HPS_2_FPGA_lw_axi == FLAGH2F_0) begin // FPGA is on
				
				initialize_total_bit_index 	= 1'b0; // check this through-out the design
				config_phase 		= 1'b0;
				testing_phase		= 1'b0;
				bit_copy 			= 1'b0;
				testinput_copy		= 1'b0;
				f2h_flag 			= FLAGF2H_0 ;
				reset_w 				= 1'b1;
			
	
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
 

 
 
endmodule
