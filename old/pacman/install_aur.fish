#!/usr/bin/env fish

set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format functions
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

# Possible valid package names as according to: 
# https://wiki.archlinux.org/title/Arch_package_guidelines#Package_naming
#
# Technically not in compliance since we don't enforce the following:
# 	"Names are not allowed to start with hyphens or dots." 
# 	"All letters should be lowercase."
# 
set _valid_package_name (string join '' \
	's/' 					 	 \
		'[[:blank:]]*' 			 \
		'(\(' 				     \
			'[[:alnum:]]' 	'\|' \
			'@' 			'\|' \
			'\.' 			'\|' \
			'_' 			'\|' \
			'\+' 			'\|' \
			'-' 			     \
		'\)*)'					 \
	'.*/\1/g')

# Strips (and therefore ignores) comments and blank lines from the 'aurlist.list' file
set pkglist ( cat "$ZAI_DIR/pkglist/aurlist.list" | \
	grep -vx '([[:blank:]]*#.*)|([[:blank:]]*)' | \
	sed "$_valid_package_name" )

if string match -rqi '^true$' $ZAI_AUR_PARU; and pacman -Qq paru &> /dev/null
	if test -n $pkglist
		txt_major "Installing user specified AUR packages..."

		txt_minor 'Attempting to install packages in bulk...'
		if paru -S \
				--needed 		\
				--skipreview 	\
				--nokeepsrc 	\
				--cleanafter 	\
				--removemake 	\
				--noconfirm 	\
				--color always $pkglist 2>> "$(_err)" | tee -a "$(_log)" 
			txt_base 'Bulk install was succesful'
		else
			err_minor 'Bulk install failed, starting individual package installation...'
			for i in $pkglist
				echo '========================================================================' | tee -a "$(_log)"
				txt_minor "Attempting to install '$i'..."
				if paru -S \
						--needed 		\
						--skipreview 	\
						--nokeepsrc 	\
						--cleanafter 	\
						--removemake 	\
						--noconfirm 	\
						--color always $i 2>> "$(_err)" | tee -a "$(_log)" 
					ver_base "Successfully installed '$i'"
				else
					err_base "Failed to install '$i'"
				end
			end
			echo '========================================================================' | tee -a "$(_log)"
		end
	end

	# Strips (and therefore allows) comments and blank lines from the 'auropts.list' file
	set pkglist ( cat "$ZAI_DIR/pkglist/auropts.list" | \
		grep -vx '([[:blank:]]*#.*)|([[:blank:]]*)' | \
		sed "$_valid_package_name" )

	if test -n $pkglist
		txt_major "Installing user specified 'asdeps' AUR packages..."

		txt_minor "Attempting to install 'asdeps' packages in bulk..."
		if paru -S \
				--needed 		\
				--skipreview 	\
				--nokeepsrc 	\
				--cleanafter 	\
				--removemake 	\
				--noconfirm 	\
				--color always $pkglist 2>> "$(_err)" | tee -a "$(_log)" 
			txt_base 'Bulk install was succesful'
		else

			err_minor "Bulk install failed, starting individual 'asdeps' package installation..."
			for i in $pkglist
				echo '========================================================================' | tee -a "$(_log)"
				txt_minor "Attempting to install '$i'..."
				if paru -S \
						--needed 		\
						--skipreview 	\
						--nokeepsrc 	\
						--cleanafter 	\
						--removemake 	\
						--noconfirm 	\
						--color always $i 2>> "$(_err)" | tee -a "$(_log)" 
					ver_base "Successfully installed '$i'"
				else
					err_base "Failed to install '$i'" 
				end
			end
			echo '========================================================================' | tee -a "$(_log)"
		end
	end
else
	if test -n $pkglist
		txt_major "Installing user specified AUR packages..."

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

	# Strips (and therefore allows) comments and blank lines from the 'auropts.list' file
	set pkglist ( cat "$ZAI_DIR/pkglist/auropts.list" | \
		grep -vx '([[:blank:]]*#.*)|([[:blank:]]*)' | \
		sed "$_valid_package_name" )

	if test -n $pkglist
		txt_major "Installing user specified 'asdeps' AUR packages..."

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
end


echo '' | tee -a "$(_log)" 
txt_major "Finished installing AUR packages"
return