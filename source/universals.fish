#!/usr/bin/env fish

# Get all 'ZAI' variables
set _var_list (set --names | grep -e '^ZAI_')

# Removed any variables there were given 
# to us by the parent process
for var in $_var_list
	set -e -flg $var > /dev/null
end

# Update list with any universal variables that remain
set _var_list (set --names | grep -e '^ZAI_')

# Convert each universal variable into 
# a valid bash export variable declaration
for var in $_var_list
	echo (string join '' "export "\
		$var
		'="'
		$$var
		'"')
end
return