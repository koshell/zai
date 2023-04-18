#!/usr/bin/env fish

set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format functions
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

txt_minor "Creating 'aur' system user to run builds without sudo..."
if not useradd --create-home --home-dir '/aur' --comment 'AUR package builder' --system aur 2>> "$(_err)" | tee -a "$(_log)" 
	err_major "Failed to create 'aur' user"
	abort
end

txt_minor "Giving 'aur' user access to pacman commands..."
# Due to the mess that is 'Arch' PATH we don't actually know for certain
# which way a given command will be resolved, and it is unclear if 'sudoers'
# is smart enough to follow the symlinks all the way to the end, so we just
# allow access to every possible path to 'pacman'
set _sudoers (string join '' \
	'aur ALL=(ALL) NOPASSWD:/bin/pacman *\n' \
	'aur ALL=(ALL) NOPASSWD:/sbin/pacman *\n' \
	'aur ALL=(ALL) NOPASSWD:/usr/bin/pacman *\n' \
	'aur ALL=(ALL) NOPASSWD:/usr/sbin/pacman *')
#set _sudoers 'aur ALL = NOPASSWD : ALL'
mkdir -p -v /etc/sudoers.d >> "$(_log)" 2>> "$(_err)"
if echo -e $_sudoers > /etc/sudoers.d/12_aur
	txt_base "Successfully gave 'aur' user access to pacman"
else
	err_base "Failed to give 'aur' user access to pacman"
	abort
end

# We need these folders to exist for aur to build packages
txt_major "Creating directories needed for 'aur' to successfully build packages..."

txt_minor "Creating '/aur/pkgbuild' directory..."
if su -c "mkdir -p -v /aur/pkgbuild" aur >> "$(_log)" 2>> "$(_err)"
	txt_base "Successfully created '/aur/pkgbuild'" 
else
	err_base "Failed to create '/aur/pkgbuild'"
end

txt_minor "Creating '/aur/built' directory..."
if su -c "mkdir -p -v /aur/built" aur >> "$(_log)" 2>> "$(_err)"
    txt_base "Successfully created '/aur/built'"
else
	err_base "Failed to create '/aur/built'"
end

txt_minor "Creating '/aur/tmp' directory..."
if su -c "mkdir -p $(_v) /aur/tmp" aur >> "$(_log)" 2>> "$(_err)"
	txt_base "Successfully created '/aur/tmp'"
else
	err_base "Failed to create '/aur/tmp'"
end