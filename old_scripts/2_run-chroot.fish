#!/usr/bin/env fish

# If '$ZAI_DIR' is explicitly set we use that otherwise 
# we use the default location of '/zai'
if test -z "$ZAI_DIR"
	# If ZAI_DIR is empty we set it to '/zai'
	set -x ZAI_DIR '/zai'
else
	# Otherwise just export it's value
	# Unsure if this is strictly needed
	set -x ZAI_DIR
end

# For logging
set _name ( path change-extension '' ( basename ( status filename )))

# Load config values
source "$ZAI_DIR/env"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

# Load colour and format variables
source "$ZAI_DIR/source/format.fish"

# Needed to set '_backup_dir' and '_log_dir'
reset_dirs

txt_major "Continuing installation in chroot..."
txt_minor "Setting timezone..."
if test -e "/usr/share/zoneinfo/$ZAI_TIME"
	zai_verbose "$( ln -sfv "/usr/share/zoneinfo/$ZAI_TIME" '/etc/localtime' 2>> "$(_err)" )"
	hwclock --systohc | tee -a "$(_log)"
else
	err_minor "Can't resolve '$ZAI_TIME' to a file"
	err_base "It is resolved like this:"
	err_base "/usr/share/zoneinfo/$ZAI_TIME"
	err_base "Confirm that the above path is valid and update the config if not"
	abort
end

# Setting the locale
bash "$ZAI_DIR/config/locale.bash"

txt_minor "Setting hostname to '$ZAI_NAME'..."
echo "$ZAI_NAME" > /etc/hostname
echo "echo \"$ZAI_NAME\" > /etc/hostname" >> "$(_log)"

if string match -rqi '^true$' $ZAI_PKG_OPTIMISE
	# Optimise 'makepkg.conf' settings
	fish "$ZAI_DIR/pacman/makepkg.fish"
end

if string match -rqi '^true$' $ZAI_PKG_AUTOKEY
	# Get pacman to automatically retrieve gpg keys
	ver_minor "Configuring pacman to automatically retrieve gpg keys..."
	zai_verbose "$( cp -vf '/etc/pacman.d/gnupg/gpg.conf' "$_backup_dir/etc/pacman.d/gnupg/gpg.conf" 2>> "$(_err)" )"
	echo 'auto-key-retrieve' >> /etc/pacman.d/gnupg/gpg.conf
	pretty_diff "$_backup_dir/etc/pacman.d/gnupg/gpg.conf" '/etc/pacman.d/gnupg/gpg.conf'
end

##################################################################
########################## Pacman Start ##########################
txt_major "Beginning large-scale package install..."

txt_minor "Refreshing and updating repo database..."
zai_verbose "$( pacman -Syu --noconfirm --color always 2>> "$(_err)" )"
txt_base "Finished updating repo database"

# Create AUR user
fish "$ZAI_DIR/pacman/aur_user.fish"

# Build 'paru' if enabled
if string match -rqi '^true$' $ZAI_AUR_PARU
	fish "$ZAI_DIR/pacman/build_paru.fish"
end

# Install kernel
fish "$ZAI_DIR/pacman/install_kernel.fish"

# Install offical packages
fish "$ZAI_DIR/pacman/install_pkgs.fish"

if string match -rqi '^true$' $ZAI_PKG_LOCALREPO
	# Install AUR packages
	fish "$ZAI_DIR/pacman/install_aur.fish"
else
	# Build AUR packages
	fish "$ZAI_DIR/pacman/build_aur.fish"
end

if pacman -Qq limine > /dev/null
	# Installing limine
	bash "$ZAI_DIR/limine/limine-install.bash"
else
	err_major "The bootloader 'limine' wasn't installed"
	err_base "This is a critical error"
	abort
end
########################### Pacman End ###########################
##################################################################

txt_minor "Updating 'pacman.conf' for normal usage..."
fish "$ZAI_DIR/pacman/post-install.fish"

txt_minor "Installing other '/etc' files..."
zai_verbose "$( cp -vrf $ZAI_DIR/etc/* /etc/ 2>> "$(_err)" )"

txt_minor "Fixing a systemd initramfs issue..."
touch /etc/vconsole.conf

if test "$ZAI_PKG_PD_REFLECT" -gt 1
	txt_minor "Updating 'reflector.conf' to use $ZAI_PKG_PD_REFLECT threads..."
	replace_line "^#--threads.*" "--threads $ZAI_PKG_PD_REFLECT" '/etc/xdg/reflector/reflector.conf'
end

txt_major "Updating mirrorlist..."
# This processes each line of 'reflector.conf' and removes comments
# and blank lines, then feeds those as arguments to reflector
if grep -vxE '(^_*#.*)|(^_*)' /etc/xdg/reflector/reflector.conf | xargs reflector >> "$(_log)" 2>> "$(_err)" 
	ver_base "Successfully updated mirrorlist"
else
	err_minor "Failed to update mirrorlist"
end

txt_major "Rebuilding package database with new 'pacman.conf'..."
zai_verbose "$( yes | pacman -Scc  --noconfirm --color always			2>> "$(_err)" )"
zai_verbose "$( yes | pacman -Syyu --noconfirm --color always --needed 	2>> "$(_err)" )"

if string match -rqi '^true$' $ZAI_PKG_CLEAN
	# Clean up any orphans agressively
	fish "$ZAI_DIR/pacman/clean_orphans.fish"
end

txt_major "Rebuilding initramfs..."
zai_verbose "$( mkinitcpio -P 2>> "$(_err)" )"

echo -e "\nSet 'root' password:"
passwd root

#########################################################
##################### Systemd Start #####################
txt_major "Configuring systemd services..."

for service in $ZAI_SYS_ENABLE
	if test -n "$service"
		if zai_verbose "$( systemctl enable $service 2>> "$(_err)" )"
			ver_base "Successfully enabled '$service'"
		else
			err_minor "Failed to enable '$service'"
		end
	end
end

for service in $ZAI_SYS_DISABLE
	if test -n "$service"
		if zai_verbose "$( systemctl disable $service 2>> "$(_err)" )"
			ver_base "Successfully disabled '$service'"
		else
			err_minor "Failed to disable '$service'"
		end	
	end
end

for service in $ZAI_SYS_MASK
	if test -n "$service"
		if zai_verbose "$( systemctl mask $service 2>> "$(_err)" )"
			ver_base "Successfully masked '$service'"
		else
			err_minor "Failed to mask '$service'"
		end	
	end
end

txt_minor "Finished configuring services\n"
###################### Systemd End ######################
#########################################################

txt_major "Copying post-install scripts to '/root'..."
for i in (find "$ZAI_DIR/post-install" -mindepth 1 -maxdepth 1)
	if echo "$(path basename $i)" | grep -qvE '^\.'
		zai_verbose "$( cp -vrf $i /root/ 2>> "$(_err)" )"
	end
end

txt_major "Installation finished!" 
echo '' | tee -a "$(_log)"

cat /etc/fstab >> "$(_log)"
bat --paging never --language fstab /etc/fstab
echo "Please confirm that the 'fstab' is configured correctly." | tee -a "$(_log)"
echo "Then feel free to reboot, installation is complete!" 		| tee -a "$(_log)"
# Done!
