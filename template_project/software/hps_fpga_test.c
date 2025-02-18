//-----------------------------------------------------
// Design Name : HPS and FPGA communication
// File Name   : hps_fpga_test.c
//-----------------------------------------------------

//-----------------------------------------------------
// Function    : Controls communication between HPS and FPGA
//-----------------------------------------------------


///////////////////////////////////////
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/ipc.h> 
#include <sys/shm.h> 
#include <sys/mman.h>
#include <sys/time.h> 
#include <math.h> 
#include <stdbool.h>
#include "hps_define.h"
// main bus; PIO
#define BUS_SIZE  32 // Depends on axi bus size
#define FPGA_AXI_BASE 	0xC0000000
#define FPGA_AXI_SPAN   0x00001000
// main axi bus base
// pointers to memory address on axi bus
void *h2p_virtual_base;
volatile unsigned int * axi_pio_ptr = NULL ; // Sends data to FPGA
volatile unsigned int * axi_pio_read_ptr = NULL ; // reads data from FPGA

volatile unsigned int * axi_pio_write0_ptr = NULL ;
volatile unsigned int * axi_pio_write1_ptr = NULL ;
volatile unsigned int * axi_pio_write2_ptr = NULL ;
volatile unsigned int * axi_pio_write3_ptr = NULL ;
volatile unsigned int * axi_pio_write4_ptr = NULL ;

volatile unsigned int * axi_pio_read0_ptr = NULL ;
volatile unsigned int * axi_pio_read1_ptr = NULL ;
volatile unsigned int * axi_pio_read2_ptr = NULL ;
volatile unsigned int * axi_pio_read3_ptr = NULL ; 
volatile unsigned int * axi_pio_read4_ptr = NULL ;

// lw bus; PIO
#define FPGA_LW_BASE 	0xff200000
#define FPGA_LW_SPAN	0x00001000
// the light weight bus base
void *h2p_lw_virtual_base;
// HPS_to_FPGA FIFO status address = 0
volatile unsigned int * lw_pio_ptr = NULL ;
volatile unsigned int * lw_pio_read_ptr = NULL ;


#define FPGA_PIO_LW_READ    0x10
#define FPGA_PIO_LW_WRITE   0x00

// read offset is 0x10 for both busses
// remember that eaxh axi master bus needs unique address
#define FPGA_PIO_READ	0x10
#define FPGA_PIO_WRITE	0x00
#define NEW_PIO_READ 0x20

// From FPGA to HPS =>input
#define FPGA_PIO_READ0	0x50    
#define FPGA_PIO_READ1	0x60
#define FPGA_PIO_READ2	0x70
#define FPGA_PIO_READ3	0x80
#define FPGA_PIO_READ4	0x90

// From HPS to FPGA => output
#define FPGA_PIO_WRITE0	0xa0
#define FPGA_PIO_WRITE1	0xb0
#define FPGA_PIO_WRITE2	0x20
#define FPGA_PIO_WRITE3	0x30
#define FPGA_PIO_WRITE4	0x40


// Define flags for communication between HPS and FPGA

# define  FLAGF2H_0 992   // Wait for HPS to generate new bitstream
# define  FLAGF2H_1 32  // FPGA is ready to receive bitstream
# define  FLAGF2H_2 64  // Received 32 bits of bitstream and stored to a local register, please wait until next signal
# define  FLAGF2H_3 96// Ready to receive next 32 bits
# define  FLAGF2H_4 128// configuration done and ready to receive inputs
# define  FLAGF2H_5 160// received inputs and running simulation
# define  FLAGF2H_6 192// output (hamming distance sent)
# define  FLAGF2H_7 224// Done with simulation and waiting for new bitstream {next_Wait for HPS to generate new bitstream}
# define  FLAGF2H_8 256// Done with simulation and waiting for new bitstream {next_Wait for HPS to generate new bitstream}

# define  FLAGH2F_0 31 // generating the bitstream
# define  FLAGH2F_1 1 // bitstream is ready to send
# define  FLAGH2F_2 2 // 32 bits of bitstream is written on pp_out_axi
# define  FLAGH2F_3 3 // waiting for FPGA to load 32 bits onto the test design
# define  FLAGH2F_4 4 // bitstream is sent
# define  FLAGH2F_5 5 // sending inputs
# define  FLAGH2F_6 6 // waiting during simulation 
# define  FLAGH2F_7 7 // done all inputs, {next -generatng new bitstream}
# define  FLAGH2F_8 8 // done all inputs, {next -generatng new bitstream}
# define  FLAGH2F_9 9 // done all inputs, {next -generatng new bitstream}




/* int size = 527; // size of bitstream {can be asked as an input from user}
int bus_size = 32; // Depends on axi bus size
int test_vec_size = 5; //input vector size - can be asked as an input
int test_out_size = 2; // output vector size
int num_test_vec = 32; // number of test vectors */


int size = SIZE; // size of bitstream {can be asked as an input from user}
int bus_size = BUS_SIZE; // Depends on axi bus size
int test_vec_size = TEST_VEC_SIZE; //input vector size - can be asked as an input
int test_out_size = TEST_OUT_SIZE; // output vector size

int num_test_vec = NUM_TEST_VEC; // number of test vectors


char bitstream[SIZE]; // defining bitstream - use malloc later
//char* bitstream = malloc((size) * sizeof(char));
int fd; // memory mapping
//int test_vectors[number_of_test_vectors][test_vector_size]; // use malloc later
char test_vectors[NUM_TEST_VEC][TEST_VEC_SIZE]; // 
//int* test_vectors = malloc((num_test_vec * test_vec_size) * sizeof(int)); // define locally	
// define bitstream array as a global array
//int out_vectors[number_of_test_vectors][test_out_size];
char out_vectors[NUM_TEST_VEC][TEST_OUT_SIZE];
int binaryNum[32]; // output dec to binary converter
int hamming_distance ;
void decToBinary(unsigned int n)
{
    // array to store binary number
    
 
    // counter for binary array
    int i = 0;
	int j;
    while (n > 0) {
        // storing remainder in binary array
        binaryNum[i] = n % 2;
        n = n / 2;
        i++;
    }
	for (j = i ; j < 32; j++)
        binaryNum[j] = 0;
 
	
    // printing binary array in reverse order
  //  for ( j = 31; j >= 0; j--)
      //  printf("%d", binaryNum[j]);
}
	

int memory_map(void)
{
		// === get FPGA addresses ==================
    // Open /dev/mem
	if( ( fd = open( "/dev/mem", ( O_RDWR | O_SYNC ) ) ) == -1 ) 	{
		printf( "ERROR: could not open \"/dev/mem\"...\n" );
		return( 1 );
	}
    
	//============================================
    // get virtual addr that maps to physical
	// for light weight AXI bus
	h2p_lw_virtual_base = mmap( NULL, FPGA_LW_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, FPGA_LW_BASE );	
	if( h2p_lw_virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap1() failed...\n" );
		close( fd );
		return(1);
	}
	// Get the addresses that map to the two parallel ports on the light-weight bus
	lw_pio_ptr = (unsigned int *)(h2p_lw_virtual_base);
	lw_pio_read_ptr = (unsigned int *)(h2p_lw_virtual_base + FPGA_PIO_LW_READ);
	
	//============================================
	
	// ===========================================
	// get virtual address for
	// AXI bus addr 
	h2p_virtual_base = mmap( NULL, FPGA_AXI_SPAN, ( PROT_READ | PROT_WRITE ), MAP_SHARED, fd, FPGA_AXI_BASE); 	
	if( h2p_virtual_base == MAP_FAILED ) {
		printf( "ERROR: mmap3() failed...\n" );
		close( fd );
		return(1);
	}
    // Get the addresses that map to the two parallel ports on the AXI bus
	
	axi_pio_ptr =(unsigned int *)(h2p_virtual_base);
	axi_pio_read_ptr =(unsigned int *)(h2p_virtual_base + FPGA_PIO_READ);
	
	axi_pio_write0_ptr = (unsigned int *)(h2p_virtual_base + FPGA_PIO_WRITE0);
	axi_pio_write1_ptr = (unsigned int *)(h2p_virtual_base + FPGA_PIO_WRITE1);
	axi_pio_write2_ptr = (unsigned int *)(h2p_virtual_base + FPGA_PIO_WRITE2);
	axi_pio_write3_ptr = (unsigned int *)(h2p_virtual_base + FPGA_PIO_WRITE3);
	axi_pio_write4_ptr = (unsigned int *)(h2p_virtual_base + FPGA_PIO_WRITE4);
	
	axi_pio_read0_ptr = (unsigned int *)(h2p_virtual_base + FPGA_PIO_READ0);
	axi_pio_read1_ptr = (unsigned int *)(h2p_virtual_base + FPGA_PIO_READ1);
	axi_pio_read2_ptr = (unsigned int *)(h2p_virtual_base + FPGA_PIO_READ2);
	axi_pio_read3_ptr = (unsigned int *)(h2p_virtual_base + FPGA_PIO_READ3);
	axi_pio_read4_ptr = (unsigned int *)(h2p_virtual_base + FPGA_PIO_READ4);
	//============================================
	
	return 0;	
}

int generate_bitstream(void) // black box fuzzer_bitwise 1
{
// bitstream is generated with random numbers 0 and 1, of sie bitstream size.	
	FILE * file1 = fopen("fabric_bitstream_sample.bit", "w");
	int i;
	for( i = 0 ; i< size ; i++ )
	{	
		int num = rand() % 2;
		fprintf(file1, "%d",num);
		if(i < size-1)
		{
			fprintf(file1, "\n");
		}
			
	}
	
	fclose(file1);

return 0;	
}



int read_bitstream(void) // bitwise bitstream read from file
{
	*(lw_pio_ptr) = FLAGH2F_0 ;	// Flag - generating bitstream
	FILE* file = fopen("fabric_bitstream_sample.bit", "r"); 
	if (file == NULL) {
			printf("Error in opening bitstream file");
			return 1;
		}
	char ch;

	
	int j = 0;
	while (j < size)
	{
		ch = fgetc(file);
			
		if ((ch == '0') | (ch == '1')) 
		{
		bitstream[j] = ch;

		j++;
	
		}
			
	
	}
	
	fclose(file);
	//printf("leaving read_bitstream \n");
	
	return 0;	
}

int read_golden_bitstream(void) // bitwise bitstream read from file
{
	*(lw_pio_ptr) = FLAGH2F_0 ;	// Flag - generating bitstream
	FILE* file = fopen("fabric_bitstream_golden.bit", "r"); 
	if (file == NULL) {
			printf("Error in opening golden bitstream file");
			return 1;
		}
	char ch;
	int j = 0;
	while (j < size)
	{
		ch = fgetc(file);
	
		if ((ch == '0') | (ch == '1')) 
		{
		bitstream[j] = ch;
		j++;
	
		}
			
	
	}
	
	fclose(file);
	printf("leaving read_bitstream \n");
	
	return 0;	
}


int readTV(void)
{
	FILE* file1 = fopen("test_vectors.txt", "r"); 
	if (file1 == NULL) {
			printf("Error in opening test vectors file \n");
			return 1;
		}
	char ch;
	char out_ch;
	printf("Reading test vectors:\n" );
	
	int j = 0;
	int i = 0;
	/// read golden output
	while (j < num_test_vec)
	{

		ch = fgetc(file1);
			//printf("value of current ch : %c \n", ch);
			//if (ch == EOF)
				//break;
			
			
		if ((ch == '0') | (ch == '1')) 
			{
			test_vectors[j][i] = ch;
			//printf("value of current test input bit : %c \n", test_vectors[j][i]);
			i++;
			
				if (i == test_vec_size)
				{
					//printf("test vector copying : %d \n", j);
					j++;
					i= 0;
				}
			
			
			
			}
		
	} 
	 
	fclose(file1);
	i=0;
	j=0;
	//printf("Reading Golden output vectors:\n" );
 	FILE* file2 = fopen("golden_output.txt", "r"); 
	if (file2 == NULL) {
			printf("Error in opening golden output file \n");
			return 1;
		}
	while (j < (num_test_vec))
	{

		out_ch = fgetc(file2);
			//printf("value of current out_ch : %c \n", out_ch);
			//if (ch == EOF)
				//break;
			
			
		if ((out_ch == '0') | (out_ch == '1')) 
			{
			out_vectors[j][i] = out_ch;
			//printf("value of current output bit : %c \n", out_vectors[j][i]);
			i++;
				if (i == test_out_size)
				{
					//printf("test output copying : %d \n", j);
					j++;
					i= 0;
				}	
			
			
			}
		
	}  
	fclose(file2);  
	
	printf("leaving test vectors:\n" );
	return 0;	
}


bool compare_results(void)
{
	bool result = true;
	
	char out_ch;
	 
	FILE* file2 = fopen("output.txt", "r"); 
	if (file2 == NULL) {
			printf("Error in opening outputvectors file");
			return 1;
		}
	int j = 0;
	int i = 0;
	char out_current[NUM_TEST_VEC][TEST_OUT_SIZE];
	printf("Comparing current output with golden output:\n" );
	while (j < (num_test_vec))
		{
			out_ch = fgetc(file2);
			//printf("value of current out_ch : %c\n", out_ch);
		
			
			
		if ((out_ch == '0') || (out_ch == '1')) 
			{
			out_current[j][i] = out_ch;
			//printf("value of current output bit : %c\n", out_current[j][i]);
			i++;
			
			if (i == test_out_size)
				{
					//printf("test output copying : %d \n", j);
					j++;
					i= 0;
				}	
				 
			
			}
		

				
		}
		
		 for(j=0 ; j< num_test_vec ; j++)
		{
			for(i=0; i< test_out_size ; i++)
			{
				//printf("%c , %c\n",out_current[j][i],out_vectors[j][i]);
				if(out_current[j][i]!= out_vectors[j][i])
				{
					result = false;
					hamming_distance++;
				}
			}
			
		}
	 

	fclose(file2);
	
return result;
	
}

int main(void)
{
	//char bitstream[100];
	// Declare volatile pointers to I/O registers (volatile 	
	// means that IO load and store instructions will be used 	
	// to access these pointer locations,  

// Declare variables
	int x, y, z, i, j;
	unsigned int n ; 
	int iter = size/bus_size ;
	int test_iter = test_vec_size/ bus_size;
	int output_iter = test_out_size/ bus_size;
	char sub[bus_size]; 
	//char test_io[bus_size];
	int total_iterations = MAX_BITSTREAM_INTERATIONS;
	bool result = true;
    char* bitstream_ptr = malloc((total_iterations * size) * sizeof(char));		
	char ch_0 = '0';
	char ch_1 = '1';
	//printf("bitstream load iteration %d \n", iter);

	unsigned int bits;
/*---------------############################---------------*/
// Memory mapping interface 
	memory_map(); // Done only once
	int bitstream_iteration = 0;
	bool found_match = false;
	int timeout_max = 1000; // Ends program if matching bitstream is re-generated timeout times.
	int timeout = 0;
	int copy = 0;
	readTV();
	unsigned int p = 0;
	unsigned int t = 0;
	unsigned int f= 1;
	while(bitstream_iteration < total_iterations) 
	{
		// state 0 - Generate bitstream
		hamming_distance = 0;
		generate_bitstream(); // Fuzzer generates the bitstream and stores into a fabric_bitstream.bit file
		//read_golden_bitstream(); // fabric_bistream_golden.bit 
		read_bitstream(); // fabric_bitstream_sample.bit
		//printf("out of read loop \n");
		//printf("calling check_bitstream function");
		for( i = 0; i < bitstream_iteration; i++) 
		{
			int match = 0;
			for( j = 0; j < size; j++)
				{
					//printf("%d ", bitstream_ptr[i * size + j]);
					if(bitstream_ptr[i * size + j] != bitstream[j])
					{	
						match = 0;
						break;
					}
					
					else
						match++;
		
				}
			if (match == size)	
			{
				found_match = true;
				timeout++;
				printf("foundmatch , restarting while loop \n");
				break;
			}
			else
			{
			found_match = false;
			timeout = 0;
			}
				
		}
		
		if (found_match == false)
		// store bitstream in data
		{	
		
			for ( j = 0; j < size; j++)
				 bitstream_ptr[bitstream_iteration * size + j] = bitstream[j];
			
			//printf("store bitstream in data \n");
			//bitstream_iteration ++;
		
		
		
			// send status as - bitstream is ready
			*(lw_pio_ptr) = FLAGH2F_0 ; // bitstream is ready to send
			// read ready-ness of FPGA to receive bitstream
			//printf("Flag H0 is raised by HPS - bitstream is ready \n");
			//printf("Waiting for flag to change to - ready to recive from FPGA \n");
			while(1)	// wait until FPGA is ready to receive
			{
				
				if (*(lw_pio_read_ptr) == FLAGF2H_0)// wait until FPGA is ready to receive 
				{break;}
			}
			//printf("Received Flag F0 from FPGA : requesting  32 bits");
			
			// state 1 - sending bitstream 32 bits first time and over iter times
			// send bistream to PIOs
		
			for (  x= 0; x< iter+1  ; x++ )	
				{
					//printf("entering for loop \n");
				//	printf("\n Bitstream is :  %s \n", bitstream);
					
					
					bits = 0;
					for( y =0 ; y< bus_size ; y++)
					{	
				
						if (x == iter)
						{
						if (y < size- (bus_size *iter))
							sub[y] = bitstream[(x*bus_size) + y];
						else 
							sub[y] = '0';
						}
						
						else
							
						sub[y] = bitstream[(x*bus_size) + y];
						
						// numeric conversion
						
						if (sub[y] == '1')
							bits = bits + pow(2,y) ;
						else
							bits = bits + 0 ;
	
						
						//printf("bits adder %d \n", bits);
					}
	
					//printf("%d : 32 bits \n", x);
					//printf("sub %s \n", sub);
					//printf("bits %d \n", bits);
					
					*(axi_pio_ptr) =  bits; // send 32 bits of bitstream LSB [0+i*32 : 0+i*32+31]
					*(lw_pio_ptr)  =  FLAGH2F_1; // send flag for sending 32 bits of bitstream
					
					//printf("Sent 32 bits and  Flag H1 raised from HPS \n");
					// check flag if bitstream is copied
					
					//printf("Waiting for FLAG F1 from FPGA- FPGA neeeds to copy 32bits on temp register \n");
					while(1)	// wait until FPGA is ready to receive next bitstream bits
					{
						if (*(lw_pio_read_ptr) == FLAGF2H_1)
						{
							//printf(" Flag F1 is raised from FPGA and (start configuration)32 bits are being configured on FPGA\n");
							*(lw_pio_ptr) = FLAGH2F_2 ; // waiting for FPGA to finish configurating test design
							//printf(" Flag H2 is raised from HPS and HPS is in wait state \n");
							break;
						}
						
					}
					
					
					while(1)
					{
						
						if (*(lw_pio_read_ptr) == FLAGF2H_2)
						{	
							*(lw_pio_ptr) = FLAGH2F_3 ; 
							//printf(" Flag F2 is raised from FPGA and (continue configuration)32 bits are being configured on FPGA\n");
							break;
						}
					}
					
					while(1)
					{
						
						if (*(lw_pio_read_ptr) == FLAGF2H_3)// check if configuration is finished and FPGA is ready to receive bitstream
						{ 
							//printf(" Flag F3 is raised from FPGA and 32 bits are configured on FPGA, ready to accept next 32 bits \n");
							break;
						}
					}
					
					// process continues till for #iter times - 32 bits data transfered at a time
				}
	
			printf(" Entire bitstream data is transfered. waiting for FPGA to finish the configuration\n");
			while(1)
				{
					if (*(lw_pio_read_ptr) == FLAGF2H_3)// check if configuration is finished and FPGA is ready to receive bitstream
							
						{
							//printf("Flag F3 raised from FPGA, FPGA is fully configured.");
							*(lw_pio_ptr) = FLAGH2F_4 ; // all bits are sent from bitstream
							//printf("Flag 4 is raised. wait to send test inputs");
							
							break;
						}
				}
					
					
			
		
	
		// send test inputs-
		FILE *file_out; 
		file_out = fopen("output.txt", "w");
			//printf("Waiting to send inputs\n");
			while(1)
				{
					if (*(lw_pio_read_ptr) == FLAGF2H_4)// FPGA is ready to receive test inputs
					{	
							//printf("Flag F4 raised by FPGA, sending inputs");	
							break;
					}
				}
				
		
			
			// read one input at a time
				
			
			char temp_input[test_vec_size];
				
			for(z= 0 ; z< num_test_vec ; z++) // accessing one row
				{	
					for(y = 0 ; y < test_vec_size ; y++)
					{
						temp_input[y]= test_vectors[z][y];
				
					}
					
	
					if(test_vec_size <= 32) // if test vector size <= 32
					{
						
						bits = 0;
						for( y =0 ; y< test_vec_size ; y++)
							{
								if (temp_input[y] == '1')
									bits = bits + pow(2,y) ;
								else
									bits = bits + 0 ;
							}
					
					
						*(axi_pio_ptr) =  bits; // send 32 bits of bitstream LSB [0+i*32 : 0+i*32+31]
						*(lw_pio_ptr)  =  FLAGH2F_5; // send flag for sending 32 bits of bitstream
						//printf("Flag H5 is raised by HPS- Sending 32 bits of an input \n")	;
						//printf("Waiting for FLAG F5 from FPGA- FPGA neeeds to copy 32bits of input on register \n");
						while(1)	// wait until FPGA is ready to receive next bitstream bits
							{
								if (*(lw_pio_read_ptr) == FLAGF2H_5)
								{
									//printf(" Flag F5 is raised from FPGA and waiting for rest of test bits\n");
									*(lw_pio_ptr) = FLAGH2F_6 ; // waiting for FPGA to finish configurating test design
									//printf(" Flag H6 is raised from HPS and All bits from one test inputs are sent \n");
									break;
								}
								
							}
							
						while(1)	// wait until FPGA starts testing
							{
								if (*(lw_pio_read_ptr) == FLAGF2H_6)
								{
									//printf(" Flag F6 is raised from FPGA and running testing\n");
									*(lw_pio_ptr) = FLAGH2F_7; // waiting for FPGA to finish testing
									//printf(" Flag H7 is raised from HPS and HPS is waiting until FPGA finishes testing\n");
									break;
								}
								
							}
					

							
							
							while(1)	// wait until FPGA finishes testing
							{
								if (*(lw_pio_read_ptr) == FLAGF2H_7) // output is ready
								{
									//printf("Received output from FPGA for inputs \n");
									//printf("output %d : %d\n",z, *(axi_pio_read_ptr)) ;
									// write onto text file
									//fprintf(file_out, "%d\n", *(axi_pio_read_ptr));
									// reading outputs 32 bits at a time.
									
									
									f= 1;
									i=0;		
									int x1;		
									for ( x1= 0; x1< output_iter+1  ; x1++ )

									{
										
											if( x1 == 0 )
											{
												n = *(axi_pio_read0_ptr);
												
											}	
												
											if( x1 == 1 )
											{
												n = *(axi_pio_read1_ptr);
												
											}	
											if( x1 == 2 )
											{
												n = *(axi_pio_read2_ptr);
												
											}	
											
											if( x1 == 3 )
											{
												n = *(axi_pio_read3_ptr);
												
											}	
											
											if( x1 == 4 )
											{
												n = *(axi_pio_read4_ptr);
												
											}
										
										//n = *(axi_pio_read_ptr); // 
											t = 0;
												while (n > 0) {
													// storing remainder in binary array
															if(n%2 == 0){
																fprintf(file_out, "%c", ch_0);
																//printf("writing %c in output file", ch_0 );
																i++; // global output pointer
																t++; // local output pointer upto 32 bits
																
															}
															else{
																fprintf(file_out, "%c", ch_1);
																//printf("writing %c in output file", ch_1 );
																i++;
																t++;
															}
														
																n = n / 2;
					
															}
																
															if(test_out_size <32)
															{	
																for(j = i ; j< test_out_size;j++) // zero padding
																{
																	fprintf(file_out, "%c", ch_0);
																	i++;
																	//printf("writing %c in output file", ch_0 );
																}
															}
															else // if test_out_size > 32 
															{
																for(j = t ; j< 32;j++) // zero padding
																{
																	fprintf(file_out, "%c", ch_0);
																	i++;
																	//printf("writing %c in output file", ch_0 );
																}
															}
									
									}			
									fprintf(file_out, "\n");		
									//printf(" Flag F7 is raised from FPGA and finished testing \n");
									*(lw_pio_ptr) = FLAGH2F_8 ; // Read all bits of output ready to read next bits 
									//printf(" Flag H8 is raised from HPS and HPS has read the output\n");
									break;
								}
								
							}
					
					
					}
					
					else
					{
					
						for (  x= 0; x< test_iter+1  ; x++ )	
						{
							printf("entering for loop for test_inputs \n");
							
							bits = 0;
								
							if (x == test_iter)
								{
									
									for( y =0 ; y< test_vec_size ; y++)
									{	
									
									
								
									if (temp_input[y] == '1')
										bits = bits + pow(2,y) ;
									else
										bits = bits + 0 ;
			
									}
								}
								
								else 
									
									{
									for( y =0 ; y< bus_size ; y++)
										{
								// numeric conversion
								
										if (temp_input[y] == '1')
											bits = bits + pow(2,y) ;
										else
											bits = bits + 0 ;
										}
									}
								//printf("bits adder %d \n", bits);
							
			
			
			
			
							printf("first remaining bits \n");
							//printf("sub %s \n", sub);
							//printf("bits %d \n", bits);
							
						*(axi_pio_ptr) =  bits; // send 32 bits of bitstream LSB [0+i*32 : 0+i*32+31]
						*(lw_pio_ptr)  =  FLAGH2F_5; // send flag for sending 32 bits of bitstream
						printf("Flag H5 is raised by HPS- Sending 32 bits of an input \n")	;
						printf("Waiting for FLAG F5 from FPGA- FPGA neeeds to copy 32bits of input on register \n");
						
						while(1)	// wait until FPGA is ready to receive next bitstream bits
							{
								if (*(lw_pio_read_ptr) == FLAGF2H_5)
								{
									printf(" Flag F5 is raised from FPGA and waiting for rest of test bits\n");
									break;
								}
								
							}
						
						//// process continues till for #iter times - 32 bits data transfered at a time
						}
						while(1)	// wait until FPGA is ready to receive next bitstream bits
							{
								if (*(lw_pio_read_ptr) == FLAGF2H_5)
								{
									printf(" Flag F5 is raised from FPGA and waiting for rest of test bits\n");
									*(lw_pio_ptr) = FLAGH2F_6 ; // 
									printf(" Flag H6 is raised from HPS and All bits from one test inputs are sent \n");
									break;
								}
								
							}
							
						while(1)	// wait until FPGA starts testing
							{
								if (*(lw_pio_read_ptr) == FLAGF2H_6)
								{
									printf(" Flag F6 is raised from FPGA and running testing\n");
									*(lw_pio_ptr) = FLAGH2F_7 ; // 
									printf(" Flag H7 is raised from HPS and HPS is waiting until FPGA finishes testing\n");
									break;
								}
								
							}
					
							while(1)	// wait until FPGA finishes testing
							{
								if (*(lw_pio_read_ptr) == FLAGF2H_7) // output is ready
								{
									printf("Received output from FPGA for inputs \n");
									printf("output %d : %d %d %d %d %d\n",z, *(axi_pio_read0_ptr),*(axi_pio_read1_ptr),*(axi_pio_read2_ptr),*(axi_pio_read3_ptr),*(axi_pio_read4_ptr)) ;
									// write onto text file
									//fprintf(file_out, "%d\n", *(axi_pio_read_ptr));
									// reading outputs 32 bits at a time.
									
									
									f= 1;
									i=0;		
									int x1;		
									for ( x1= 0; x1< output_iter+1  ; x1++ )

									{
										
											if( x1 == 0 )
											{
												n = *(axi_pio_read0_ptr);
												
											}	
												
											if( x1 == 1 )
											{
												n = *(axi_pio_read1_ptr);
												
											}	
											if( x1 == 2 )
											{
												n = *(axi_pio_read2_ptr);
												
											}	
											
											if( x1 == 3 )
											{
												n = *(axi_pio_read3_ptr);
												
											}	
											
											if( x1 == 4 )
											{
												n = *(axi_pio_read4_ptr);
												
											}
										
										//n = *(axi_pio_read_ptr); // 
											t = 0;
												while (n > 0) {
													// storing remainder in binary array
															if(n%2 == 0){
																fprintf(file_out, "%c", ch_0);
																//printf("writing %c in output file", ch_0 );
																i++; // global output pointer
																t++; // local output pointer upto 32 bits
																
															}
															else{
																fprintf(file_out, "%c", ch_1);
																//printf("writing %c in output file", ch_1 );
																i++;
																t++;
															}
														
																n = n / 2;
					
															}
																
															if(test_out_size <32)
															{	
																for(j = i ; j< test_out_size;j++) // zero padding
																{
																	fprintf(file_out, "%c", ch_0);
																	i++;
																	//printf("writing %c in output file", ch_0 );
																}
															}
															else // if test_out_size > 32 
															{
																for(j = t ; j< 32;j++) // zero padding
																{
																	fprintf(file_out, "%c", ch_0);
																	i++;
																	//printf("writing %c in output file", ch_0 );
																}
															}
									
									}			
									fprintf(file_out, "\n");		
									//printf(" Flag F7 is raised from FPGA and finished testing \n");
									*(lw_pio_ptr) = FLAGH2F_8 ; // Read all bits of output ready to read next bits 
									//printf(" Flag H8 is raised from HPS and HPS has read the output\n");
									break;
								}
								
							}
										
							
						
						
					}	
				
			}// for
		
			//printf("All test inputs are done, testing done, reset \n");
			
			while(1)
			{
			if (*(lw_pio_read_ptr) == FLAGF2H_4)// 
					{		
						*(lw_pio_ptr) = FLAGH2F_0 ;						
						break;
					}
					
			}
			
		// after testing check communication status.
				fclose(file_out);
				
			//break;
		bitstream_iteration ++;
		printf("Current bitstream iteration %d \n",bitstream_iteration);
		result = compare_results();
		if (result == true)
		printf("Leaving comparison, result is TRUE \n");
		else
		printf("Leaving comparison, result is FALSE \n");
		
		
		//printf("Leaving comparison \n");
		char filename[50];
		if (result == true)
			{
			// all outputs match with golden outputs, found bitstream
			// store bitstream as bittsream_found_int(copy)
			//either continue running 1000 iterations and find other possible solutions 
			//or exit after finding first solution
			
			printf("result is true, found the bitstream");
			
			
			   sprintf(filename, "fabric_bitstream_%d.bit", copy);
				FILE * file_ = fopen(filename, "w");
				int i;
				for( i = 0 ; i< size ; i++ )
				{	
					
					fprintf(file_, "%c\n",bitstream[i]);
					
				}
				fclose(file_);
				printf("current file saving number %d \n",copy);
				copy++;
			
			}
	
	
		printf("Hamming distance for current bitstream = %d \n", hamming_distance);
		}
		
		if (timeout >= timeout_max)
		{
			printf("Repeatative bitstream generated ");
			break;
		}
		
		
		
		}
	
	


	// end while(1)
		
	
	
	
	return 0;
	
} // end main

/// /// ///////////////////////////////////// 
/// end /////////////////////////////////////
