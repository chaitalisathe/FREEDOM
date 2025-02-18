Points to remember:

- To use our hardware redaction (general_redactor.py) script. Please use typical Benchmark module port declaration as follows:
  ```
  module myadder( A, B, CI, CO, SUM );

  input A; // Input a
  input B;// Input b
  input CI; // Input cin
  output CO; // Output carry
  output SUM ;// Output sum


  endmodule

- pragmas cannot be between always blocks
- all always blocks should have begin and end
 
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
> [!NOTE]
> To avoid conflicts between openFPGA fabric and Cyclone V libraries check following:-
>
> 
> - Do not include SRC/sub_module/user_defined_template.v file created from OpenFPGA to our project
> - Check instantiation for D flip flop inside hardware/SRC/sub_module/memories.v. It should be DFF_user instead of DFF.
> - Check module declaration and instantiation for OR2 in hardware/SRC/sub_module/luts.v and hardware/SRC/sub_module/inv_buf_passgate.v file. It should be OR2_user instead of OR2.

## Tutorial 
1. Download **template_project** from this project.
2. Rename **template_project** to your preffered ***project_name***
   
3. Copy ***${benchmark}.v*** to this folder
   
> Hardware redaction:

4. Redact a portion of design to ***${benchmark}_redacted.v*** file

**Or** 

*Run script general_redactor.py to generate benchmark_redacted.v file*
```
python3 general_redactor.py
```

> eFPGA fabric generation:

5. Generate eFPGA fabric using tutorial given in [OpenFPGA Tool](https://openfpga.readthedocs.io/en/master/tutorials/design_flow/verilog2verification/)
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

Run following command to generate eFPGA fabric
```
python3 openfpga_flow/scripts/run_fpga_task.py basic_tests/full_testbench/configuration_chain
 
```
> [!WARNING]
> OpenFPGA verification using iverilog might fail due to discordance for input-output port naming conventions. You can find solution for that on OpenFPGA website.

6. Copy **SRC** folder from OpenFPGA tool at path ${PATH:OPENFPGA_PATH}/openfpga_flow/tasks/basic_tests/full_testbench/configuration_chain/*your_folder*

   to **hardware/** folder
8. Copy **fabric_bitstream.bit** file from OpenFPGA tool at path
   ${PATH:OPENFPGA_PATH}/openfpga_flow/tasks/basic_tests/full_testbench/configuration_chain/*your_folder*

   to **software/** folder.

> [!NOTE]
> Remove extra characters other than bits of bitstream. Rename original bitstream to **fabric_bitstream_golden.bit**

> Integrate ASIC portion and eFPGA fabric
> 
8. Instantiate eFPGA fabric module in ASIC portion of original benchmark to create file ***asic_fpga_${benchmark}.v***
```
for example-

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

// eFPGA fabric module instantiation 
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

**Or** 

Run stitcher.py script. {*Update the script according to port declaration for other eFPGA fabrics than OpenFPGA k4n4 fabric*}

```
python3 stitcher.py
````

> Quartus project and FPGA programming:
8. Use Terasic System Builder to generate quartus project

**Or**

*Run following scripts to generate quartus project and generate the wrapper file*
```
python3 project_gen.py
python3 generate_wrapper.py
```

10. Open Platform Designer in Quartus project, modify computer_system.qsys file [*Optional*] and then generate HDL.

**Or** 

*Open EDS shell and use following commands to compile qsys and generate HDL*


Go to main project directory where **computer_system.qsys** file is stored using cd command


cd "go to project directory"

```
qsys-generate computer_system.qsys --block-symbol-file --output-directory=/computer_system --family="Cyclone V" --part=5CSXFC6D6F31C6

qsys-generate computer_system.qsys --synthesis=VERILOG --output-directory=/computer_system --family="Cyclone V" --part=5CSXFC6D6F31C6

```
11. Modify **hardware/user_defined_parameters.sv** file for number of input, output bitwidths, size of bitstream

> [!NOTE]
> Make sure to include all required design files in project.

12. Compile quartus project to generate programming bitstream file *asic_fpga_${benchmark}_top.sof* 

**Or** 

*Open EDS shell and use following commands to compile Quartus project*

Edit and use proper project name in following commands for ***asic_fpga_${benchmark}_top***

```
quartus_map --read_settings_files=on --write_settings_files=off asic_fpga_${benchmark}_top -c asic_fpga_${benchmark}_top
quartus_fit --read_settings_files=off --write_settings_files=off asic_fpga_${benchmark}_top -c asic_fpga_${benchmark}_top
quartus_asm --read_settings_files=off --write_settings_files=off asic_fpga_${benchmark}_top -c asic_fpga_${benchmark}_top
quartus_sta asic_fpga_${benchmark}_top -c asic_fpga_${benchmark}_top

```

Tcl scripts:
only if quartus_* commands fail during compilation-  

```
tclsh /computer_system/synthesis/submodules/hps_sdram_p0_parameters.tcl
tclsh /computer_system/synthesis/submodules/hps_sdram_p0_pin_assignments.tcl
```
13. Program DE-10 standard FPGA SoC development board using JTAG
> [!NOTE]
> After configuring the FPGA on board, press warm reset HPS button.

> HPS programming

14. Modify **software/hps_define.c** for number of input and output bits, size of bitstream 
15. Compile *hps_fpga_test.c*
    
```
cd software
make clean
make
```

> Install Linux on the DE10- Standard Board from the "DE10 Standard_Getting_Started_Guide.pdf" to run Linux on DE1 0_Standard board provided by Terasic


16. Transfer following files from software folder to HPS using scp command.

		 fabric_bitstream_golden.bit	# Actual configuration bitstream
		 test_vectors.txt		# test vectors
		 golden_output.txt		# golden output for test vectors
		 hps_fpga_test			# copiled c program

> [!NOTE]
> - test_vectors.txt file contains only binary digits.
> 
> - If input is a 10 bit vector, it is stored in LSB -> MSB order inside test_vectors.txt
>
> - Similar case with output.txt file. Output is read from left to right as LSB -> MSB
>
> - If benchmark has multiple input-output vectors, please make sure their connections are proper in asic_fpga_${benchmark}_top.v file. Modify them if needed.

```
// ASIC + FPGA design
asic_fpga_myadder EMULATOR_DUT ( 
.f_op_clk (fpga_op_clk) ,
.f_prog_clk(fpga_prog_clk), 
.f_reset(fpga_reset) ,
.f_ccff_head(ccff_head),
.f_ccff_tail(ccff_tail),
.A(shared_input[0]), // LSB of input stream 
.B(shared_input[1]),
.CI(shared_input[2]), // MSB of input stream
.SUM(design_output[0]), // LSB of output stream
.CO(design_output[1]) // MSB of output stream
);		
	
```



Run following commands to get IP address of Linux
```
udhcpc
ifconfig
```
Sample commamnd to transfer file from project directory to sample project directory on Linux

```
scp hps_fpga_test root@192.168.2.6:/home/root/sample_project
```

> Execution
17. Execute c program on DE10- Standard Board 

Go to sample_project flolder on linux

```
cd sample_project
./hps_fpga_test
```
