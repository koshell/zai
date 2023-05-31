#!/usr/bin/env fish

set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format functions
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

txt_major "Starting creation of 'aur' system user..."

txt_minor "Creating 'aur' system user to run builds without root privileges..."
if not zai_verbose "$( \
	useradd \
		--create-home \
		--home-dir '/aur' \
		--comment 'AUR package builder' \
		--system aur 2>> $(_err) \
)"
	err_major "Failed to create 'aur' user"
	abort
end

txt_minor "Creating 'makepkg' system group..."
if not zai_verbose "$( groupadd --system --force makepkg 2>> $(_err) )"
	err_major "Failed to create 'makepkg' group"
	abort
end

txt_minor "Adding 'aur' user to 'makepkg' group..."
if not zai_verbose "$( usermod --append -G makepkg aur 2>> $(_err) )"
	err_major "Failed to add user 'aur' to group 'makepkg'"
	abort
end

# We need these folders to exist for aur to build packages
txt_major "Creating directories needed for 'aur' to successfully build packages..."

txt_minor "Creating '/aur/pkgbuild' directory..."
if zai_verbose "$( su -c "mkdir -pv /aur/pkgbuild" aur 2>> $(_err) )"
	txt_base "Successfully created '/aur/pkgbuild'" 
else
	err_base "Failed to create '/aur/pkgbuild'"
end

txt_minor "Creating '/aur/built' directory..."
if zai_verbose "$( su -c "mkdir -pv /aur/built" aur 2>> $(_err) )"
    txt_base "Successfully created '/aur/built'"
else
	err_base "Failed to create '/aur/built'"
end

txt_minor "Creating '/aur/tmp' directory..."
if zai_verbose "$( su -c "mkdir -pv /aur/tmp" aur 2>> $(_err) )"
	txt_base "Successfully created '/aur/tmp'"
else
	err_base "Failed to create '/aur/tmp'"
end

txt_major "Finished creation of 'aur' system user..."
return
