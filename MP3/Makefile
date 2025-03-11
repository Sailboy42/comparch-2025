filename = sine
pcf_file = ../common/iceBlinkPico.pcf

build:
	yosys -p "read_verilog -sv top.sv; synth_ice40 -top top -json top.json"
	nextpnr-ice40 --up5k --package sg48 --json $(filename).json --pcf $(pcf_file) --asc $(filename).asc
	icepack $(filename).asc $(filename).bin

prog: #for sram
	dfu-util --device 1d50:6146 --alt 0 -D $(filename).bin -R

clean:
	del /f top.json top.asc top.bin