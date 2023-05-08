#!/usr/bin/env fish

# Load colour and format variables
source "$ZAI_DIR/source/format.fish"

# Wrapper for 'sed'
function replace_line
	
	############################################################	
	####### Check for, and protect against, unsafe usage #######
	
	if test -z "$argv[1]"
		# Search string is undefined or empty, feeding this
		# to 'sed' would be bad so we abort instead
		echo "{$txtred}Search string passed to 'replace_line' function empty or undefined{$txtclean}" >&2
		echo "{$txtred}\$1 = '$argv[1]'{$txtclean}" >&2
		return 1
	end
	if test -z "$argv[2]"
		if string match -rqiv '^true$' "$ZAI_LAZYSED" 
			# Replacment string is undefined or empty, this ~might~ be intentional
			# but could be extremely destructive if it is a bug so we abort unless
			# explicitly told to allow this usage with $ZAI_LAZYSED
			echo "{$txtred}Replacment string passed to 'replace_line' function empty or undefined{$txtclean}" >&2
			echo "{$txtred}\$2 = '$argv[2]'{$txtclean}" >&2
			return 1
		end
	end
	if test -z "$argv[3]"
		# Search file is undefined or empty, feeding this 
		# to 'sed' would be bad so we abort instead
		echo "{$txtred}File path passed to 'replace_line' function empty or undefined{$txtclean}" >&2
		echo "{$txtred}\$3 = '$argv[3]'{$txtclean}" >&2
		return 1
	end

	############################################################
    
	# Make variable usage a bit clearer
	set _search 	$argv[1]
	set _replace 	$argv[2]
	set _file 		$argv[3]
	
	# Actually run 'sed'
	sed -i "s|$_search|$_replace|g" "$_file" 
	set _sed_exit $status

	# Return 'sed' status
	return $_sed_exit
end

function abort
	if string match -rqi '^true$' $ZAI_IGNOREFAIL
		err_base "Continuing regardless..."
		return
	else
		err_base "Aborting..."
		exit 1
	end
end

function pause
	if string match -rqi '^true$' $ZAI_PAUSESKIP
		ver_base "Continuing without pausing..."
	else
		# I'm aware calling a whole bash subshell just to achieve a 'pause'
		# like effect is a big 'ol hack but I couldn't find a good example
		# of achieving similar behaviour in pure fish
		bash -c 'read -n1 -r -s -p "Press any key to continue..."'; echo ''
	end
	return
end

# Diffs two files and outputs with bat
function pretty_diff 
	diff -u "$argv[1]" "$argv[2]" --minimal | \
	tee -a (_log) | \
	bat --language diff --paging never --file-name "$argv[1] -> $argv[2]" -
	return
end

function zai_log
	set -f _return_code "$status"
	if printf '%s' "$argv[1]" | grep -zEvq -e '^[[:blank:]]*$' 
		printf '%s\n' "$argv[1]" | tee -a "$(_log)"
	end
	return $_return_code
end

function zai_verbose
	set -f _return_code "$status"
	if printf '%s' "$argv[1]" | grep -zEvq -e '^[[:blank:]]*$' 
		if string match -rqi '^true$' "$ZAI_VERBOSE_VERY"; or string match -rqi '^true$' "$ZAI_VERBOSE"
			printf '%s\n' "$argv[1]" | tee -a "$(_log)"
		else
			printf '%s\n' "$argv[1]" >> "$(_log)"
		end
	end
	return $_return_code
end

function zai_verbose
	set -f _return_code "$status"
	if printf '%s' "$argv[1]" | grep -zEvq -e '^[[:blank:]]*$' 
		if string match -rqi '^true$' "$ZAI_VERBOSE_VERY"; or string match -rqi '^true$' "$ZAI_VERBOSE"
			printf '%s\n' "$argv[1]" | tee -a "$(_log)"
		else
			printf '%s\n' "$argv[1]" >> "$(_log)"
		end
	end
	return $_return_code
end

function zai_vverbose
	set -f _return_code "$status"
	if printf '%s' "$argv[1]" | grep -zEvq -e '^[[:blank:]]*$'
		if string match -rqi '^true$' "$ZAI_VERBOSE_VERY"
			printf '%s\n' "$argv[1]" | tee -a (_log)
		else
			printf '%s\n' "$argv[1]" >> (_log)
		end
	end
	return $_return_code
end

######################################################	
###### Set directories to store transient files ######

function reset_dirs 
	set -g _log_dir "$(_log_dir)"
	set -g _backup_dir "$(_backup_dir)"
	return
end

function _log_dir
	if test -n "$ZAI_LOGS_DIR"
		if test -d "$ZAI_LOGS_DIR"
			echo "$ZAI_LOGS_DIR"
		else
			echo "The config option '\$ZAI_LOGS_DIR' is set but doesn't resolve to a directory" >> "$ZAI_DIR/logs/$_name.err"
			echo "\$ZAI_LOGS_DIR = $ZAI_LOGS_DIR" 												>> "$ZAI_DIR/logs/$_name.err"
			echo "Defaulting to '\$ZAI_DIR/logs'" 												>> "$ZAI_DIR/logs/$_name.err"
			echo "$ZAI_DIR/logs" | tee --append 												   "$ZAI_DIR/logs/$_name.err"
			echo '' 						 													>> "$ZAI_DIR/logs/$_name.err"
		end
	else
		echo "$ZAI_DIR/logs"
	end
	return
end

function _backup_dir 
	if test -n "$ZAI_BACKUPS_DIR"
		if test -d "$ZAI_BACKUPS_DIR"
			echo "$ZAI_BACKUPS_DIR"
		else
			echo "The config option '\$ZAI_BACKUPS_DIR' is set but doesn't resolve to a directory"  >> "$ZAI_DIR/logs/$_name.err"
			echo "\$ZAI_BACKUPS_DIR = $ZAI_BACKUPS_DIR" 											>> "$ZAI_DIR/logs/$_name.err"
			echo "Defaulting to '\$ZAI_DIR/backups'" 												>> "$ZAI_DIR/logs/$_name.err"
			echo "$ZAI_DIR/backups" | tee --append 													   "$ZAI_DIR/logs/$_name.err"
			echo '' 						 														>> "$ZAI_DIR/logs/$_name.err"
		end
	else
		echo "$ZAI_DIR/backups"
	end
	return
end

######################################################	
####### Text formatting and printing functions #######

function _log
	if test -z "$_log_dir"
		set -g _log_dir "$(_log_dir)"
	end
	echo "$_log_dir/$_name.log"
	return	
end

function _err
	if test -z "$_log_dir"
		set -g _log_dir "$(_log_dir)"
	end
	echo "$_log_dir/$_name.err"
	return	
end

# Creates '==> $1' with colour and formatting
function txt_major 
	if test -z "$_log_dir"
		set -g _log_dir "$(_log_dir)"
	end
	_txtclean				# Reset text formatting
	_txtgrn					# Set text green
	echo -n -- '==' 		| tee --append "$_log_dir/$_name.log"
	echo -n -- '> ' 		| tee --append "$_log_dir/$_name.log"
	_txtclean				# Reset text formatting
	echo -e -- "$argv[1]" 	| tee --append "$_log_dir/$_name.log"

	_txtclean				# Reset text formatting
	return 
end

# Creates '--> $1' with colour and formatting
function txt_minor 
	if test -z "$_log_dir"
		set -g _log_dir "$(_log_dir)"
	end
	_txtclean				# Reset text formatting
	_txtgrn					# Set text green
	echo -n -- ' --' 		| tee --append "$_log_dir/$_name.log"
	echo -n -- '> ' 		| tee --append "$_log_dir/$_name.log"
	_txtclean				# Reset text formatting
	echo -e -- "$argv[1]" 	| tee --append "$_log_dir/$_name.log"

	_txtclean				# Reset text formatting
	return
end

# Creates ' -> $1' with colour and formatting
function txt_base 
	if test -z "$_log_dir"
		set -g _log_dir "$(_log_dir)"
	end
	_txtclean				# Reset text formatting
	_txtgrn					# Set text green
	echo -n -- '   ' 		| tee --append "$_log_dir/$_name.log"
	echo -n -- '> ' 		| tee --append "$_log_dir/$_name.log"
	_txtclean				# Reset text formatting
	echo -e -- "$argv[1]" 	| tee --append "$_log_dir/$_name.log"
	
	_txtclean				# Reset text formatting
	return
end

# Creates '==> $1' with colour and formatting
function err_major 
	if test -z "$_log_dir"
		set -g _log_dir "$(_log_dir)"
	end
	_txtclean				>&2	# Reset text formatting
	_txtred					>&2	# Set text red
	echo -n -- '==' 		| tee --append "$_log_dir/$_name.err" >&2
	echo -n -- '> ' 		| tee --append "$_log_dir/$_name.err" >&2
	echo -e -- "$argv[1]" 	| tee --append "$_log_dir/$_name.err" >&2

	_txtclean				>&2	# Reset text formatting
	return 
end

# Creates '--> $1' with colour and formatting
function err_minor
	if test -z "$_log_dir"
		set -g _log_dir "$(_log_dir)"
	end
	_txtclean				>&2	# Reset text formatting
	_txtred					>&2	# Set text red
	echo -n -- ' --' 		| tee --append "$_log_dir/$_name.err" >&2
	echo -n -- '> ' 		| tee --append "$_log_dir/$_name.err" >&2
	echo -e -- "$argv[1]" 	| tee --append "$_log_dir/$_name.err" >&2

	_txtclean				>&2	# Reset text formatting
	return
end

# Creates ' -> $1' with colour and formatting
function err_base
	if test -z "$_log_dir"
		set -g _log_dir "$(_log_dir)"
	end
	_txtclean				>&2	# Reset text formatting
	_txtred					>&2	# Set text red
	echo -n -- '   ' 		| tee --append "$_log_dir/$_name.err" >&2
	echo -n -- '> ' 		| tee --append "$_log_dir/$_name.err" >&2
	_txtclean				>&2	# Reset text formatting
	echo -e -- "$argv[1]" 	| tee --append "$_log_dir/$_name.err" >&2
	
	_txtclean				>&2	# Reset text formatting
	return
end

# Creates '==> $1' with colour and formatting
# only if $ZAI_VERBOSE is 'true'
function ver_major 
	if string match -rqi '^true$' $ZAI_VERBOSE
		if test -z "$_log_dir"
			set -g _log_dir "$(_log_dir)"
		end
		_txtclean			# Reset text formatting
		_txtblu				# Set text blue
		echo -n '==' 		| tee --append "$_log_dir/$_name.log"
		echo -n '> ' 		| tee --append "$_log_dir/$_name.log"
		_txtclean			# Reset text formatting
		echo -e "$argv[1]" 	| tee --append "$_log_dir/$_name.log"

		_txtclean			# Reset text formatting
	end
	return 
end

# Creates '-->  $1' with colour and formatting
# only if $ZAI_VERBOSE is 'true'
function ver_minor 
	if string match -rqi '^true$' $ZAI_VERBOSE
		if test -z "$_log_dir"
			set -g _log_dir "$(_log_dir)"
		end
		_txtclean			# Reset text formatting
		_txtblu				# Set text blue
		echo -n ' --' 		| tee --append "$_log_dir/$_name.log"
		echo -n '> ' 		| tee --append "$_log_dir/$_name.log"
		_txtclean			# Reset text formatting
		echo -e "$argv[1]" 	| tee --append "$_log_dir/$_name.log"

		_txtclean			# Reset text formatting
	end
	return
end

# Creates ' ->   $1' with colour and formatting
# only if $ZAI_VERBOSE is 'true'
function ver_base
	if string match -rqi '^true$' $ZAI_VERBOSE
		if test -z "$_log_dir"
			set -g _log_dir "$(_log_dir)"
		end
		_txtclean			# Reset text formatting
		_txtblu				# Set text blue
		echo -n '   ' 		| tee --append "$_log_dir/$_name.log"
		echo -n '> ' 		| tee --append "$_log_dir/$_name.log"
		_txtclean			# Reset text formatting
		echo -e "$argv[1]" 	| tee --append "$_log_dir/$_name.log"

		_txtclean			# Reset text formatting
	end
	return
end
