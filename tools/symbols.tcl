#
# Symbols utility
#
namespace eval symbols {
	variable symbols [dict create]

	proc clear {} {
		variable symbols
		set symbols [dict create]
	}

	proc load {path} {
		variable symbols
		set handle [open "$path" r]
		while {[gets $handle line] > -1} {
			if {[regexp {^([a-zA-Z_.?#][a-zA-Z0-9_.?#'$]*)[:\s]\s*equ\s*([0-9][0-9a-fA-F]*)[Hh]} $line -> name value]} {
				symbol $name [expr 0x$value]
			}
		}
		close $handle
	}

	set_help_text symbol [join {
		"Usage: symbol \[<name>] \[<value>]\n"
		"Set a symbol to a value."
		"Get a symbol if no value is specified."
		"List symbols if no name is specified."
	} ""]
	proc symbol {{name {}} {value {}}} {
		variable symbols
		if {$name eq {}} {
			dict for {name value} $symbols {
				puts [format "%s: 0x%X" $name $value]
			}
		} elseif {$value eq {}} {
			dict get $symbols $name
		} else {
			dict set symbols $name $value
			return
		}
	}

	proc symbol_tab {args} {
		variable symbols
		dict keys $symbols
	}

	set_tabcompletion_proc symbol [namespace code symbol_tab]

	namespace export symbol
}

namespace import symbols::*
