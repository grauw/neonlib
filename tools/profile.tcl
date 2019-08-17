#
# Profiling utility
#
# With this utility you can profile the time spent in sections of your code.
# To measure a section you need to instrument it with TCL breakpoints or Z80 I/O
# instructions to indicate the start and end, and what section it belongs to.
#
# Additionally you can divide the measurements in frame blocks by using the
# “frame” section. This section is treated as a frame delimiter, and every time
# this section starts all the section times are reset and the OSD is updated.
#
# Commands:
#
# profile [<id>] [<unit>]
# profile_osd [<unit>]
# profile_frame
# profile::section_begin <id>
# profile::section_end <id>
# profile::section_begin_bp <id> <address> [<condition>]
# profile::section_end_bp <id> <address> [<condition>]
# profile::section_scope_bp <id> <address> [<condition>]
# profile::section_irq_bp <id> [<condition>]
# profile::sections_create <id>...
#
# See help <command> for more information.
#
# Z80 interface:
#
# Start a section by writing <id> to I/O port 2Ch on the Z80.
# End a section by writing <id> to I/O port 2Dh on the Z80.
# Since only numeric IDs can be used, use 255 to indicate the “frame” ID.
#
namespace eval profile {
	variable sections [dict create]
	variable frame_start_time 0
	variable frame_total_time 0
	variable frame_break false
	variable width 40
	variable height 8
	variable osd_unit %

	debug set_watchpoint write_io 0x2C {} [namespace code {
		section_begin [expr $::wp_last_value == 255 ? frame : $::wp_last_value]
	}]

	debug set_watchpoint write_io 0x2D {} [namespace code {
		section_end [expr $::wp_last_value == 255 ? frame : $::wp_last_value]
	}]

	set_help_text profile::section_begin_bp [join {
		"Usage: profile::section_begin_bp <id> <address> \[<condition>]\n"
		"Define a breakpoint which starts a section."
	} {}]
	proc section_begin_bp {id address {condition {}}} {
		section_create $id
		debug set_bp $address $condition [namespace code "section_begin $id"]
	}

	set_help_text profile::section_end_bp [join {
		"Usage: profile::section_end_bp <id> <address> \[<condition>]\n"
		"Define a breakpoint which ends a section."
	} {}]
	proc section_end_bp {id address {condition {}}} {
		section_create $id
		debug set_bp $address $condition [namespace code "section_end $id"]
	}

	set_help_text profile::section_scope_bp [join {
		"Usage: profile::section_scope_bp <id> <address> \[<condition>]\n"
		"Define a breakpoint which starts a section, and will end it after the "
		"value on the top of the stack is read, typically when the method "
		"returns or when it is popped. Useful for profiling function calls."
	} {}]
	proc section_scope_bp {id address {condition {}}} {
		section_create $id
		set begin [namespace code "section_begin $id"]
		set end [namespace code "section_end $id"]
		debug set_bp $address $condition \
			"$begin\ndebug set_watchpoint read_mem -once \[reg sp] {} {debug set_condition -once {} {$end}}"
	}

	set_help_text profile::section_irq_bp [join {
		"Usage: profile::section_irq_bp <id> \[<condition>]\n"
		"Define a probe breakpoint which starts a section when the CPU accepts "
		"an IRQ, and ends it after the return address on the stack is read, "
		"typically when it returns. Useful for profiling interrupt handlers."
	} {}]
	proc section_irq_bp {id {condition {}}} {
		section_create $id
		set begin [namespace code "section_begin $id"]
		set end [namespace code "section_end $id"]
		set handler "$begin\ndebug set_watchpoint read_mem -once \[expr \[reg sp] - 2] {} {debug set_condition -once {} {$end}}"
		debug probe set_bp z80.acceptIRQ $condition $handler
		debug probe set_bp r800.acceptIRQ $condition $handler
	}

	set_help_text profile::sections_create [join {
		"Usage: profile::sections_create <id>...\n"
		"Predefines sections. Useful to specify the order they appear in."
	} {}]
	proc sections_create {ids} {
		foreach id $ids {
			section_create $id
		}
	}

	set_help_text profile::section_create [join {
		"Usage: profile::section_create <id>\n"
		"Predefines a section. Useful to specify the order they appear in."
	} {}]
	proc section_create {id} {
		variable sections
		if {![dict exists $sections $id]} {
			dict set sections $id [dict create total_time 0 sync_time 0 count 0 balance 0 frame_time 0]
		}
	}

	proc section_with {id body} {
		variable sections
		section_create $id
		dict with sections $id {
			set time [machine_info time]
			if {$balance > 0} {
				set total_time [expr $total_time + $time - $sync_time]
			}
			set sync_time $time
			eval $body
		}
	}

	set_help_text profile::section_begin [join {
		"Usage: profile::section_begin <id>\n"
		"Starts a section. Use the “frame” ID to mark the beginning of a frame."
	} {}]
	proc section_begin {id} {
		section_with $id {
			incr balance
			incr count
		}

		if {$id eq "frame"} {
			section_frame_flush
		}
	}

	set_help_text profile::section_end [join {
		"Usage: profile::section_end <id>\n"
		"Ends a section."
	} {}]
	proc section_end {id} {
		section_with $id {
			incr balance -1
		}
	}

	proc section_frame_flush {} {
		variable sections
		variable frame_start_time
		variable frame_total_time
		variable frame_break
		set time [machine_info time]
		set frame_total_time [expr $time - $frame_start_time]
		set frame_start_time $time
		foreach id [dict keys $sections] {
			section_with $id {
				set frame_time $total_time
				set total_time 0
			}
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
		variable sections
		foreach id [dict keys $sections] {
			section_with $id {
				variable frame_total_time
				variable osd_unit

				if {![osd exists profile.$id]} {
					variable width
					variable height
					set index [lsearch -exact [dict keys $sections] $id]
					set x [expr ($index * $height / 240) * $width]
					set y [expr $index * $height % 240]
					set rgba [osd_hya [expr $index * 0.14] 0.5 1.0]
					osd create rectangle profile.$id -x $x -y $y -w $width -h $height -scaled true -clip true -rgba 0x00000088
					osd create rectangle profile.$id.bar -x 0 -y 0 -w 0 -h $height -scaled true -rgba $rgba
					osd create text profile.$id.text -x 2 -y 1 -size [expr $height - 3] -scaled true -rgba 0xffffffff
				}

				set fraction [expr $frame_total_time != 0 ? $frame_time / $frame_total_time : 0]
				set fraction_clamped [expr $fraction < 0 ? 0 : $fraction > 1 ? 1 : $fraction]
				osd configure profile.$id.bar -w [expr $fraction_clamped * [osd info profile.$id -w]]

				if {$osd_unit eq "s"} {
					set text [format "%s: %.3f s" $id $frame_time]
				} elseif {$osd_unit eq "ms"} {
					set text [format "%s: %.2f ms" $id [to_ms $frame_time]]
				} elseif {$osd_unit eq "t"} {
					set text [format "%s: %d T" $id [to_cycles $frame_time]]
				} else {
					set text [format "%s: %00.2f%%" $id [expr $fraction * 100]]
				}
				osd configure profile.$id.text -text $text
			}
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
		"Usage: profile \[<id>] \[<unit>]\n"
		"Show the current profiling status in the console. "
		"Optionally specify a section ID and a unit (s, ms, t, %).\n"
		"\n"
		"Legend:\n"
		"- frame: the time spent in the last frame\n"
		"- current: shows the currently accumulated time\n"
		"- count: the number of times the section was started\n"
		"- balance: whether the CPU is currently in a section\n"
		"  If section starts and ends are imbalanced, balance will ever-increase.\n"
	} {}]
	proc profile {{id ""} {unit "s"}} {
		variable sections
		if {$id eq ""} {
			foreach id [dict keys $sections] {
				profile $id $unit
			}
		} elseif {[dict exists $sections $id]} {
			section_with $id {
				upvar unit unit
				variable frame_total_time
				set percentage [expr $frame_total_time != 0 ? $frame_time * 100 / $frame_total_time : 0]

				if {$unit eq "s"} {
					set frame_unit [format {%.8f s} $frame_time]
					set current_unit [format {%.8f s} $total_time]
				} elseif {$unit eq "ms"} {
					set frame_unit [format {%.5f ms} [to_ms $frame_time]]
					set current_unit [format {%.5f ms} [to_ms $total_time]]
				} elseif {$unit eq "t"} {
					set frame_unit [format {%d T} [to_cycles $frame_time]]
					set current_unit [format {%d T} [to_cycles $total_time]]
				} else {
					set frame_unit [format {%05.2f%%} $percentage]
					set current_unit [format {%.8f s} $total_time]
				}

				if {$frame_total_time != 0} {
					puts [format {%s :: frame: %s, current: %s, count: %d, balance: %d} \
						$id $frame_unit $current_unit $count $balance]
				} else {
					puts [format {%s :: current: %s, count: %d, balance: %d} \
						$id $current_unit $count $balance]
				}
			}
		}
	}

	proc profile_tab {args} {
		variable sections
		dict keys $sections
	}

	set_tabcompletion_proc profile [namespace code profile_tab]

	set_help_text profile_osd [join {
		"Usage: profile_osd \[<unit>]\n"
		"Show the on-screen display of the current section frame times. "
		"The OSD updates at the beginning of each frame. "
		"Optionally specify the unit (s, ms, t or %)."
	} {}]
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

	set_help_text profile_frame [join {
		"Usage: profile_frame\n"
		"Continues execution until the start of the next frame."
	} {}]
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
