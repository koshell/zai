#!/usr/bin/env fish

##########################
######### Colour #########

# Black - Regular
function _txtblk
	tput setf 0 2>/dev/null || echo -ne "\e[30m"
	return
end

# Black - Regular
function _txtreg 
	_txtblk
	return
end

# Red
function _txtred 
	tput setf 4 2>/dev/null || echo -ne "\e[31m"
	return
end

# Green
function _txtgrn 
	tput setf 2 2>/dev/null || echo -ne "\e[32m"
	return
end

# Yellow
function _txtylw 
	tput setf 6 2>/dev/null || echo -ne "\e[1;33m"
	return
end

# Blue
function _txtblu 
	tput setf 1 2>/dev/null || echo -ne "\e[34m"
	return
end

# Purple
function _txtpur 
	tput setf 5 2>/dev/null || echo -ne "\e[35m"
	return
end

# Cyan
function _txtcyn 
	tput setf 3 2>/dev/null || echo -ne "\e[36m"
	return
end

# White
function _txtwht 
	tput setf 7 2>/dev/null || echo -ne "\e[1;37m"
	return
end

##########################
####### Formatting #######

# Start bold text
function _txtbold 
	tput bold 2>/dev/null || echo -ne "\e[1m"
	return
end

# Start underlined text
function _txtsmul 
	tput smul 2>/dev/null
	return
end

# End underlined text
function _txtrmul 
	tput rmul 2>/dev/null
	return
end

# Start reverse video
function _txtrev 
	tput rev 2>/dev/null
	return
end

# Start blinking text
function _txtblink 
	tput blink 2>/dev/null || echo -ne "\e[5m"
	return
end

# Start invisible text
function _txtinvis 
	tput invis 2>/dev/null
	return
end

# Start “standout” mode
function _txtsmso 
	tput smso 2>/dev/null
	return
end

# End “standout” mode
function _txtrmso 
	tput rmso 2>/dev/null
	return
end

# Turn off all attributes
function _txtsgr0 
	tput sgr0 2>/dev/null || echo -ne "\e[0m"
	return
end

##########################
########## Meta ##########
	
# Reset all formatting
function _txtclean 
	_txtreg
	_txtsgr0
end