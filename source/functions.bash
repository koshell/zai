#!/usr/bin/env bash
# shellcheck disable=SC2154
#
# Load colour and format variables
# shellcheck source=./format.bash
source "${ZAI_DIR}/source/format.bash"

# Diffs two files and outputs with bat
function pretty_diff {
	diff -u "$1" "$2" --minimal | \
	tee -a "$(_log)" | \
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
	
	############################################################
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
	############################################################
    
	# Make variable usage a bit clearer
	readonly _search="$1"
	readonly _replace="$2"
	readonly _file="$3"
	
	# Actually run 'sed'
	sed -i "s|${_search}|${_replace}|g" "$_file" 
	
	# Return 'sed' status
	return "$?"
}

# Wraps command output and hides it if not verbose
function zai_verbose {
	_return_code="$?"
	if [[ ${ZAI_VERBOSE,,} =~ ^true$ ]]; then
		printf '%s' "$1\n" | tee -a "$(_log)"
	else
		printf '%s' "$1\n" >> "$(_log)"
	fi
	return $_return_code
}

######################################################	
###### Set directories to store transient files ######

function reset_dirs {
	_log_dir="$(_log_dir)"
	mkdir -p $_log_dir
	_backup_dir="$(_backup_dir)"
	mkdir -p $_backup_dir
	return
}

function _log_dir {
	if [[ -n "$ZAI_LOGS_DIR" ]]; then
		if [[ -d "$ZAI_LOGS_DIR" ]]; then
			echo "$ZAI_LOGS_DIR"
		else
			{ \
				echo "The config option '\$ZAI_LOGS_DIR' is set but doesn't resolve to a directory"; \
				echo "\$ZAI_LOGS_DIR = $ZAI_LOGS_DIR"; \
				echo "Defaulting to '\$ZAI_DIR/logs'"; \
			} 								 >> "$ZAI_DIR/logs/$_name.err"
			echo "$ZAI_DIR/logs" | tee --append "$ZAI_DIR/logs/$_name.err"
			echo '' 						 >> "$ZAI_DIR/logs/$_name.err"
		fi
	else
		echo "$ZAI_DIR/logs"
	fi
	return
}

function _backup_dir {
	if [[ -n "$ZAI_BACKUPS_DIR" ]]; then
		if [[ -d "$ZAI_BACKUPS_DIR" ]]; then
			echo "$ZAI_BACKUPS_DIR"
		else
			{ \
				echo "The config option '\$ZAI_BACKUPS_DIR' is set but doesn't resolve to a directory"; \
				echo "\$ZAI_BACKUPS_DIR = $ZAI_BACKUPS_DIR"; \
				echo "Defaulting to '\$ZAI_DIR/backups"; \
			} 									>> "$ZAI_DIR/logs/$_name.err"
			echo "$ZAI_DIR/backups" | tee --append "$ZAI_DIR/logs/$_name.err"
			echo '' 							>> "$ZAI_DIR/logs/$_name.err"
		fi
	else
		echo "$ZAI_DIR/backups"
	fi
	return
}

######################################################	
####### Text formatting and printing functions #######

function _log {
	if [[ -z $_log_dir ]]; then
		_log_dir="$(_log_dir)"
	fi
	# shellcheck disable=SC2154
	echo "$_log_dir/$_name.log"
	return	
}


function _err {
	if [[ -z $_log_dir ]]; then
		_log_dir="$(_log_dir)"
	fi
	# shellcheck disable=SC2154
	echo "$_log_dir/$_name.err"
	return	
}


# Creates '==> $1' with colour and formatting
function txt_major {
	if [[ -z $_log_dir ]]; then
		_log_dir="$(_log_dir)"
	fi
	_txtclean		# Reset text formatting
	_txtgrn			# Set text green
	echo -n '==' 	| tee --append "$_log_dir/$_name.log"
	echo -n '> ' 	| tee --append "$_log_dir/$_name.log"
	_txtclean		# Reset text formatting
	echo -e "$1" 	| tee --append "$_log_dir/$_name.log"
	
	_txtclean
	return 
}

# Creates '-->  $1' with colour and formatting
function txt_minor {
	if [[ -z $_log_dir ]]; then
		_log_dir="$(_log_dir)"
	fi
	_txtclean		# Reset text formatting
	_txtgrn			# Set text green
	echo -n '--'  	| tee --append "$_log_dir/$_name.log"
	echo -n '>  ' 	| tee --append "$_log_dir/$_name.log"
	_txtclean		# Reset text formatting
	echo -e "$1"	| tee --append "$_log_dir/$_name.log"
	
	_txtclean
	return
}

# Creates ' ->   $1' with colour and formatting
function txt_base {
	if [[ -z $_log_dir ]]; then
		_log_dir="$(_log_dir)"
	fi
	_txtclean		# Reset text formatting
	_txtgrn			# Set text green
	echo -n ' -' 	| tee --append "$_log_dir/$_name.log"
	echo -n '>   ' 	| tee --append "$_log_dir/$_name.log"
	_txtclean		# Reset text formatting
	echo -e "$1" 	| tee --append "$_log_dir/$_name.log"
	
	_txtclean
	return
}

# Creates '==> $1' with colour and formatting
function err_major {
	if [[ -z $_log_dir ]]; then
		_log_dir="$(_log_dir)"
	fi
	_txtclean		>&2	# Reset text formatting
	_txtred			>&2	# Set text red
	echo -n '=='  	| tee --append "$_log_dir/$_name.log"	>&2
	echo -n '> '  	| tee --append "$_log_dir/$_name.log"	>&2
	_txtclean		>&2	# Reset text formatting
	echo -e "$1"	| tee --append "$_log_dir/$_name.log"	>&2
	
	_txtclean
	return 
}

# Creates '-->  $1' with colour and formatting
function err_minor {
	if [[ -z $_log_dir ]]; then
		_log_dir="$(_log_dir)"
	fi
	_txtclean		>&2	# Reset text formatting
	_txtred			>&2	# Set text red
	echo -n '--' 	| tee --append "$_log_dir/$_name.log" >&2
	echo -n '>  ' 	| tee --append "$_log_dir/$_name.log" >&2
	_txtclean		>&2	# Reset text formatting
	echo -e "$1"  	| tee --append "$_log_dir/$_name.log"	>&2
	
	_txtclean
	return
}

# Creates ' ->   $1' with colour and formatting
function err_base {
	if [[ -z $_log_dir ]]; then
		_log_dir="$(_log_dir)"
	fi
	_txtclean		>&2	# Reset text formatting
	_txtred			>&2	# Set text red
	echo -n ' -' 	| tee --append "$_log_dir/$_name.log" >&2
	echo -n '>   ' 	| tee --append "$_log_dir/$_name.log" >&2
	_txtclean		>&2	# Reset text formatting
	echo -e "$1"  	| tee --append "$_log_dir/$_name.log"	>&2

	_txtclean
	return
}

# Creates '==> $1' with colour and formatting
# only if $ZAI_VERBOSE is 'true'
function ver_major {
	if [[ ${ZAI_VERBOSE,,} =~ ^true$ ]]; then
		if [[ -z $_log_dir ]]; then
			_log_dir="$(_log_dir)"
		fi
		_txtclean		# Reset text formatting
		_txtblu			# Set text blue
		echo -n '==' 	| tee --append "$_log_dir/$_name.log"
		echo -n '>  ' 	| tee --append "$_log_dir/$_name.log"
		_txtclean		# Reset text formatting
		echo -e "$1" 	| tee --append "$_log_dir/$_name.log"

		_txtclean
	fi
	return 
}

# Creates '-->  $1' with colour and formatting
# only if $ZAI_VERBOSE is 'true'
function ver_minor {
	if [[ ${ZAI_VERBOSE,,} =~ ^true$ ]]; then
		if [[ -z $_log_dir ]]; then
			_log_dir="$(_log_dir)"
		fi
		_txtclean		# Reset text formatting
		_txtblu			# Set text blue
		echo -n '--' 	| tee --append "$_log_dir/$_name.log"
		echo -n '>   ' 	| tee --append "$_log_dir/$_name.log"
		_txtclean		# Reset text formatting
		echo -e "$1" 	| tee --append "$_log_dir/$_name.log"

		_txtclean
	fi
	return
}

# Creates ' ->   $1' with colour and formatting
# only if $ZAI_VERBOSE is 'true'
function ver_base {
	if [[ ${ZAI_VERBOSE,,} =~ ^true$ ]]; then
		if [[ -z $_log_dir ]]; then
			_log_dir="$(_log_dir)"
		fi
		_txtclean		# Reset text formatting
		_txtblu			# Set text blue
		echo -n '  ' 	| tee --append "$_log_dir/$_name.log"
		echo -n '>    ' | tee --append "$_log_dir/$_name.log"
		_txtclean		# Reset text formatting
		echo -e "$1" 	| tee --append "$_log_dir/$_name.log"

		_txtclean
	fi
	return
}
