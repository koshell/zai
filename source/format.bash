#!/usr/bin/env bash

##########################
######### Colour #########

# Black - Regular
function _txtblk {
	tput setf 0 2>/dev/null || echo -ne "\e[30m"
	return
}

# Black - Regular
function _txtreg {
	_txtblk
	return
}

# Red
function _txtred {
	tput setf 4 2>/dev/null || echo -ne "\e[31m"
	return
}

# Green
function _txtgrn {
	tput setf 2 2>/dev/null || echo -ne "\e[32m"
	return
}

# Yellow
function _txtylw {
	tput setf 6 2>/dev/null || echo -ne "\e[1;33m"
	return
}

# Blue
function _txtblu {
	tput setf 1 2>/dev/null || echo -ne "\e[34m"
	return
}

# Purple
function _txtpur {
	tput setf 5 2>/dev/null || echo -ne "\e[35m"
	return
}

# Cyan
function _txtcyn {
	tput setf 3 2>/dev/null || echo -ne "\e[36m"
	return
}

# White
function _txtwht {
	tput setf 7 2>/dev/null || echo -ne "\e[1;37m"
	return
}

##########################
####### Formatting #######

# Start bold text
function _txtbold {
	tput bold 2>/dev/null || echo -ne "\e[1m"
	return
}

# Start underlined text
function _txtsmul {
	tput smul 2>/dev/null
	return
}

# End underlined text
function _txtrmul {
	tput rmul 2>/dev/null
	return
}

# Start reverse video
function _txtrev {
	tput rev 2>/dev/null
	return
}

# Start blinking text
function _txtblink {
	tput blink 2>/dev/null || echo -ne "\e[5m"
	return
}

# Start invisible text
function _txtinvis {
	tput invis 2>/dev/null
	return
}

# Start “standout” mode
function _txtsmso {
	tput smso 2>/dev/null
	return
}

# End “standout” mode
function _txtrmso {
	tput rmso 2>/dev/null
	return
}

# Turn off all attributes
function _txtsgr0 {
	tput sgr0 2>/dev/null || echo -ne "\e[0m"
	return
}

##########################
########## Meta ##########
	
# Reset all formatting
function _txtclean {
	_txtreg
	_txtsgr0
}
