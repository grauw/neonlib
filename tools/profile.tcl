#
# Profiling utility
#
# Start profiling with out (2ch),a, end profiling with out (2dh),a.
# Run the profile command in the openMSX console to see the result.
#
namespace eval profile {
	variable time 0
	variable start_time -1
	variable count 0
	variable ignored 0
	debug set_watchpoint write_io 0x2C {} {profile::start}
	debug set_watchpoint write_io 0x2D {} {profile::stop}
	
	proc start {} {
		variable start_time
		variable ignored
		variable out_overhead
		set out_cycles [expr {"[cpuregs::get_active_cpu]" eq "z80"} ? 12.0 : 5.0]
		set overhead [expr $out_cycles / 3579545]
		if {$start_time == -1} {
			set start_time [expr [machine_info time] + $overhead]
		} else {
			set start_time [expr $start_time + $overhead]
			incr ignored
		}
	}
	
	proc stop {} {
		variable time
		variable start_time
		variable count
		variable ignored
		if {$start_time != -1} {
			set time [expr [machine_info time] - $start_time + $time]
			set start_time -1
			incr count
		} else {
			incr ignored
		}
	}
	
	proc profile {} {
		variable time
		variable count
		variable ignored
		puts "Time: $time, count: $count, ignored: $ignored"
	}
	
	namespace export profile
}

namespace import profile::*
