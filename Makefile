all:
	mkdir -p bin
	java -jar tools/glass.jar -I gen src/COM.asm bin/neonlib.com bin/neonlib.sym

run: all
	openmsx -machine Panasonic_FS-A1GT -ext ide -script openmsx.tcl

run2: all
	openmsx -machine Philips_NMS_8245 -ext ide -script openmsx.tcl
