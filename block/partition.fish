#!/usr/bin/env fish

# For logging
set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format variables
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

txt_major "Creating partition table for /dev/$ZAI_BLK..."
parted --script --fix --align optimal "/dev/$ZAI_BLK" \
    mklabel gpt \
    mkpart none 0% 1025MiB \
    mkpart none 1025MiB 33793MiB \
    mkpart none 33793MiB 164865MiB \
    mkpart none 164865MiB 100%
echo ''
parted "/dev/$ZAI_BLK" unit GiB print
txt_major "Finished creating table for '/dev/$ZAI_BLK'."
return
