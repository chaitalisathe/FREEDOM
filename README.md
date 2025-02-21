# FREEDOM (FPGA-based Hardware Redaction Emulator)
<a id="readme-top"></a>
Emulation of FPGA-based hardware redaction
<!-- TABLE OF CONTENTS -->
<details>
   <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#introduction">Introduction</a>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#pre-requisites">Pre-requisites</a></li>
        <li><a href="#setup and installation">Setup and Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a>
			   <ul>	
    				<li><a href="#Project Structure"> Project Structure </a></li>
				</ul>
	 </li>
   <!-- <li><a href="#contributing">Contributing</a></li> -->
   <!-- <li><a href="#license">License</a></li> -->
  <li><a href="#contact">Contact</a></li>
   <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>
				
<!-- Introduction -->
## Introduction

Most VLSI design companies are now fabless. This forces them to rely on complex international supply chains that can compromise their Intellectual Property (IP).

One popular approach to address this is through logic locking. One of the problems with traditional locking mechanisms is that the locking circuitry is built into the netlist that the (HW) design company delivers to the foundry, which has now access to the entire design, including the locking mechanism. 

This implies that they could potentially tamper with this circuitry or reverse engineer it to obtain the locking key. An alternative approach is to redact a portion of the hardware design by mapping it to an embedded FPGA (eFPGA).

The unprogrammed design is then sent to be fabricated at an untrusted fab, which can now not reverse engineer the design because they do not have the bitstream configuration that makes the entire chip operate correctly. The bitstream acts in this case as the locking key. 
Hardware redaction is nevertheless not 100% secure, and different attacks have already been proposed.

The main problem with most of these attacks is that they require a long simulation times, but in reality, when applied to the actual hardware, are executed much faster.

Thus, here we introduce a FPGA-based hardware redaction framework to speed up new attacks with the ultimate goal of learning how to build more robust hardware redaction systems.

The framework is composed of an **automated ASIC and FPGA partitioning tool**, generating eFPGA fabric using [**OpenFPGA tool**](https://openfpga.readthedocs.io/en/master/), the mapping of these parts onto a low-cost **FPGA board (Terasic DE10-SoC**)  and a library of **software APIs** that run on the embedded processor of the FPGA in order to launch attacks onto the redacted systems mapped onto the FPGA fabric. 

<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- Getting Started -->
## Getting Started

<!-- Pre-requisites -->
### Pre-requisites


<!-- Tools and softwares -->
#### Tools and softwares
- [OpenFPGA tool](https://openfpga.readthedocs.io/en/master/)
- FPGA Development Tool - [Quartus Prime Lite- Quartus (Quartus Prime 23.1std)](https://www.intel.com/content/www/us/en/software-kit/825278/intel-quartus-prime-lite-edition-design-software-version-23-1-1-for-windows.html)
- Embeddded Tool - [Intel SoC EDS Standard- Intel SoC FPGA Embedded Development Suite Standard Edition 19.1.0.670](https://www.intel.com/content/www/us/en/software-kit/661080/intel-soc-fpga-embedded-development-suite-soc-eds-standard-edition-software-version-20-1-for-linux.html)
- Simulation tool(optional) - [ModelSim-Intel FPGA Edition (includes Starter Edition)](https://www.intel.com/content/www/us/en/software-kit/750666/modelsim-intel-fpgas-standard-edition-software-version-20-1-1.html#:~:text=ModelSim%2DIntel%C2%AE%20FPGA%20Edition%20(includes%20Starter%20Edition))
- python 3.9 or above
- puTTY
- Win32 Disk Imager 

<!-- Hardwares -->
#### Hardwares 
- [Terasic DE10 Standard SoC board](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=1081)
- Network router
- Micros SD Card, at 4GB minimum
- Micros SD Card Card Reader

<p align="right">(<a href="#readme-top">back to top</a>)</p>


 

<!-- Setup and Installation -->
### Setup and Installation
<!--Installation tutorial for above tools and software can be found at -->
- [ ]  Install [OpenFPGA tool](https://www.youtube.com/watch?v=F9sMRmDewM0)
- [ ]  Install Quartus 
- [ ]  Install EDS tool, EDS shell
- [ ]  Setup DE10 board [Install Linux on the board](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&CategoryNo=205&No=1081&PartNo=4#contents)


<p align="right">(<a href="#readme-top">back to top</a>)</p>


<!-- Usage -->
## Usage
Download template_project folder. This folder contains sample scripts and files required to build an emulator.

This framework is divided in four stages:
#### Stage 1. **Hardware Partitioning**:
In this stage original benchmark design **benchmark.v** is partitioned in two parts such that **asic_benchmark.v** and 		**benchamrk_redacted.v**.

Where **benchmark.v** = **asic_benchmark.v** + **benchamrk_redacted.v**.
Once we decide which part of design needs to be hidden, we need to add ***startprama*** and ***endpragma*** at the start and end of that piece of code to be redacted. 

A script **general_redactor.py**, automatically generates a separate module for redacted portion and names it as  **benchamrk_redacted.v**.

General guidelines to use general_redactor.py script:

- Only define name of ports in module's initial declaration as Verilog 1995 standard. Please use following syntax for module port declaration- 
  
  ```
  module myadder( A, B, CI, CO, SUM );

  input A; // Input a
  input B;// Input b
  input CI; // Input cin
  output CO; // Output carry
  output SUM ;// Output sum

  ------------------------	
  -------------------------------
  ---------------------------
  endmodule
  ```

- pragmas cannot be between always blocks.
- all always blocks should have begin and end.
- Do not put **startpragma** and **endpragma** in comments.
  ```
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

  ```
- Refer to following code snippet to understand correct way of using startpragma and endpragma :-
  ```
	always @ ( posedge clk )	
					
		odata_r <= { addsub16u2ot [15] , width_enc_data2_t1 } ;
	always @ ( C_06 or C_05 or C_04 )	
		begin
		M_86_t_c1 = ( ( ~C_04 ) & C_05 ) ;
		M_86_t_c2 = ( ( ~C_04 ) & ( ( ~C_05 ) & C_06 ) ) ;
		M_86_t_c3 = ( ( ~C_04 ) & ( ( ~C_05 ) & ( ~C_06 ) ) ) ;
		M_86_t = ( ( { 3{ C_04 } } & 3'h1 )
			| ( { 3{ M_86_t_c1 } } & 3'h2 )
			| ( { 3{ M_86_t_c2 } } & 3'h3 )
			| ( { 3{ M_86_t_c3 } } & 3'h4 ) ) ;
		end
	
	startpragma
	
	always @ ( M_86_t or width_enc_data2_t1 )	
		begin
		C_adpcm_get_index_delta_t1_c1 = ~width_enc_data2_t1 [2] ;	
		C_adpcm_get_index_delta_t1 = ( ( { 4{ C_adpcm_get_index_delta_t1_c1 } } & 
				4'h1 )	// line#=../../adpcm_encoder.cpp:147
			| ( { 4{ width_enc_data2_t1 [2] } } & { M_86_t , 1'h0 } ) ) ;
		end
	
	endpragma
	
	
	
	always @ ( width_enc_data1_t2 )	// line#=../../adpcm_encoder.cpp:102
		begin
		width_enc_data2_t1_c1 = ~width_enc_data1_t2 [3] ;
		width_enc_data2_t1 = ( ( { 3{ width_enc_data1_t2 [3] } } & 3'h7 )	
			| ( { 3{ width_enc_data2_t1_c1 } } & width_enc_data1_t2 [2:0] ) ) ;
		end
	always @ ( addsub4u_41ot or incr4u1ot or geop16u_11ot )	
		begin
		width_enc_data1_t2_c1 = ~geop16u_11ot ;	
							
		width_enc_data1_t2 = ( ( { 4{ geop16u_11ot } } & incr4u1ot )	
			| ( { 4{ width_enc_data1_t2_c1 } } & addsub4u_41ot )	
			) ;
		end

  ```
*Run script general_redactor.py to generate benchmark_redacted.v file*

Please use name of the benchmark module in place of **${benchmark}**

`cd` go to project_name directory

```
python3 general_redactor.py ${benchmark} startpragma endpragma
```
For example, 

python3 general_redactor.py **myadder** startpragma endpragma

#### Stage 2: eFPGA Fabric gneration and mapping of redacted part on eFPGA fabric using OpenFPGA

- To generate an eFPGA fabric we make use of an open source tool called [OpenFPGA](https://openfpga.readthedocs.io/en/master/).
- OpenFPGA generates an eFPGA fabric, maps redacted design on that fabric and generates a configuration bitstream. 
- This tool provides various eFPGA fabric architectures, for our sample project we are using K4N4 fabric. But we can use any eFPGA 	 
  fabric architecture, provided that eFPGA fabric size fits on given FPGA board.
- We are using full_testbench feature of OpenFPGA tool.
- Generate eFPGA fabric using tutorial given in [OpenFPGA Tool](https://openfpga.readthedocs.io/en/master/tutorials/design_flow/verilog2verification/)
> [!NOTE]
> Update following in *task.conf* file stored at
>
> {PATH:OPENFPGA_PATH}/openfpga_flow/tasks/basic_tests/full_testbench/configuration_chain/config/
> 
> 	[OpenFPGA_SHELL]
> 
> 	*openfpga_arch_file* = ${PATH:OPENFPGA_PATH}/openfpga_flow/openfpga_arch/k4_N4_40nm_cc_openfpga.xml
> 
> 	[ARCHITECTURES]
> 
> 	*arch0* = ${PATH:OPENFPGA_PATH}/openfpga_flow/vpr_arch/k4_N4_tileable_40nm.xml
> 
>	[BENCHMARKS]
>
> 	*bench0* = ${PATH:OPENFPGA_PATH}/openfpga_flow/benchmarks/benchmark_redacted.v
>
> 	[SYNTHESIS_PARAM]
>
> 	bench0_top = benchmark_redacted

*Run following command to generate eFPGA fabric*
```
python3 openfpga_flow/scripts/run_fpga_task.py basic_tests/full_testbench/configuration_chain
 
```

> [!NOTE]
> To avoid conflicts between openFPGA fabric and Cyclone V libraries check following:-
>
> 
> - Do not include SRC/sub_module/user_defined_template.v file created from OpenFPGA to our project
> - Check instantiation for D flip flop inside hardware/SRC/sub_module/memories.v. It should be DFF_user instead of DFF.
> - Check module declaration and instantiation for OR2 in hardware/SRC/sub_module/luts.v and hardware/SRC/sub_module/inv_buf_passgate.v file. It should be OR2_user instead of OR2.

> [!WARNING]
> 
> - Since we are using full_testbench feature, OpenFPGA tool automatically runs verification of that eFPGA fabric using iverilog tool.
> - Although it successfully generates an eFPGA fabric, a verification might fail due to discordance for input-output port naming conventions.
> - If your design has input vectors/buses then use following script in **task.config** file. openfpga_shell_template=${PATH:OPENFPGA_PATH}/openfpga_flow/openfpga_shell_scripts/full_testbench_example_without_ace_script.openfpga
> - You will find more information about this scenario on [OpenFPGA tool](https://github.com/lnis-uofu/OpenFPGA/issues).


#### Stage 3: Integrating ASIC and eFPGA designs
- Once eFPGA fabric is generated we can integrate that onto ASIC portion.
- This can be done by instantiating FPGA_TOP module in **benchamrk.v** design in place of redacted part.
- In this stage we also need to add additional ports related to eFPGA ports {such as- f_op_clk, f_prog_clk, f_reset, f_ccff_head, f_ccff_tail etc} to original benchmark module.
  
> [!NOTE]
> - Any eFPGA fabric can be used provided that all RTL files of eFPGA fabric are available
> - To use other fabric we will need to modify module declaration, port list and connections to FPGA top instantiation in **asic_fpga_benchmark.v**
  
- Consider following code snippet to understand diffenrence between original **benchmark.v** and **asic_fpga_benchmark.v**

```
// original benchamrk -> myadder.v 
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
```
 - Integrated ASIC and eFPGA design
```
// This file is generated using the script "stitcher.py"
// asic_fpga_myadder.v
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
assign CO = gfpga_pad_GPIO_PAD[18];

endmodule
```



#### Stage 4: Creating project on Quartus


#### Stage 5: C programming for HPS



#### STgae 6: Execution and evaluation




<!-- Project Structure -->
### Project Structure
This repository has two main folders-
1. Working benchmark- hardware_redaction_sample1 
2. template_project

> Folder structure and naming conventions for this project
#### A typical top-level directory layout


	project-name/
	
	├── README.md
 
	├── asic_fpga_benchmark_top.v  					# wrapper file for emulator
	
	├── user_defined_parameters.sv 

	├── benchmark.v							# Original benchmark

 	├── asic_fpga_benchmark_top.qpf
	
	├── asic_fpga_benchmark_top.qsf    				# Contains list of all files included in quartus project
	
	├── computer_system.qsys       					# A qsys project 
 
 	├── asic_fpga_benchmark_top.sdc  

  	├── general_redactor.py  					# Script to partition original benchmark into two portions

   	├── general_wrapper.py  					# Script to create general wrapper for emulator

   	├── project_gen.py						# Script to create Quartus project and include necessary design files

	├── stitcher.py  						# To integrate ASIC portion and eFPGA fabric together
	
	├── hardware/  
	
	│   ├── SRC/							#This folder is generated by OpenFPGA tool
	
	│   │   ├── lb/
	
	│   │   ├── routing/
	
	│   │   ├── sub_module/
	
	│   │   └── ... 
	
	│   ├── controller_ip.v 					# FSM controller
	
	│   ├── gpio.v 							# Library file from OpenFPGA
	
	│   ├── dff_user.v 						# Library file from OpenFPGA
	
	│   ├── hex_decoder.v						# 7-seg display Hex decoder

  	│   ├── benchmark_redacted.v					# Redacted portion
	
	│   ├── control_parameters.sv					# control parameters 
	
	│   ├── asic_fpga_benchmark.v					# integrated ASIC benchmark design with eFPGA fabic 
	
	│   └── ... 
	
	├── software/
	
	│   ├── fabric_bitstream.bit
	
	│   ├── fpga_hps_benchmark.c
	
	│   ├── Makefile
	
	│   ├── hps_define.h
	
	│   ├── test_vectors.txt
	
	│   ├── golden_output.txt
	
	│   └── ...
	
	├── computer_system/                       			# Compiled QSYS project
	
	└── ... 


## Contact





<p align="right">(<a href="#readme-top">back to top</a>)</p>
