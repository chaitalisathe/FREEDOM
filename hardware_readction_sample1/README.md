## Tutorial to run sample project

1. Download **hardware_redaction_sample1** from this project.

> Quartus project and FPGA programming:

2. Open Platform Designer in Quartus project, modify computer_system.qsys file [*Optional*] and then generate HDL.

Or 

*Open EDS shell and use following commands to compile qsys and generate HDL*


Go to main project directory where **computer_system.qsys** file is stored using cd command


cd "go to project directory"

```
qsys-generate computer_system.qsys --block-symbol-file --output-directory=/computer_system --family="Cyclone V" --part=5CSXFC6D6F31C6

qsys-generate computer_system.qsys --synthesis=VERILOG --output-directory=/computer_system --family="Cyclone V" --part=5CSXFC6D6F31C6

```
3. Compile quartus project to generate programming bitstream file *asic_fpga_myadder_top.sof* 

Or 

*Open EDS shell and use following commands to compile Quartus project*
cd "go to project directory"

```
quartus_map --read_settings_files=on --write_settings_files=off asic_fpga_myadder_top -c asic_fpga_myadder_top
quartus_fit --read_settings_files=off --write_settings_files=off asic_fpga_myadder_top -c asic_fpga_myadder_top
quartus_asm --read_settings_files=off --write_settings_files=off asic_fpga_myadder_top -c asic_fpga_myadder_top
quartus_sta asic_fpga_myadder_top -c asic_fpga_myadder_top

```

Tcl scripts:
only if quartus_* commands fail during compilation-  

```
tclsh /computer_system/synthesis/submodules/hps_sdram_p0_parameters.tcl
tclsh /computer_system/synthesis/submodules/hps_sdram_p0_pin_assignments.tcl
```
3. Program DE-10 standard FPGA SoC development board using JTAG
    
> HPS programming

4. Compile *hps_fpga_test.c*
    
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
Sample command to transfer file from project directory to sample project directory on Linux

```
scp hps_fpga_test root@192.168.x.y:/home/root/sample_project
```

> Execution
13. Execute c program on DE10- Standard Board 

Go to sample_project flolder on linux

```
cd sample_project
./hps_fpga_test
```

