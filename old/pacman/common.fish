#!/usr/bin/env fish

# Load colour and format functions
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

###################################
## Regex Strings ##################

# Possible valid package names as according to: 
# https://wiki.archlinux.org/title/Arch_package_guidelines#Package_naming
#
# (Still learning sed syntax so there might be errors in the breakdown)
# Breakdown:
#
#	's|'
# 		# Specifies the start of the search string in sed, 
# 		# and also the character to use for a field divider (|).
#
#	'^'
#		# Match against the start of the line (technically the start of the search space)
#	
#	'[[:blank:]]*'
#		# Match 0-inf blank characters (<Space> or <Tab>)	
#
#	'\('
#		# Start match group 1
#
#	'['
#		'[:digit:]' 	
#		'[:lower:]' 	
#		'@' 			
#		'_' 			
#		'+' 			
#	']'
#		# Match one (and only one) of: 
#		#	'[:digit:]' OR 
#		# 	'[:lower:]' OR
#		#	'@'			OR
#		#	'_'			OR
#		#	'+'
#
#	'['
#		'[:digit:]'		
#		'[:lower:]'		
#		'@' 			
#		'.' 			
#		'_' 			
#		'+' 			
#		'-' 			
#	']+'
#		# Match 1-inf of: 
#		#	'[:digit:]' OR 
#		# 	'[:lower:]' OR
#		#	'@'			OR
#		#	'.'			OR
#		#	'_'			OR
#		#	'+'			OR
#		#	'-'
#
#	'\)'
#		# End Match group 1
#
#	'[[:blank:]]*'
#		# Match 0-inf blank characters (<Space> or <Tab>)
#
#	'$'
#		# End of the matching space
#
#	'|'
#		# Start replace space
#
#	'\1'
#		# Print match group 1
#
#	'|g'
#		# End sed command
#
set -g SED_REGEX_package_name_strict "$(string join '' \
	's|' 						\
		'^'						\
		'[[:blank:]]*' 			\
		'\(' 			   	 	\
			'[' 				\
				'[:digit:]' 	\
				'[:lower:]' 	\
				'@' 			\
				'_' 			\
				'+' 			\
			']'					\
			'[' 				\
				'[:digit:]'		\
				'[:lower:]'		\
				'@' 			\
				'.' 			\
				'_' 			\
				'+' 			\
				'-' 			\
			']+' 	 			\
		'\)'					\
		'[[:blank:]]*'			\
		'$'						\
	'|' 						\
		'\1'					\
	'|g'						\
)"

set -g SED_REGEX_package_name_lazy "$(string join '' \
	's|' 						\
		'^'						\
		'.*' 	 				\
		'\(' 			   	 	\
			'[' 				\
				'[:alnum:]'		\
				'@' 			\
				'.' 			\
				'_' 			\
				'+' 			\
				'-' 			\
			']+' 	 			\
		'\)'					\
		'.*' 	 				\
		'$'						\
	'|' 						\
		'\1'					\
	'|g'						\
)"

# Used for inverted grep regex
#
# Breakdown:
#
#	(^[[:blank:]]*$) 
#		# Match 0-inf blank characters (<Space> or <Tab>) between the start (^) and the end ($) of the line and nothing else. 
#		# Which means we match lines with white space '<Space><Tab><Tab>'. Since we can match against 0 blank characters
#		# that means this also implicitly matches against lines with nothing but '/n' ('^$')
#	
#	|	# OR
#	
#	(^[[:blank:]]*#.*$)
#		# Similar to the first case, but in this case first we match 0-inf blank characters, then we match a '#', after which
#		# we then match 0-inf of any character till the end of the line ($) since we shouldn't try to parse anything in comments
#
set -g GREP_REGEX_blank_comment "$(string join '' \
	'(^[[:blank:]]*$)'	\
	'|'					\
	'(^[[:blank:]]*#.*$)')"


###################################
## Regex Functions ################

# Process a pkglist file into a iterable list
# removing comments and blank lines
#
# Takes a file path from $ZAI_DIR down
# Eg; $ZAI_DIR/pkglist/default.list would be
#     /pkglist/default.list
function process_pkglist
	set -f list ( cat "$( string join '' "$ZAI_DIR" "$argv[1]" )" | \
		grep -vx '([[:blank:]]*#.*)|([[:blank:]]*)' | \
		sed "$SED_REGEX_package_name" ) 
	if test -n "$list"
		printf '%s\n' "$list"
		return 0
	else
		# Nothing matched regex
		return 1
	end
end

# Takes one or more package names
# and removes any leading or trailing
# debris from each then returns the
# cleaned list with printf
function sanitise_pkg_names
	set -f cleaned_names
	for name in $argv
		if string match -rqi '^true$' "$ZAI_REX_STRICTPKG"
			set -f result "$( \
				printf '%s' "$name" | \
				sed "$SED_REGEX_package_name_strict")"
		else
			set -f result "$( \
				printf '%s' "$name" | \
				sed "$SED_REGEX_package_name_lazy")"
		end
		if test -n "$result"
			set -a cleaned_names "$result"
		end
	end
	for name in $cleaned_names
		printf '%s\n' "$name"
	end
	return 0
end

###################################
## Conditionals ###################

# Checks if the packages supplied are installed
#
# Returns 0 if they are all installed, otherwise
# returns the amount that are not installed
function is_pkg_installed
	set -f return_code 0
	for pkg in $argv
		if not pacman -Qq &> /dev/null
			set return_code ( math $return_code + 1 )
		end
	end
	return $return_code
end

###################################
## Building & Installing ##########

# Install a package, whatever that means
# just do it
function install_pkg
	:
end

## Install Functions

# Install packages with pacman
function _install_pacman
	:
end

# Install packages with paru
function _install_paru
	:
end

## Build Functions

# Build package using makepkg (pacman)
function _build_makepkg
	:
end

# Build package using paru
function _build_paru
	:
end

###################################
###################################

begin
	:
end



if test -n $pkglist
	txt_major "Installing default packages..."

	txt_minor 'Attempting to install packages in bulk...'
	if pacman -S --noconfirm --needed --color always $pkglist 2>> "$(_err)" | tee -a "$(_log)" 
		txt_base 'Bulk install was succesful'
	else

		err_minor 'Bulk install failed, starting individual package installation...'
		for i in $pkglist
			echo '========================================================================' | tee -a "$(_log)"
			txt_minor "Attempting to install '$i'..."
			if pacman -S --noconfirm --needed --color always $i 2>> "$(_err)" | tee -a "$(_log)" 
				ver_base "Successfully installed '$i'"
			else
				err_base "Failed to install '$i'"
			end
		end
		echo '========================================================================' | tee -a "$(_log)"
	end
end

# Strips (and therefore allows) comments and blank lines from the 'pkglist.list' file
set pkglist ( cat "$ZAI_DIR/pkglist/pkglist.list" | \
	grep -vx '([[:blank:]]*#.*)|([[:blank:]]*)' | \
	sed "$_valid_package_name" )

if test -n $pkglist
	txt_major "Installing user specified official repo packages..."

	txt_minor 'Attempting to install packages in bulk...'
	if pacman -S --noconfirm --needed --color always $pkglist 2>> "$(_err)" | tee -a "$(_log)" 
		txt_base 'Bulk install was succesful'
	else

		err_minor 'Bulk install failed, starting individual package installation...'
		for i in $pkglist
			echo '========================================================================' | tee -a "$(_log)"
			txt_minor "Attempting to install '$i'..."
			if pacman -S --noconfirm --needed --color always $i 2>> "$(_err)" | tee -a "$(_log)" 
				ver_base "Successfully installed '$i'"
			else
				err_base "Failed to install '$i'"
			end
		end
		echo '========================================================================' | tee -a "$(_log)"
	end
end

# Strips (and therefore allows) comments and blank lines from the 'pkgopts.list' file
set pkglist ( cat "$ZAI_DIR/pkglist/pkgopts.list" | \
	grep -vx '([[:blank:]]*#.*)|([[:blank:]]*)' | \
	sed "$_valid_package_name" )

if test -n $pkglist
	txt_major "Installing user specified 'asdeps' official repo packages..."

	txt_minor "Attempting to install 'asdeps' packages in bulk..."
	if pacman -S --noconfirm --asdeps --needed --color always $pkglist 2>> "$(_err)" | tee -a "$(_log)" 
		txt_base 'Bulk install was succesful'
	else

		err_minor "Bulk install failed, starting individual 'asdeps' package installation..."
		for i in $pkglist
			echo '========================================================================' | tee -a "$(_log)"
			txt_minor "Attempting to install '$i'..."
			if pacman -S --noconfirm --asdeps --needed --color always $i 2>> "$(_err)" | tee -a "$(_log)" 
				ver_base "Successfully installed '$i'"
			else
				err_base "Failed to install '$i'" 
			end
		end
		echo '========================================================================' | tee -a "$(_log)"
	end
end

echo '' | tee -a "$(_log)" 
txt_major 'Finished installing offical packages'
return
