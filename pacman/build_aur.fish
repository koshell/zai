#!/usr/bin/env fish

set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format functions
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

# Load list of packages to install
set pkglist (cat $ZAI_DIR/pacman/aurlist.txt)

function clean_tmp
	txt_base "Cleaning up loose build files..."
	for _path in ( find /tmp/makepkg -mindepth 1 -maxdepth 1 )
		if test -n $_path
			rm -rf (_v) $_path
		end
	end
	for _path in ( find /aur/tmp -mindepth 1 -maxdepth 1 )
		if test -n $_path
			rm -rf (_v) $_path
		end
	end
	for _path in ( find /tmp -mindepth 1 -maxdepth 1 | \
				   grep -E '(^/tmp/cargo-install)|(^/tmp/rustc)|(^/tmp/yarn)' )
		rm -rf (_v) $_path
	end
end

txt_major "Preparing to build AUR packages..."

txt_minor "Refreshing and updating repo database..."
pacman -Syu --noconfirm --color always

txt_minor "Creating 'aur' system user to run builds without sudo..."
if not useradd --create-home --home-dir '/aur' --comment 'AUR package builder' --system aur
	err_major "Failed to create 'aur' user"
	abort
end

txt_minor "Giving 'aur' user access to pacman commands..."
set _sudoers (string join '' \
	'aur ALL=(ALL) NOPASSWD:/bin/pacman *\n' \
	'aur ALL=(ALL) NOPASSWD:/sbin/pacman *\n' \
	'aur ALL=(ALL) NOPASSWD:/usr/bin/pacman *\n' \
	'aur ALL=(ALL) NOPASSWD:/usr/sbin/pacman *')
#set _sudoers 'aur ALL = NOPASSWD : ALL'
mkdir -p (_v) /etc/sudoers.d
if echo -e $_sudoers > /etc/sudoers.d/60_aur
	txt_base "Successfully gave 'aur' user access to pacman"
else
	err_base "Failed to give 'aur' user access to pacman"
	abort
end

# We need these folders to exist for makepkg to succeed
txt_major "Creating directories needed to successfully build packages..."
txt_minor "Creating '/aur/pkgbuild' directory..."
su -c "mkdir -p $(_v) /aur/pkgbuild" aur && \
	txt_base "Successfully created '/aur/pkgbuild'" || \
	err_base "Failed to create '/aur/pkgbuild'"
txt_minor "Creating '/aur/built' directory..."
su -c "mkdir -p $(_v) /aur/built" aur && \
	txt_base "Successfully created '/aur/built'" || \
	err_base "Failed to create '/aur/built'"
txt_minor "Creating '/aur/tmp' directory..."
su -c "mkdir -p $(_v) /aur/tmp" aur && \
	txt_base "Successfully created '/aur/tmp'" || \
	err_base "Failed to create '/aur/tmp'"

# Incase tmpfs failed earlier we might need to make a '/tmp' directory
# This is likely overkill but fuck it, more errors are better then less
if test -e /tmp/makepkg && test -d /tmp/makepkg
	if test (stat -c '%U') != 'aur'
		txt_minor "Repairing '/tmp/makepkg/' permissions..."
		chown -c aur /tmp/makepkg
	end
else
	txt_minor "Creating '/tmp/makepkg'..."
	mkdir -p (_v) /tmp/makepkg && \
		txt_base "Successfully created '/tmp/makepkg'" || \
		err_base "Failed to create '/tmp/makepkg'"
	txt_minor "Setting folder ownership..."
	chown -c aur /tmp/makepkg && \
		txt_base "Successfully set owner of '/tmp/makepkg'" || \
		err_base "Failed to set owner of '/tmp/makepkg'"
end

txt_major "Attempting to build 'paru'..."
# Lets build 'paru' first to make life easier...
set _paru 'false'
su -c 'git clone "https://aur.archlinux.org/paru.git" "/aur/pkgbuild/paru"' aur
if su -c 'cd /aur/pkgbuild/paru; PKGDEST="/aur/built" makepkg -s --noconfirm --needed' aur
	txt_minor "Successfully built 'paru'"
	set _paru 'true'
	clean_tmp
else
	err_minor "Failed to build 'paru' in '/tmp'"
	clean_tmp
	# Common cause of failed builds is a full or too small /tmp
	txt_minor "Attempting build without using '/tmp'..."
	if su -c 'cd /aur/pkgbuild/paru; BUILDDIR="/aur/tmp" PKGDEST="/aur/built" makepkg -s --noconfirm --needed' aur
		txt_minor "Successfully built 'paru'"
		set _paru 'true'
		clean_tmp
	else
		clean_tmp
		err_minor "Failed to build 'paru'"
	end
end

if string match -rqi '^true$' $_paru
	txt_major "Installing 'paru'..."
	if pacman -U --noconfirm --needed --color always (find /aur/built -type f | grep -iF 'paru')
		txt_base "Successfully installed 'paru'"
	else
		err_base "Failed to install 'paru'"
		set _paru 'false'
	end
end

if string match -rqi '^true$' $_paru
	txt_major 'Beginning package compilation...'
	for pkg in $pkglist
		clean_tmp
		txt_major "Attempting to build & install '$pkg'..."
		if su -c "yes | paru -Sa \
			--needed \
			--skipreview \
			--nokeepsrc \
			--cleanafter \
			--removemake \
			--noconfirm $pkg" aur
			txt_base "Successfully built & installed '$pkg'"
		
		else
			err_base "Failed to build or install '$pkg' inside '/tmp'"
			clean_tmp
			txt_minor "Attempting build outside '/tmp'..."
			if su -c "BUILDDIR='/aur/tmp' yes | paru -Sa \
				--needed \
				--skipreview \
				--nokeepsrc \
				--cleanafter \
				--removemake \
				--noconfirm $pkg" aur
				txt_base "Successfully built & installed '$pkg'"
			else
				clean_tmp
				err_base "Failed to build or install '$pkg'"
			end
		end
	end
else
	txt_major "Collecting AUR PKGBUILD files..."
	for i in $pkglist
		echo '========================================================================' 
		txt_minor "Attempting to clone '$i'..."
		set _clone_cmd ( string join '' \
			'git clone https://aur.archlinux.org/' $i '.git ' \
			'/aur/pkgbuild/' $i )
		if su -c "$_clone_cmd" aur
			ver_base "Successfully cloned '$i'"
		else
			err_base "Failed to clone '$i'" 
		end
	end
	echo '========================================================================' 
	
	txt_minor "Clearing failed clones..."
	for _folder in (find /aur/pkgbuild -maxdepth 1 -mindepth 1 -type d)
		if not test -e "$_folder/PKGBUILD"
			rm -rf (_v) "$_folder"
		end
	end

	# List folders in /aur/pkgbuild
	for bdir in (find /aur/pkgbuild -maxdepth 1 -mindepth 1 -type d)
		if path basename $bdir | grep -vqE '^\.'
			set -a -g build_dirs $bdir
		end
	end

	txt_major 'Beginning package compilation...'
	for _pkg_path in $build_dirs
		set _pkg (path basename $_pkg_path)
		txt_major "Attempting to build '$_pkg'..."
		clean_tmp
		if su -c "cd $_pkg_path; \
			PKGDEST='/aur/built' makepkg -s" aur
			
			txt_base "Successfully built '$_pkg'"
		else
			err_base "Failed to build '$_pkg' inside '/tmp'"
			clean_tmp

			txt_minor "Attempting build outside '/tmp'..."
			if su -c "cd $_pkg_path; \
				BUILDDIR='/aur/tmp' PKGDEST='/aur/built' makepkg -s" aur
				txt_base "Successfully built '$_pkg'"
			else
				clean_tmp
				err_base "Failed to build '$_pkg'"
			end
		end
	end

	txt_minor "Removing sources files before installing..."
	for _folder in (find /aur/pkgbuild -maxdepth 1 -mindepth 1 -type d)
		rm -rf (_v) "$_folder"
	end

	set built_pkgs (find /aur/built -maxdepth 1 -mindepth 1 -type f)
	if test -n $built_pkgs
		txt_minor 'Attempting to install built packages in bulk...'
		if pacman -U --noconfirm --needed --color always $built_pkgs
			txt_base 'Bulk install was succesful'
		else
			err_minor 'Bulk install failed, starting individual package installation...'
			for i in $built_pkgs
				set _pkg_name (path basename $i)
				echo '========================================================================' 
				txt_minor "Attempting to install '$_pkg_name'..."
				if pacman -U --noconfirm --needed --color always $i 
					txt_base "Successfully installed '$_pkg_name'"
				else
					err_base "Failed to install '$_pkg_name'" 
				end
			end
			echo '========================================================================'
		end
	else if -n $pkglist
		err_major "No packages were built!"
	end
end

txt_major "Finished installing AUR packages"
pause
return