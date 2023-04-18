#!/usr/bin/env bash

# Load colour and format variables
# shellcheck source=./format.bash
source "${ZAI_DIR}/source/format.bash"

# Diffs two files and outputs with bat
function pretty_diff {
	diff -u "$1" "$2" --minimal | \
	tee -a "$(_resolve_log)" | \
	bat --language diff --paging never --file-name "$1 -> $2" -
	return
}

# Overwrites any bash variables with fish universal variables if they exist
function update_exports {
	txt_major "Updating exported variables..."
	printenv | grep -E '^ZAI\_' | sort > /tmp/zai_var.old
	eval "$(fish "$ZAI_DIR/source/universals.fish")"
	printenv | grep -E '^ZAI\_' | sort > /tmp/zai_var.new
	diff -u "/tmp/zai_var.old" "/tmp/zai_var.new" --minimal	>> "$(_log)"
	pretty_diff "/tmp/zai_var.old" "/tmp/zai_var.new" 
	txt_major "Finished updating exported variables"
	return
}

function pause {
	if [[ ${ZAI_PAUSESKIP,,} =~ ^true$ ]]; then
		ver_base "Continuing without pausing..."
	else
		read -n1 -r -s -p "Press any key to continue..."; echo ''
	fi
	return
}


function abort {
	if [[ ${ZAI_IGNOREFAIL,,} =~ ^true$ ]]; then
		err_base "Continuing regardless..."
		return
	else
		err_base "Aborting..."
		exit 1
	fi
}

# Wrapper for 'sed'
function replace_line {
	
	####### Check for, and protect against, unsafe usage #######
	
	if [[ -z "$1" ]]; then
		# Search string is undefined or empty, feeding this
		# to 'sed' would be bad so we abort instead
		err_base "Search string passed to 'replace_line' function empty or undefined"
		err_base "\$1 = '$1'"
		return 1
	
	elif [[ -z "$2" ]]; then
		if [[ ! ${ZAI_LAZYSED,,} =~ ^true$ ]]; then
			# Replacment string is undefined or empty, this ~might~ be intentional
			# but could be extremely destructive if it is a bug so we abort unless
			# explicitly told to allow this usage with $ZAI_LAZYSED
			err_base "Replacement string passed to 'replace_line' function empty or undefined"
			err_base "\$2 = '$2'"
			return 1
		fi

	elif [[ -z "$3" ]]; then
		# Search file is undefined or empty, feeding this 
		# to 'sed' would be bad so we abort instead
		err_base "File path passed to 'replace_line' function empty or undefined"
		err_base "\$3 = '$3'"
		return 1
	fi

	############################################################
    
	# Make variable usage a bit clearer
	readonly _search="$1"
	readonly _replace="$2"
	readonly _file="$3"
	
	# Actually run 'sed'
	sed -i "s|${_search}|${_replace}|g" "$_file" 
	readonly _sed_exit="$?"

	# Return 'sed' status
	return $_sed_exit
}

######################################################	
### Make commands run verbose if enabled in config ###

function _verbose {
	if [[ ${ZAI_VERBOSE,,} =~ ^true$ ]]; then
		echo '--verbose'
		return
	else
		return
	fi
}


function _v {
	if [[ ${ZAI_VERBOSE,,} =~ ^true$ ]]; then
		echo '-v'
		return
	else
		return
	fi
}

######################################################	
####### Text formatting and printing functions #######

function _log {
	echo "$ZAI_DIR/logs/$_name.log"
	return	
}


function _err {
	echo "$ZAI_DIR/logs/$_name.err'"
	return	
}


# Creates '==> $1' with colour and formatting
function txt_major {
	_txtclean		# Reset text formatting
	_txtgrn			# Set text green
	echo -n '==' 	| tee --append "$ZAI_DIR/logs/$_name.log"
	echo -n '> ' 	| tee --append "$ZAI_DIR/logs/$_name.log"
	_txtclean		# Reset text formatting
	echo -e "$1" 	| tee --append "$ZAI_DIR/logs/$_name.log"
	
	_txtclean
	return 
}

# Creates '-->  $1' with colour and formatting
function txt_minor {
	_txtclean		# Reset text formatting
	_txtgrn			# Set text green
	echo -n '--'  	| tee --append "$ZAI_DIR/logs/$_name.log"
	echo -n '>  ' 	| tee --append "$ZAI_DIR/logs/$_name.log"
	_txtclean		# Reset text formatting
	echo -e "$1"	| tee --append "$ZAI_DIR/logs/$_name.log"
	
	_txtclean
	return
}

# Creates ' ->   $1' with colour and formatting
function txt_base {
	_txtclean		# Reset text formatting
	_txtgrn			# Set text green
	echo -n ' -' 	| tee --append "$ZAI_DIR/logs/$_name.log"
	echo -n '>   ' 	| tee --append "$ZAI_DIR/logs/$_name.log"
	_txtclean		# Reset text formatting
	echo -e "$1" 	| tee --append "$ZAI_DIR/logs/$_name.log"
	
	_txtclean
	return
}

# Creates '==> $1' with colour and formatting
function err_major {
	_txtclean		>&2	# Reset text formatting
	_txtred			>&2	# Set text red
	echo -n '=='  	| tee --append "$ZAI_DIR/logs/$_name.log"	>&2
	echo -n '> '  	| tee --append "$ZAI_DIR/logs/$_name.log"	>&2
	_txtclean		>&2	# Reset text formatting
	echo -e "$1"	| tee --append "$ZAI_DIR/logs/$_name.log"	>&2
	
	_txtclean
	return 
}

# Creates '-->  $1' with colour and formatting
function err_minor {
	_txtclean		>&2	# Reset text formatting
	_txtred			>&2	# Set text red
	echo -n '--' 	| tee --append "$ZAI_DIR/logs/$_name.log" 	>&2
	echo -n '>  ' 	| tee --append "$ZAI_DIR/logs/$_name.log" 	>&2
	_txtclean		>&2	# Reset text formatting
	echo -e "$1"  	| tee --append "$ZAI_DIR/logs/$_name.log"	>&2
	
	_txtclean
	return
}

# Creates ' ->   $1' with colour and formatting
function err_base {
	_txtclean		>&2	# Reset text formatting
	_txtred			>&2	# Set text red
	echo -n ' -' 	| tee --append "$ZAI_DIR/logs/$_name.log" 	>&2
	echo -n '>   ' 	| tee --append "$ZAI_DIR/logs/$_name.log" 	>&2
	_txtclean		>&2	# Reset text formatting
	echo -e "$1"  	| tee --append "$ZAI_DIR/logs/$_name.log"	>&2

	_txtclean
	return
}

# Creates '==> $1' with colour and formatting
# only if $ZAI_VERBOSE is 'true'
function ver_major {
	if [[ ${ZAI_VERBOSE,,} =~ ^true$ ]]; then
		_txtclean		# Reset text formatting
		_txtblu			# Set text blue
		echo -n '==' 	| tee --append "$ZAI_DIR/logs/$_name.log"
		echo -n '>  ' 	| tee --append "$ZAI_DIR/logs/$_name.log"
		_txtclean		# Reset text formatting
		echo -e "$1" 	| tee --append "$ZAI_DIR/logs/$_name.log"

		_txtclean
	fi
	return 
}

# Creates '-->  $1' with colour and formatting
# only if $ZAI_VERBOSE is 'true'
function ver_minor {
	if [[ ${ZAI_VERBOSE,,} =~ ^true$ ]]; then
		_txtclean		# Reset text formatting
		_txtblu			# Set text blue
		echo -n '--' 	| tee --append "$ZAI_DIR/logs/$_name.log"
		echo -n '>   ' 	| tee --append "$ZAI_DIR/logs/$_name.log"
		_txtclean		# Reset text formatting
		echo -e "$1" 	| tee --append "$ZAI_DIR/logs/$_name.log"

		_txtclean
	fi
	return
}

# Creates ' ->   $1' with colour and formatting
# only if $ZAI_VERBOSE is 'true'
function ver_base {
	if [[ ${ZAI_VERBOSE,,} =~ ^true$ ]]; then
		_txtclean		# Reset text formatting
		_txtblu			# Set text blue
		echo -n '  ' 	| tee --append "$ZAI_DIR/logs/$_name.log"
		echo -n '>    ' | tee --append "$ZAI_DIR/logs/$_name.log"
		_txtclean		# Reset text formatting
		echo -e "$1" 	| tee --append "$ZAI_DIR/logs/$_name.log"

		_txtclean
	fi
	return
}
