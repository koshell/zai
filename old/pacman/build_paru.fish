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

# This function cleans up loose files that might 
# be created as part of the build process
function clean_tmp
	txt_base "Cleaning up loose build files..."
	for _path in ( find /tmp/makepkg -mindepth 1 -maxdepth 1 )
		if test -n $_path
			rm -rfv $_path 2>> "$(_err)" | tee -a "$(_log)" 
		end
	end
	for _path in ( find /aur/tmp -mindepth 1 -maxdepth 1 )
		if test -n $_path
			rm -rfv $_path 2>> "$(_err)" | tee -a "$(_log)" 
		end
	end
	for _path in ( find /tmp -mindepth 1 -maxdepth 1 | \
			grep -E '(^/tmp/cargo-install)|(^/tmp/rustc)|(^/tmp/yarn)' )
		
		rm -rfv $_path 2>> "$(_err)" | tee -a "$(_log)" 
	end
end

txt_major "Preparing to build and install 'paru'..."

# If tmpfs failed earlier we might need to make a '/tmp' directory
if test -d /tmp/makepkg
	# This is likely overkill but fuck it, more errors are better then less
	if test (stat -c '%U') != 'aur'
		txt_minor "Repairing '/tmp/makepkg' permissions..."
		chown -c aur /tmp/makepkg 2>> "$(_err)" | tee -a "$(_log)"
	end
else
	txt_minor "Creating '/tmp/makepkg'..."
	if mkdir -p -v /tmp/makepkg 2>> "$(_err)" | tee -a "$(_log)"
		txt_base "Successfully created '/tmp/makepkg'"
	else
		err_base "Failed to create '/tmp/makepkg'"
	end
	
	txt_minor "Setting folder ownership..."
	if chown -c aur /tmp/makepkg 2>> "$(_err)" | tee -a "$(_log)"
		txt_base "Successfully set owner of '/tmp/makepkg'"
	else
		err_base "Failed to set owner of '/tmp/makepkg'"
	end
end

# Check if paru was installed by something else
if not pacman -Qq paru &> /dev/null
	txt_major "Attempting to build and install 'paru'..."
	su -c 'git clone "https://aur.archlinux.org/paru.git" "/aur/pkgbuild/paru"' aur 2>> "$(_err)" | tee -a "$(_log)" 
	clean_tmp
	if su -c "cd /aur/pkgbuild/paru; PKGDEST='/aur/built' makepkg -sic \
			--needed \
			--noconfirm \
			--color always" aur 2>> "$(_err)" | tee -a "$(_log)"
		txt_minor "Successfully built and installed 'paru'"
		clean_tmp
	else
		err_minor "Failed to build or install 'paru' in '/tmp'"
		# Common cause of failed builds is a full, or too small, tmpfs directory
		txt_minor "Attempting build and install outside of '/tmp'..."
		clean_tmp
		if su -c "cd /aur/pkgbuild/paru; BUILDDIR='/aur/tmp' PKGDEST='/aur/built' makepkg -sic \
				--needed \
				--noconfirm \
				--color always" aur 2>> "$(_err)" | tee -a "$(_log)"
			txt_minor "Successfully built and installed 'paru'"
			clean_tmp
		else
			err_minor "Failed to build or install 'paru'"
			clean_tmp
		end
	end
	txt_minor "Removing source files after attempted installation..."
	for _file in (find /aur/pkgbuild -maxdepth 1 -mindepth 1)
		rm -rfv "$_file" 2>> "$(_err)" | tee -a "$(_log)"
	end
end

if  pacman -Qq paru &> /dev/null
	ver_minor "Updating 'paru' database..."
	paru --gendb --noconfirm 2>> "$(_err)" | tee -a "$(_log)"
end

txt_major "Finished building and installing 'paru'"
pause
return