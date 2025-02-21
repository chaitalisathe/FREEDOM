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
This framework has four stages:
1. **Hardware Partitioning**:
In this stage original benchmark design **benchmark.v** is partitioned in two parts such that **asic_benchmark.v** and 		**benchamrk_redacted.v**.

Where **benchmark.v** = **asic_benchmark.v** + **benchamrk_redacted.v**.
Once we decide which part of design needs to be hidden, we need to add ***startprama*** and ***endpragma** at the start and end of that piece of code. 

A script **general_redactor.py**, automatically generates a separate module for redacted portion and names it as  **benchamrk_redacted.v**.


3. 






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
