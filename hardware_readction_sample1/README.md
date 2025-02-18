## Tutorial to run sample project

1. Download **hardware_redaction_sample1** from this project.

> Quartus project and FPGA programming:

2. Open Platform Designer in Quartus project, modify computer_system.qsys file [*Optional*] and then generate HDL.
![image](https://github.com/user-attachments/assets/33c9bfdf-9ca7-4bdd-b4be-0dcaca27722c)


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

Click on Auto detect and select device 5CSXFC6D6

![image](https://github.com/user-attachments/assets/14be1486-8b6b-496f-b296-d655cd1ee1d5)

Program selected device using asic_fpga_myadder_top.sof file

![image](https://github.com/user-attachments/assets/36f575b8-e5c8-4c17-8942-8d96ddc07aef)
   
> HPS programming


To generate golden_output.txt file, first compile *hps_fpga_generate_golden_output.c* file, execute it on DE10 board. Then compile and execute hps_fpga_test.c.

4. Compile *hps_fpga_test.c*
    
```
cd software
make clean
make
```

>[!NOTE] 
>Install Linux on the DE10- Standard Board from the "DE10 Standard_Getting_Started_Guide.pdf" to run Linux on DE10 Standard board provided by Terasic


5. Transfer following files from software folder to HPS using scp command.

	
		fabric_bitstream_golden.bit	# Actual configuration bitstream
		test_vectors.txt		# test vectors (test vectors bits are stored in the order LSB -> MSB, for eg. if input bitwidth is 10, inputs are stored as [0:9]) Input is read from left to right as LSB -> MSB
		golden_output.txt		# golden output for test vectors (golden output bits are stored in the order LSB -> MSB, for eg. if output bitwidth is 10, inputs are stored as [0:9]) Output is read from left to right as LSB -> MSB
		hps_fpga_test			# compiled c program


Run following commands to get IP address of Linux
```
udhcpc
ifconfig
```
Sample command to transfer file from project directory to sample_project directory on Linux

```
scp hps_fpga_test root@192.168.x.y:/home/root/sample_project
```

> Execution
6. Execute c program on DE10- Standard Board 

Go to sample_project folder on linux

```
cd sample_project
./hps_fpga_test
```

