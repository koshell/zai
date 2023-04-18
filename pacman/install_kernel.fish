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

# Strips trailing and leading whitespace and other invalid characters
set --append pkglist ( echo "$ZAI_KERNEL" | sed "$_valid_package_name" )

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

if string match -rqi '^true$' "$ZAI_KERNEL_HEADERS_INSTALL"
	set --append pkglist ( echo "$ZAI_KERNEL_HEADERS" | sed "$_valid_package_name" )
end

if string match -rqi '^true$' "$ZAI_KERNEL_DOCS_INSTALL"
	set --append pkglist ( echo "$ZAI_KERNEL_DOCS" | sed "$_valid_package_name" )
end

set _paru ''
if pacman -Qq paru &> /dev/null
	set _paru 'true'
end

if string match -rqi '^true$' $ZAI_AUR_PARU; and string match -rqi '^true$' $_paru
	txt_major "Installing kernel..."

	txt_minor 'Attempting to install kernel packages in bulk...'
	if paru -S \
			--needed 		\
			--skipreview 	\
			--nokeepsrc 	\
			--cleanafter 	\
			--removemake 	\
			--noconfirm 	\
			--color always $pkglist 2>> "$(_err)" | tee -a "$(_log)" 
		txt_base 'Bulk install was successful'
	else
		err_minor 'Bulk kernel install failed, starting individual kernel package installation...'
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
else
	txt_major "Installing kernel..."

	txt_minor 'Attempting to install kernel packages in bulk...'
	if pacman -S --noconfirm --needed --color always $pkglist 2>> "$(_err)" | tee -a "$(_log)" 
		txt_base 'Bulk install was successful'
	else
		err_minor 'Bulk install failed, starting individual kernel package installation...'
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

set pkglist ''

if not pacman -Qq ( echo "$ZAI_KERNEL" | sed "$_valid_package_name" ) &> /dev/null
	set --append pkglist ( echo "$ZAI_KERNEL" | sed "$_valid_package_name" )
end

if string match -rqi '^true$' "$ZAI_KERNEL_HEADERS_INSTALL"; and not pacman -Qq ( echo "$ZAI_KERNEL_HEADERS" | sed "$_valid_package_name" ) &> /dev/null
	set --append pkglist ( echo "$ZAI_KERNEL_HEADERS" | sed "$_valid_package_name" )
end

if string match -rqi '^true$' "$ZAI_KERNEL_DOCS_INSTALL"; and not pacman -Qq ( echo "$ZAI_KERNEL_DOCS" | sed "$_valid_package_name" ) &> /dev/null
	set --append pkglist ( echo "$ZAI_KERNEL_DOCS" | sed "$_valid_package_name" )
end

# Possible that a kernel from the AUR was set in the config but 
# 'paru' wasn't installed therefore we need to build the kernel manually
if string match -rqvi '^true$' $_paru; and test -n $pkglist
	txt_major "Assuming kernel is a AUR package..."
	txt_minor "Attempting to collect AUR 'PKGBUILD' files..."
	for i in $pkglist
		echo '========================================================================' | tee -a "$(_log)"
		txt_minor "Attempting to clone '$i'..."
		set _clone_cmd ( string join '' \
			'git clone https://aur.archlinux.org/' $i '.git ' \
			'/aur/pkgbuild/' $i )
		if su -c "$_clone_cmd" aur 2>> "$(_err)" | tee -a "$(_log)"
			ver_base "Successfully cloned '$i'"
		else
			err_base "Failed to clone '$i'" 
		end
	end
	echo '========================================================================' | tee -a "$(_log)"
	
	txt_minor "Clearing failed clones..."
	for _folder in (find /aur/pkgbuild -maxdepth 1 -mindepth 1 -type d)
		if not test -e "$_folder/PKGBUILD"
			rm -rf -v "$_folder" 2>> "$(_err)" | tee -a "$(_log)"
		end
	end

	# Crease list of folders in /aur/pkgbuild
	for bdir in (find /aur/pkgbuild -maxdepth 1 -mindepth 1 -type d)
		if path basename $bdir | grep -vqE '^\.'
			set -a -g build_dirs $bdir
		end
	end

	txt_major 'Beginning kernel compilation and installation...'
	for _pkg_path in $build_dirs
		clean_tmp
		set _pkg (path basename $_pkg_path)
		txt_major "Attempting to build and install '$_pkg'..."
		if su -c "cd $_pkg_path; makepkg -sic \
				--needed \
				--noconfirm \
				--color always" aur 2>> "$(_err)" | tee -a "$(_log)"
			txt_base "Successfully built and installed '$_pkg'"
		else
			clean_tmp
			err_base "Failed to build or install '$_pkg' inside of '/tmp'"
			txt_minor "Attempting build and install outside of '/tmp'..."
			if su -c "cd $_pkg_path; BUILDDIR='/aur/tmp' makepkg -sic \
					--needed \
					--noconfirm \
					--color always" aur 2>> "$(_err)" | tee -a "$(_log)"
				txt_base "Successfully built and installed '$_pkg'"
			else
				clean_tmp
				err_base "Failed to build or install '$_pkg'"
			end
		end
	end

	txt_minor "Removing sources files after installation..."
	for _file in (find /aur/pkgbuild -maxdepth 1 -mindepth 1)
		rm -rfv "$_file" 2>> "$(_err)" | tee -a "$(_log)"
	end

	set failed_packages ''

	if not pacman -Qq ( echo "$ZAI_KERNEL" | sed "$_valid_package_name" ) &> /dev/null
		set --append failed_packages ( echo "$ZAI_KERNEL" | sed "$_valid_package_name" )
	end
	
	if string match -rqi '^true$' "$ZAI_KERNEL_HEADERS_INSTALL"; and not pacman -Qq ( echo "$ZAI_KERNEL_HEADERS" | sed "$_valid_package_name" ) &> /dev/null
		set --append failed_packages ( echo "$ZAI_KERNEL_HEADERS" | sed "$_valid_package_name" )
	end
	
	if string match -rqi '^true$' "$ZAI_KERNEL_DOCS_INSTALL"; and not pacman -Qq ( echo "$ZAI_KERNEL_DOCS" | sed "$_valid_package_name" ) &> /dev/null
		set --append failed_packages ( echo "$ZAI_KERNEL_DOCS" | sed "$_valid_package_name" )
	end

	if test -n $failed_packages
		for i in $failed_packages
			err_major "Failed to install $i"
		end
		abort
	end
else if test -n $pkglist
	for i in $pkglist
		err_major "Failed to install $i"
	end
	abort
end

echo '' | tee -a "$(_log)" 
txt_major "Finished installing kernel"
return