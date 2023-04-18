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

txt_major "Continuing installation in chroot..."
txt_minor "Setting timezone..."
if test -e "/usr/share/zoneinfo/$ZAI_TIME"
	ln -sf -v /usr/share/zoneinfo/$ZAI_TIME /etc/localtime 		>> "$(_log)"
	hwclock --systohc 											| tee -a "$(_log)"	
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

if string match -rqi '^true$' $ZAI_PKG_OPTIMISE
	# Optimise 'makepkg.conf' settings
	fish  "$ZAI_DIR/pacman/makepkg.fish"
end

# Get pacman to automatically retrieve gpg keys
ver_minor "Configuring pacman to automatically retrieve gpg keys..."
cp (_v) /etc/pacman.d/gnupg/gpg.conf "$ZAI_DIR/backups/etc/pacman.d/gnupg/gpg.conf" | tee -a "$(_log)"
echo 'auto-key-retrieve' >> /etc/pacman.d/gnupg/gpg.conf
pretty_diff "$ZAI_DIR/backups/etc/pacman.d/gnupg/gpg.conf" "/etc/pacman.d/gnupg/gpg.conf"

###################################################################
txt_major "Beginning large-scale package install..."

# Install offical packages
fish "$ZAI_DIR/pacman/install_pkgs.fish"


if string match -rqi '^true$' $ZAI_PKG_LOCALREPO
	# Install AUR packages
	fish "$ZAI_DIR/pacman/install_aur.fish"
else
	# Build AUR packages
	fish "$ZAI_DIR/pacman/build_aur.fish"
end

if  pacman -Qqs limine | grep -qE '^limine$'
	# Installing limine
	bash "$ZAI_DIR/limine/limine-install.bash"
else
	err_major "The bootloader 'limine' wasn't installed"
	err_base "This is a critical error"
	err_base "Aborting..."
	exit 1
end
###################################################################

txt_minor "Updating 'pacman.conf' for normal usage..."
fish "$ZAI_DIR/pacman/post-install.fish"

txt_minor "Installing other '/etc' files..."
cp (_v) -r $ZAI_DIR/etc/* /etc/	| tee -a "$(_log)"

txt_minor "Fixing a systemd initramfs issue..."
touch /etc/vconsole.conf

txt_major "Updating mirrorlist..."
# This processes each line of 'reflector.conf' and removes comments
# and blank lines, then feeds those as arguments to reflector
if grep -vxE '(^_*#.*)|(^_*)' /etc/xdg/reflector/reflector.conf | xargs reflector >> "$(_log)"
	ver_base "Successfully updated mirrorlist"
else
	err_minor "Failed to update mirrorlist"
end

txt_major "Rebuilding package database with new 'pacman.conf'..."
yes | pacman -Scc  --noconfirm --color always			| tee -a "$(_log)"
yes | pacman -Syyu --noconfirm --color always --needed 	| tee -a "$(_log)"

# Clean up any orphans agressively
fish "$ZAI_DIR/pacman/clean_orphans.fish"

txt_major "Rebuilding initramfs..."
mkinitcpio -P | tee -a "$(_log)"

echo -e "\nSet 'root' password:"
passwd root

#########################################################
txt_major "Enabling systemd services..."

if systemctl --quiet enable ly
	ver_base "Successfully enabled 'ly'"
else
	err_minor "Failed to enable 'ly'"
end

if systemctl --quiet disable getty@tty2.service
	ver_base "Successfully disabled 'getty@tty2'"
else
	err_minor "Failed to disable 'getty@tty2'"
end

if systemctl --quiet mask getty@tty2.service
	ver_base "Successfully masked 'getty@tty2'"
else
	err_minor "Failed to mask 'getty@tty2'"
end

if systemctl --quiet enable NetworkManager
	ver_base "Successfully enabled 'NetworkManager'"
else
	err_minor "Failed to enable 'NetworkManager'"
end

if systemctl --quiet enable auditd
	ver_base "Successfully enabled 'auditd'"
else
	err_minor "Failed to enable 'auditd'"
end

if systemctl --quiet enable sshd
	ver_base "Successfully enabled 'sshd'"
else
	err_minor "Failed to enable 'sshd'"
end

if systemctl --quiet enable libvirtd
	ver_base "Successfully enabled 'libvirtd'"
else
	err_minor "Failed to enable 'libvirtd'"
end

if systemctl --quiet enable reflector
	ver_base "Successfully enabled 'reflector'"
else
	err_minor "Failed to enable 'reflector'"
end

txt_minor "Finished enabling services.\n"
#########################################################

txt_major "Copying post-install scripts to '/root'..."
for i in (find "$ZAI_DIR/post-install" -mindepth 1 -maxdepth 1)
	if echo "$(path basename $i)" | grep -qvE '^\.'
		cp (_v) -rf $i /root/ | tee -a "$(_log)"
	end
end

echo -e "$major Installation finished!\n"

cat /etc/fstab >> "$(_log)"
bat --paging never --language fstab /etc/fstab
echo "Please confirm that the 'fstab' is configured correctly." >> "$(_log)"
echo "Then feel free to reboot, installation is complete!" 		>> "$(_log)"
# Done!
