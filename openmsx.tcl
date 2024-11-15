source tools/profile.tcl
source tools/symbols.tcl

symbols::load gen/neonlib.sym

ext debugdevice
set debugoutput stdout
debug set_watchpoint read_io 0x2E
#debug set_watchpoint write_mem 0x0000 {([debug read ioports 0xA8] & 0x0C) == 0x04}
#debug set_watchpoint read_mem 0x0000 {([debug read ioports 0xA8] & 0x0C) == 0x04}

debug set_bp -once 0xFEDA {} {  # H.STKE
	lassign [get_selected_slot 3] ram_ps ram_ss
	variable pc_in_ram_slot "\[pc_in_slot $ram_ps $ram_ss\]"

	debug set_bp [symbol System_ThrowExceptionWithMessage] $pc_in_ram_slot
}

proc dihaltcallback {} {
	message "DI; HALT detected, which means a hang. You can just as well reset the machine now..." warning
	debug break
}
set di_halt_callback dihaltcallback

diskmanipulator create /tmp/neonlib.dsk 32M
virtual_drive /tmp/neonlib.dsk
diskmanipulator format virtual_drive
diskmanipulator import virtual_drive bin/
virtual_drive eject
hda /tmp/neonlib.dsk

set maxframeskip 100
set throttle off
after time 12 "set throttle on"
