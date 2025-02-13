//-------------------------------------------
//	FPGA Synthesizable Verilog Netlist
//	Description: Netlist Summary
//	Author: Xifan TANG
//	Organization: University of Utah
//	Date: Wed Feb 12 15:59:47 2025
//-------------------------------------------
//----- Time scale -----
`timescale 1ns / 1ps

// ------ Include fabric top-level netlists -----
`include "./SRC/fabric_netlists.v"

`include "myadder.v"
`include "asic_fpga_myadder.v"
`include "controller_ip.v"

`include "./SRC/emulator_myadder_tb.v"
