#!/usr/bin/env fish

set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format functions
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

# Load list of packages to install
set pkglist (cat "$ZAI_DIR/pacman/pkg_aur")

txt_major "Refreshing and updating repo database..."
pacman -Syu --noconfirm --color always

txt_major "Installing AUR packages..."

txt_minor 'Attempting to install packages in bulk...'
if pacman -S --noconfirm --needed --color always $pkglist
	txt_base 'Bulk install was succesful'
else
	err_minor 'Bulk install failed, starting individual package installation...'
	for i in $pkglist
		echo '========================================================================'
		txt_minor "Attempting to install '$i'..."
		if pacman -S --noconfirm --needed --color always $i 
			ver_base "Successfully installed '$i'"
		else
			err_base "Failed to install '$i'"
		end
	end
	echo '========================================================================'
end

# Load list of packages to install
set pkglist (cat "$ZAI_DIR/pacman/pkg_aur.asdeps")

if test -n $pkglist
	txt_minor "Attempting to install 'asdeps' packages in bulk..."
	if pacman -S --noconfirm --asdeps --needed --color always $pkglist
		txt_base 'Bulk install was succesful'
	else

		err_minor "Bulk install failed, starting individual 'asdeps' package installation..."
		for i in $pkglist
			echo '========================' 
			txt_minor "Attempting to install '$i'..."
			if pacman -S --noconfirm --asdeps --needed --color always $i 
				ver_base "Successfully installed '$i'"
			else
				err_base "Failed to install '$i'" 
			end
		end
		echo '========================================================================'
	end
end
txt_major "Finished installing AUR packages"
return