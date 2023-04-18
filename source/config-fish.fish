#!/usr/bin/env fish

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

# Load colour and format variables
source "$ZAI_DIR/source/format.fish"

set _config_env (bash -c "source $ZAI_DIR/0_config; printenv | grep '^ZAI_' | sort -n")

for line in $_config_env
    set _env (string split --max 1 --no-empty '=' $line)
    set -a new_list "set -x $_env[1] '$_env[2]'"
end

echo -e "\nLoading config values...\n" >> "$(_log)"

# Save a copy of the export variables to the log
printf '%s\n' $new_list | sort -k3,3  >> "$(_log)"

# Export environmental variables
eval ( printf '%s; ' $new_list )

echo -e "\nFinished loading config values\n" >> "$(_log)"