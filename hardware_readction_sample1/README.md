Points to remember:

- Typical Benchmark module port declaration
  ```
  module myadder( A, B, CI, CO, SUM );
  input A; // Input a
  input B;// Input b
  input CI; // Input cin
  output CO; // Output carry
  output SUM ;// Output sum


  endmodule
  
  ```


  1. Download **Template_Emulator** from this project.
2. Rename **Template_Emulator** to your preffered *project_name*
   
3. Copy *${benchmark}.v* to this folder
> Hardware redaction: 
4. Redact a portion of design to *${benchmark}_redacted.v* file

Or 

*Run script ====redaction=== to generate benchmark_redacted.v file*
```

```
> eFPGA fabric generation:

5. Generate eFPGA fabric using tutorial given in [OpenFPGA Tool](https://openfpga.readthedocs.io/en/master/tutorials/design_flow/verilog2verification/)
> [!NOTE]
> Update following in *task.conf* file stored at {PATH:OPENFPGA_PATH}/openfpga_flow/tasks/basic_tests/full_testbench/configuration_chain/config/
> 
> 	*openfpga_arch_file* = ${PATH:OPENFPGA_PATH}/openfpga_flow/openfpga_arch/k4_N4_40nm_cc_openfpga.xml
> 
> 	*arch0* = ${PATH:OPENFPGA_PATH}/openfpga_flow/vpr_arch/k4_N4_tileable_40nm.xml
>
> 	*bench0* = ${PATH:OPENFPGA_PATH}/openfpga_flow/benchmarks/benchmark_redacted.v

Run following command to generate eFPGA fabric
```
python3 openfpga_flow/scripts/run_fpga_task.py basic_tests/full_testbench/configuration_chain
 
```


6. Copy **SRC** folder from OpenFPGA tool at path ${PATH:OPENFPGA_PATH}/openfpga_flow/tasks/basic_tests/full_testbench/configuration_chain/*your_folder*
   to **hardware/** folder
7. Copy **fabric_bitstream.bit** file from OpenFPGA tool at path
   ${PATH:OPENFPGA_PATH}/openfpga_flow/tasks/basic_tests/full_testbench/configuration_chain/*your_folder* to **software/** folder.

Remove extra characters other than bits of bitstream.

> Quartus project and FPGA programming:
8. Use Terasic System Builder to generate quartus project

Or

*Run ===generate quartus project === script to generate quartus project.*
```

```
9. Open Platform Designer in Quartus project, modify computer_system.qsys file [*Optional*] and then generate HDL.

Or 

*Open EDS shell and use following command to compile qsys and generate HDL*


Go to main project directory where **computer_system.qsys** file is stored using cd command


cd "go to project directory"

```
qsys-generate computer_system.qsys --block-symbol-file --output-directory=/computer_system --family="Cyclone V" --part=5CSXFC6D6F31C6

qsys-generate computer_system.qsys --synthesis=VERILOG --output-directory=/computer_system --family="Cyclone V" --part=5CSXFC6D6F31C6

```
10. Modify **hardware/user_defined_parameters.sv** file for number of input, output bitwidths, size of bitstream
11. Compile quartus project to generate programming bitstream file *asic_fpga_${benchmark}_top.sof* 

Or 

*Open EDS shell and use following commands to compile Quartus project*

Edit and use proper project name in following commands --asic_fpga_${benchmark}_top--

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
9. Program DE-10 standard FPGA SoC development board using JTAG
    
> HPS programming

10. Modify **software/hps_define.c** for number of input and output bits, size of bitstream 
11. Compile *hps_fpga_test.c*
    
```
cd software
make clean
make
```

> Install Linux on the DE10- Standard Board from the "DE10 Standard_Getting_Started_Guide.pdf" to run Linux on DE1 0_Standard board provided by Terasic


12. Transfer following files from software folder to HPS using scp command.

	
- fabric_bitstream_golden.bit	# Actual configuration bitstream
- test_vectors.txt		# test vectors
- golden_output.txt		# golden output for test vectors
- hps_fpga_test			# copiled c program

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
13. Execute c program on DE10- Standard Board 

Go to sample_project flolder on linux

```
cd sample_project
./hps_fpga_test
```

