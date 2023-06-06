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

txt_major "Preparing to build AUR packages..."

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
if string match -rqi '^true$' $ZAI_AUR_PARU; and pacman -Qq paru &> /dev/null
	set -g _paru 'true'
end

if string match -rqi '^true$' $ZAI_AUR_PARU; and test -z $_paru; or string match -rqiv '^true$' $_paru
	txt_major "Attempting to build and install 'paru'..."

	su -c 'git clone "https://aur.archlinux.org/paru.git" "/aur/pkgbuild/paru"' aur 2>> "$(_err)" | tee -a "$(_log)" 
	if su -c 'cd /aur/pkgbuild/paru; PKGDEST="/aur/built" makepkg -si --noconfirm --needed' aur 2>> "$(_err)" | tee -a "$(_log)"
		txt_minor "Successfully built and installed 'paru'"
		set -g _paru 'true'
		clean_tmp
	else
		err_minor "Failed to build or install 'paru' in '/tmp'"
		clean_tmp
		# Common cause of failed builds is a full, or too small, tmpfs directory
		txt_minor "Attempting build and install outside of '/tmp'..."
		if su -c 'cd /aur/pkgbuild/paru; BUILDDIR="/aur/tmp" PKGDEST="/aur/built" makepkg -si --noconfirm --needed' aur 2>> "$(_err)" | tee -a "$(_log)"
			txt_minor "Successfully built and installed 'paru'"
			set -g _paru 'true'
			clean_tmp
		else
			clean_tmp
			err_minor "Failed to build or install 'paru'"
		end
	end
end

# Strips (and therefore ignores) comments and blank lines from the 'aurlist.list' file
set pkglist ( cat "$ZAI_DIR/pkglist/aurlist.list" | \
	grep -vx '([[:blank:]]*#.*)|([[:blank:]]*)' | \
	sed "$_valid_package_name" )

if string match -rqi '^true$' $_paru
	ver_minor "Updating 'paru' database..."
	paru --gendb --noconfirm 2>> "$(_err)" | tee -a "$(_log)"

	txt_major 'Beginning package compilation and installation...'
	for pkg in $pkglist
		clean_tmp
		txt_major "Attempting to build and install '$pkg'..."
		if su -c "yes | paru -Sa \
			--needed 		\
			--skipreview 	\
			--nokeepsrc 	\
			--cleanafter 	\
			--removemake 	\
			--noconfirm 	\
			--color always $pkg" aur 2>> "$(_err)" | tee -a "$(_log)"
			txt_base "Successfully built and installed '$pkg'"
		
		else
			err_base "Failed to build or install '$pkg' inside '/tmp'"
			clean_tmp
			txt_minor "Attempting to build and install '$pkg' outside of '/tmp'..."
			if su -c "yes | BUILDDIR='/aur/tmp' paru -Sa \
				--needed 		\
				--skipreview 	\
				--nokeepsrc 	\
				--cleanafter 	\
				--removemake 	\
				--noconfirm 	\
				--color always $pkg" aur 2>> "$(_err)" | tee -a "$(_log)"
				txt_base "Successfully built and installed '$pkg' outside of '/tmp'"
			else
				clean_tmp
				err_base "Failed to build or install '$pkg' outside of '/tmp'"
			end
		end
	end
else
	txt_major "Collecting AUR 'PKGBUILD' files..."
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

	txt_major 'Beginning package compilation and installation...'
	for _pkg_path in $build_dirs
		clean_tmp
		set _pkg (path basename $_pkg_path)
		txt_major "Attempting to build and install '$_pkg'..."
		if su -c "cd $_pkg_path; makepkg -sic \
				--needed \
				--noconfirm \
				--color always" aur 2>> "$(_err)" | tee -a "$(_log)"
			txt_base "Successfully built '$_pkg'"
		else
			clean_tmp
			err_base "Failed to build or install '$_pkg' inside of '/tmp'"
			txt_minor "Attempting build and install outside of '/tmp'..."
			if su -c "cd $_pkg_path; BUILDDIR='/aur/tmp' makepkg -sic \
					--needed \
					--noconfirm \
					--color always" aur 2>> "$(_err)" | tee -a "$(_log)"
				txt_base "Successfully built '$_pkg'"
			else
				clean_tmp
				err_base "Failed to build '$_pkg'"
			end
		end
	end

	txt_minor "Removing sources files after installation..."
	for _file in (find /aur/pkgbuild -maxdepth 1 -mindepth 1)
		rm -rfv "$_file" 2>> "$(_err)" | tee -a "$(_log)"
	end
end

set pkglist ( cat "$ZAI_DIR/pkglist/auropts.list" | \
	grep -vx '([[:blank:]]*#.*)|([[:blank:]]*)' | \
	sed "$_valid_package_name" )

if string match -rqi '^true$' $_paru
	ver_minor "Updating 'paru' database..."
	paru --gendb --noconfirm 2>> "$(_err)" | tee -a "$(_log)"

	txt_major "Beginning 'asdeps' package compilation and installation..."
	for pkg in $pkglist
		clean_tmp
		txt_major "Attempting to build and install '$pkg'..."
		if su -c "yes | paru -Sa \
			--needed 		\
			--skipreview 	\
			--nokeepsrc 	\
			--cleanafter 	\
			--removemake 	\
			--asdeps		\
			--noconfirm 	\
			--color always $pkg" aur 2>> "$(_err)" | tee -a "$(_log)"
			txt_base "Successfully built and installed '$pkg'"
		
		else
			err_base "Failed to build or install '$pkg' inside '/tmp'"
			clean_tmp
			txt_minor "Attempting to build and install '$pkg' outside of '/tmp'..."
			if su -c "yes | BUILDDIR='/aur/tmp' paru -Sa \
				--needed 		\
				--skipreview 	\
				--nokeepsrc 	\
				--cleanafter 	\
				--removemake 	\
				--asdeps		\
				--noconfirm 	\
				--color always $pkg" aur 2>> "$(_err)" | tee -a "$(_log)"
				txt_base "Successfully built and installed '$pkg' outside of '/tmp'"
			else
				clean_tmp
				err_base "Failed to build or install '$pkg' outside of '/tmp'"
			end
		end
	end
else
	txt_major "Collecting AUR 'PKGBUILD' files..."
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
			rm -rfv "$_folder" 2>> "$(_err)" | tee -a "$(_log)"
		end
	end

	# Crease list of folders in /aur/pkgbuild
	for bdir in (find /aur/pkgbuild -maxdepth 1 -mindepth 1 -type d)
		if path basename $bdir | grep -vqE '^\.'
			set -a -g build_dirs $bdir
		end
	end

	txt_major "Beginning 'asdeps' package compilation and installation..."
	for _pkg_path in $build_dirs
		clean_tmp
		set _pkg (path basename $_pkg_path)
		txt_major "Attempting to build and install '$_pkg'..."
		if su -c "cd $_pkg_path; makepkg -sic \
				--needed \
				--asdeps \
				--noconfirm \
				--color always" aur 2>> "$(_err)" | tee -a "$(_log)"
			txt_base "Successfully built and installed '$_pkg'"
		else
			clean_tmp
			err_base "Failed to build or install '$_pkg' inside of '/tmp'"
			txt_minor "Attempting build and install outside of '/tmp'..."
			if su -c "cd $_pkg_path; BUILDDIR='/aur/tmp' makepkg -sic \
					--needed \
					--asdeps \
					--noconfirm \
					--color always" aur 2>> "$(_err)" | tee -a "$(_log)"
				txt_base "Successfully built and installed '$_pkg' outside of '/tmp'"
			else
				clean_tmp
				err_base "Failed to build or install '$_pkg' outside of '/tmp'"
			end
		end
	end

	txt_minor "Removing sources files after installation..."
	for _file in (find /aur/pkgbuild -maxdepth 1 -mindepth 1)
		rm -rfv "$_file" 2>> "$(_err)" | tee -a "$(_log)"
	end
end

txt_major "Finished installing AUR packages"
pause
return