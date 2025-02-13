// parameters file

parameter  FLAGF2H_0 = 32'd992;   // Waiting for HPS to generate new bitstream, reset state FPGA is ready to copy bitstream
parameter  FLAGF2H_1 = 32'd32;  // Copy bitstream from AXI bus
parameter  FLAGF2H_2 = 32'd64;  // configuration start
parameter  FLAGF2H_3 = 32'd96;// continue configuration for 32 bits
parameter  FLAGF2H_4 = 32'd128;// Done FPGA configuration. Ready to receive inputs in next 
parameter  FLAGF2H_5 = 32'd160;// copy test inputs
parameter  FLAGF2H_6 = 32'd192;// send test inputs to FPGA-DUT - Start simulation
parameter  FLAGF2H_7 = 32'd224;// continue simulation for #clocks latency period
parameter  FLAGF2H_8 = 32'd256;// done simulation

parameter  FLAGH2F_0 = 32'd31; // generating the bitstream
parameter  FLAGH2F_1 = 32'd1; // bitstream is ready to send 32 bits of bitstream is written on pp_out_axi
parameter  FLAGH2F_2 = 32'd2; // waiting for FPGA to load 32 bits onto the test design
parameter  FLAGH2F_3 = 32'd3; // 
parameter  FLAGH2F_4 = 32'd4; // entire bitstream is sent
parameter  FLAGH2F_5 = 32'd5; // sending test input
parameter  FLAGH2F_6 = 32'd6; // Start simulation
parameter  FLAGH2F_7 = 32'd7; // waiting during simulation  
parameter  FLAGH2F_8 = 32'd8; //done all inputs, {next -generatng new bitstream}

parameter AXI_PIO_SIZE_BITTSREAM = 'd32;
parameter LW_PIO_SIZE_FLAGS = 'd32;
parameter AXI_PIO_SIZE_INPUTS = 'd32;
