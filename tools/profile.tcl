#
# Profiling utility
#
# Usage:
#
# Start profiling a section with in a,(2ch), end with out (2ch),a. ID in A.
# Start profiling a frame with in a,(2dh), end with out (2dh),a.
# Every time a frame starts, all section times are reset.
#
# Details:
#
# With this utility you can profile the time spent in up to 257 sections of your
# code. To measure a section you need to instrument it with I/O instructions to
# indicate the start and end of the section.
#
# The first 256 sections are instrumented with I/O port 2CH, read with “in” to
# start the section and write with “out” to end it. The section number is
# specified as the MSB of the 16-bit I/O address, a little known Z80 feature
# (see the Z80 manual). With out (n),a and in a,(n) the section number is
# specified in register A, with out (c),r and in r,(c) in register B.
#
# The remaining section is the “frame section”, instrumented with I/O port 2DH.
# It is started with “in” and ended with “out”, but does not need a section
# number. This section is treated as a frame delimiter, every time this section
# starts all section times are reset.
#
# Console commands:
#
# profile_osd - show the on-screen display of the current frame time.
# profile - show the detailed current profiling status in the console.
#
# See help <command> for more information.
#
# Legend: the “frame” value indicates the time spent in the last frame, the
# “current” value shows the currently accumulated time, the “count” value shows
# the number of times a section was started, and finally the “balance” value
# shows whether the CPU is currently in a section. If sections are not started
# or ended consistently, this value will ever-increase or ever-decrease.
#
namespace eval profile {
	variable slots [dict create]
	variable frame_start_time 0
	variable frame_total_time 0
	variable frame_break false
	variable width 40
	variable height 8
	variable osd_unit %

	debug set_watchpoint read_io 0x2C {} [namespace code {
		slot_begin [expr $::wp_last_address >> 8]
	}]

	debug set_watchpoint write_io 0x2C {} [namespace code {
		slot_end [expr $::wp_last_address >> 8]
	}]

	debug set_watchpoint read_io 0x2D {} [namespace code {
		frame_begin
		slot_begin frame
	}]

	debug set_watchpoint write_io 0x2D {} [namespace code {
		slot_end frame
	}]

	proc slots_create {slotids} {
		foreach slotid $slotids {
			slot_create $slotid
		}
	}

	proc slot_create {slotid} {
		variable slots
		if {![dict exists $slots $slotid]} {
			dict set slots $slotid [dict create total_time 0 start_time -1 count 0 balance 0 frame_time 0]
		}
	}

	proc slot_with {slotid body} {
		variable slots
		slot_create $slotid
		dict with slots $slotid $body
	}

	proc slot_begin {slotid} {
		slot_with $slotid {
			if {$balance == 0} {
				set start_time [machine_info time]
			}
			incr balance
			incr count
		}
	}

	proc slot_end {slotid} {
		slot_with $slotid {
			if {$balance == 1} {
				set total_time [expr $total_time + [machine_info time] - $start_time]
			}
			incr balance -1
		}
	}

	proc slot_flush_frame {slotid} {
		slot_with $slotid {
			set time [machine_info time]
			set frame_time [expr $total_time + ($balance > 0 ? $time - $start_time : 0)]
			set total_time 0
			set start_time $time
		}
	}

	proc frame_begin {} {
		variable slots
		variable frame_start_time
		variable frame_total_time
		variable frame_break
		set time [machine_info time]
		set frame_total_time [expr $time - $frame_start_time]
		set frame_start_time $time
		foreach slotid [dict keys $slots] {
			slot_flush_frame $slotid
		}
		osd_update
		if ($frame_break) {
			set frame_break false
			debug break
		}
	}

	proc osd_update {} {
		if {![osd exists profile]} {
			return
		}
		variable slots
		set index 0
		foreach slotid [dict keys $slots] {
			slot_with $slotid {
				upvar index index
				variable width
				variable height
				variable frame_total_time
				variable osd_unit

				set fraction [expr $frame_total_time != 0 ? $frame_time / $frame_total_time : 0]

				if {![osd exists profile.$slotid]} {
					set rgba [osd_hya [expr $index * 0.14] 0.5 1.0]
					osd create rectangle profile.$slotid -x 0 -y 0 -w $width -h $height -scaled true -clip true -rgba 0x00000088
					osd create rectangle profile.$slotid.bar -x 0 -y 0 -w 0 -h $height -scaled true -rgba $rgba
					osd create text profile.$slotid.text -x 2 -y 1 -size 5 -scaled true -rgba 0xffffffff
				}

				osd configure profile.$slotid -x [expr ($index * $height / 240) * $width] -y [expr $index * $height % 240]
				osd configure profile.$slotid.bar -w [expr ($fraction < 0 ? 0 : $fraction > 1 ? 1 : $fraction) * $width]

				if {$osd_unit eq "s"} {
					set text [format "%s: %.3f s" $slotid $frame_time]
				} elseif {$osd_unit eq "ms"} {
					set text [format "%s: %.2f ms" $slotid [to_ms $frame_time]]
				} elseif {$osd_unit eq "t"} {
					set text [format "%s: %d T" $slotid [to_cycles $frame_time]]
				} else {
					set text [format "%s: %00.2f%%" $slotid [expr $fraction * 100]]
				}
				osd configure profile.$slotid.text -text $text
			}
			incr index
		}
	}

	proc osd_hya {h y a} {
		set h [expr ($h - floor($h)) * 8.0]
		osd_yuva $y [expr $h < 2.0 ? -1.0 : $h < 4.0 ? $h - 3.0 : $h < 6.0 ? 1.0 : 7.0 - $h] \
		            [expr $h < 2.0 ? $h - 1.0 : $h < 4.0 ? 1.0 : $h < 6.0 ? 5.0 - $h : -1.0] $a
	}

	proc osd_yuva {y u v a} {
		set r [fraction_to_uint8 [expr $y + 1.28033 * 0.615 * $v]]
		set g [fraction_to_uint8 [expr $y - 0.21482 * 0.436 * $u - 0.38059 * 0.615 * $v]]
		set b [fraction_to_uint8 [expr $y + 2.12798 * 0.436 * $u]]
		set a [fraction_to_uint8 $a]
		expr $r << 24 | $g << 16 | $b << 8 | $a
	}

	proc fraction_to_uint8 {value} {
		set value [expr round($value * 255)]
		expr $value > 255 ? 255 : $value < 0 ? 0 : $value
	}

	proc to_ms {seconds} {
		expr $seconds * 1000
	}

	proc to_cycles {seconds} {
		set cpu [get_active_cpu]
		expr round($seconds * [machine_info ${cpu}_freq])
	}

	set_help_text profile [join {
		{Show the detailed current profiling status in the console.}
		{Optionally specify a slot ID and a unit (s, ms, t, %).}
	} "\n"]
	proc profile {{slotid ""} {unit "s"}} {
		variable slots
		if {$slotid eq ""} {
			foreach slotid [dict keys $slots] {
				profile $slotid $unit
			}
		} elseif {[dict exists $slots $slotid]} {
			slot_with $slotid {
				upvar unit unit
				variable frame_total_time
				set percentage [expr $frame_total_time != 0 ? $frame_time * 100 / $frame_total_time : 0]
				set current [expr $total_time + ($balance > 0 ? [machine_info time] - $start_time : 0)]

				if {$unit eq "s"} {
					set frame_unit [format {%.8f s} $frame_time]
					set current_unit [format {%.8f s} $current]
				} elseif {$unit eq "ms"} {
					set frame_unit [format {%.5f ms} [to_ms $frame_time]]
					set current_unit [format {%.5f ms} [to_ms $current]]
				} elseif {$unit eq "t"} {
					set frame_unit [format {%d T} [to_cycles $frame_time]]
					set current_unit [format {%d T} [to_cycles $current]]
				} else {
					set frame_unit [format {%05.2f%%} $percentage]
					set current_unit [format {%.8f s} $current]
				}

				if {$frame_total_time != 0} {
					puts [format {%s :: frame: %s, current: %s, count: %d, balance: %d} \
						$slotid $frame_unit $current_unit $count $balance]
				} else {
					puts [format {%s :: current: %s, count: %d, balance: %d} \
						$slotid $current_unit $count $balance]
				}
			}
		}
	}

	proc profile_tab {args} {
		variable slots
		dict keys $slots
	}

	set_tabcompletion_proc profile [namespace code profile_tab]

	set_help_text profile_osd [join {
		{Show the on-screen display of the current frame time.}
		{Optionally specify the unit (s, ms, t or %).}
	} "\n"]
	proc profile_osd {{unit ""}} {
		if {$unit ne ""} {
			variable osd_unit
			set osd_unit $unit
		}
		if {![osd exists profile]} {
			osd create rectangle profile
		} elseif {$unit eq ""} {
			osd destroy profile
		}
		return
	}

	proc profile_osd_tab {args} {
		list s ms t %
	}

	set_tabcompletion_proc profile_osd [namespace code profile_osd_tab]

	set_help_text profile_frame {Advance to the next profiling frame.}
	proc profile_frame {} {
		variable frame_break
		set frame_break true
		debug cont
	}

	namespace export profile
	namespace export profile_osd
	namespace export profile_frame
}

namespace import profile::*
