#!/usr/bin/env fish

set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format functions
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

##################
#
# This file will contain the AUR user creation part of 'build_aur.fish'
# so that it can be executed separately 
#
##################