#!/usr/bin/env fish

set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format variables
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

set _conf '/etc/makepkg.conf'

ver_minor "Backing up $_conf..."
cp (_v) -f "$_conf" "$ZAI_DIR/backups/makepkg.conf"

txt_major "Optimising 'makepkg.conf' settings..."

txt_minor "Enabling native optimised C/C++ compilation..."
if replace_line 'CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fno-plt -fexceptions' \
				'CFLAGS="-march=native -O2 -pipe -fno-plt -fexceptions' $_conf
	txt_base "Successfully enabled optimised C/C++ compilation"
else
	err_base "Failed to enable optimised C/C++ compilation"
end

txt_minor "Enabling native optimised rust compilation..."
if replace_line '#RUSTFLAGS="-C opt-level=2"' \
				'RUSTFLAGS="-C opt-level=2 -C target-cpu=native"' $_conf
	txt_base "Successfully enabled optimised rust compilation"
else
	err_base "Failed to enable optimised rust compilation"
end

txt_minor "Enabling multithreaded compilation..."
if replace_line '#MAKEFLAGS="-j2"' \
				'MAKEFLAGS="-j$(nproc)"' $_conf
	txt_base "Successfully enabled multithreaded compilation"
else
	err_base "Failed to enable multithreaded compilation"
end

txt_minor "Enabling compilation in tmpfs..."
if replace_line '#BUILDDIR=/tmp/makepkg' \
				'BUILDDIR=/tmp/makepkg' $_conf
	txt_base "Successfully enabled compilation in tmpfs"
else
	err_base "Failed to enable compilation in tmpfs"
end

txt_minor "Changing package compressing to lz4..."
if replace_line "PKGEXT='.pkg.tar.zst'" \
				"PKGEXT='.pkg.tar.lz4'" $_conf
	txt_base "Successfully set package compressing to lz4"
else
	err_base "Failed to set package compressing to lz4"
end

txt_minor "Enabling multithreaded package compression..."
if replace_line "COMPRESSZST=(zstd -c -z -q -)" \
				"COMPRESSZST=(zstd -c -z -q --threads=0 -)" $_conf
	txt_base "Successfully enabled multithreaded zstd compression"
else
	err_base "Failed to enable multithreaded zstd compression"
end
if replace_line "COMPRESSXZ=(xz -c -z -)" \
				"COMPRESSXZ=(xz -c -z --threads=0 -)" $_conf
	txt_base "Successfully enabled multithreaded xz compression"
else
	err_base "Failed to enable multithreaded xz compression"
end
if pacman -S --noconfirm --needed --color always pigz &>/dev/null
	if replace_line "COMPRESSGZ=(gzip -c -f -n)" \
					"COMPRESSGZ=(pigz -c -f -n)" $_conf
		txt_base "Successfully enabled multithreaded gzip compression"
	else
		err_base "Failed to enable multithreaded gzip compression"
	end
else
	err_base "Failed to enable multithreaded gzip compression"
end
if pacman -S --noconfirm --needed --color always pbzip2 &>/dev/null
	if replace_line "COMPRESSBZ2=(bzip2 -c -f)" \
					"COMPRESSBZ2=(pbzip2 -c -f)" $_conf
		txt_base "Successfully enabled multithreaded bzip2 compression"
	else
		err_base "Failed to enable multithreaded bzip2 compression"
	end
else
	err_base "Failed to enable multithreaded bzip2 compression"
end

txt_minor "Enabling  link time optimisations..."
if replace_line "OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug !lto)" \
				"OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug lto)" $_conf
	txt_base "Successfully enabled link time optimisations"
else
	err_base "Failed to enable link time optimisations"
end

txt_minor "Attempt #1 at disabling the 'dev only' errors..."
if replace_line '-fstack-clash-protection -fcf-protection"' \
				'-fstack-clash-protection -fcf-protection -Wno-dev"' \
				$_conf
	txt_base "Successfully applied attempt #1"
else
	err_base "Failed to apply attempt #1"
end

pretty_diff "$ZAI_DIR/backups/makepkg.conf" "$_conf"

txt_major "Finished optimising 'makepkg.conf' settings"
return