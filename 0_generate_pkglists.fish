#!/usr/bin/env fish

# For logging
set _name ( path change-extension '' ( basename ( status filename )))

set -x ZAI_DIR ( path dirname ( status filename ))

# Since this is likely being ran outside of the normal 
# environment we need to reload the config values
source "$ZAI_DIR/source/config-fish.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

# Load colour and format variables
source "$ZAI_DIR/source/format.fish"

txt_major "This script will now attempt to make a list of your current installed packages"
txt_minor "Do not run this on anything other then an 'arch' or 'arch-based' system or you will experience undefined behaviour"
pause
echo '' | tee -a "$(_log)"

# These are all magic functions stolen from the arch wiki, 
# I have no idea how half them work and can't really debug them if they break
set pkglist ( pacman -Qqetn )
txt_minor "Saved $(printf '%s\n' $pkglist | grep -xv '[[:blank:]]*' | tee $ZAI_DIR/pkglist/pkglist.list | tee -a $(_log) | wc -l) official packages to '$ZAI_DIR/pkglist/pkglist.list'"

set pkg_optlist ( bash -c 'comm -13 <(pacman -Qqndt | sort) <(pacman -Qqndtt | sort)' )
txt_base "Saved $(printf '%s\n' $pkg_optlist | grep -xv '[[:blank:]]*' | tee $ZAI_DIR/pkglist/pkgopts.list | tee -a $(_log) | wc -l) official optional dependencies to '$ZAI_DIR/pkglist/pkgopts.list'"

# This just makes the printing nicer
echo '' | tee -a "$(_log)"

set aurlist ( pacman -Qqetm )
txt_minor "Saved $(printf '%s\n' $aurlist | grep -xv '[[:blank:]]*' | tee $ZAI_DIR/pkglist/aurlist.list | tee -a $(_log) | wc -l) AUR packages to '$ZAI_DIR/pkglist/aurlist.list'"

set aur_optlist ( bash -c 'comm -13 <(pacman -Qqmdt | sort) <(pacman -Qqmdtt | sort)' )
txt_base "Saved $(printf '%s\n' $aur_optlist | grep -xv '[[:blank:]]*' | tee $ZAI_DIR/pkglist/auropts.list | tee -a $(_log) | wc -l) AUR optional dependencies to '$ZAI_DIR/pkglist/auropts.list'"

echo '' | tee -a "$(_log)"
txt_major "Done!"
