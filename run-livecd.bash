#!/usr/bin/env bash
# shellcheck disable=SC2155,SC2046
#
readonly __version__='0.0.1'
readonly __author__='zaiju'

# Script root directory
export ZAI_DIR="$(dirname -- "$(readlink -f "$0")")"

# For logging
_name='run-livecd'

# Load config values
# shellcheck source=source/config.sh
source "$ZAI_DIR/source/config.sh"

# Load colour and format functions
# shellcheck source=source/format.bash
source "$ZAI_DIR/source/format.bash"

# Load helper functions
# shellcheck source=source/functions.bash
source "$ZAI_DIR/source/functions.bash"

if [[ ! $ZAI_DIR == '/zai' ]]; then
	_log='/tmp/zai.log'
	_err='/tmp/zai.err'
	clear
	echo -n "Starting " | tee -a "$(_log)"
	_txtbold
	_txtgrn
	echo "Zaiju's Arch Installer" | tee -a "$(_log)"
	_txtclean
	echo -e "Version: ${__version__}\n" | tee -a "$(_log)"
	txt_major "Copying scripts to '/zai'..."
	rm -rf /zai > /dev/null
	if cp -ar "${ZAI_DIR}" '/zai'; then
		txt_major "Passing execution into '/zai'..."
		exec '/zai/run-livecd.bash' || err_major 'Failed to pass execution, aborting...'; exit 1
	else
		err_major "Copying scripts failed"
		abort
	fi
fi

# VM testing
if [[ ${ZAI_VMDEGUB,,} =~ ^true$ ]]; then
	txt_major "Creating symlinks for testing..."
	ln -vs /dev/vda  "/dev/${ZAI_BLK}"
	ln -vs /dev/vda1 "/dev/${ZAI_BLK}${ZAI_BLK_PP}1"
	ln -vs /dev/vda2 "/dev/${ZAI_BLK}${ZAI_BLK_PP}2"
	ln -vs /dev/vda3 "/dev/${ZAI_BLK}${ZAI_BLK_PP}3"
	ln -vs /dev/vda4 "/dev/${ZAI_BLK}${ZAI_BLK_PP}4"
fi

# Creating backup directory
mkdir $(_v) -p /mnt/zai/backups

# Get pacman to automatically retrieve gpg keys
echo 'auto-key-retrieve' >> /etc/pacman.d/gnupg/gpg.conf 

txt_major "Installing 'bat', 'rsync', and 'fish' for easier scripting..."
pacman -Sy --noconfirm --needed --color always bat fish rsync
########

txt_major "Making sure file permissions are correct..."
find "$ZAI_DIR" -type f | \
grep -iE '(\.bash)|(\.fish)|(\.sh)' | \
xargs chmod +x -c
########

# Just prints time and date information so the user is aware
# of any issues now rather then later
txt_major "Double check that the time & date is correct:"
echo ''; timedatectl; echo ''
pause

# Partition $ZAI_BLOCK
fish "$ZAI_DIR/block/partition.fish"

# Encrypt partitions 2, 3, and 4 on $ZAI_BLOCK
fish "$ZAI_DIR/block/crypt.fish"

# Create various filesystems on $ZAI_BLOCK
fish "$ZAI_DIR/block/format-mount.fish"

# Configure pacman.conf for better bootstrapping performance
fish "$ZAI_DIR/pacman/pre-install.fish"

# If 'pre-install.fish' failed to setup a local repo we need to
# re-export the variable to prevent further issues down the track
if [[ ${ZAI_PKG_LOCALREPO,,} =~ ^true$ ]]; then
	update_exports
fi

# Install a basic environment onto the new partitions to 
# allow for continued configuration once we chroot in
bash "$ZAI_DIR/pacman/pacstrap.bash"

# Generate and copy a 'fstab' into the new root
# This can sometimes mess up but it is a good example
# The user is expected to double check it before rebooting
txt_major "Copying basic 'fstab' config into new root partition..."
genfstab -U /mnt >> /mnt/etc/fstab
bat --paging never --language fstab /mnt/etc/fstab

# Having a functioning tmpfs inside the new root will make compilation
# faster if we are doing that and otherwise has no real drawbacks
#
# It is intentionally created after the fstab to avoid it trying to
# add it to the generated 'fstab' file, instead we will let systemd
# handle automatic creation of the '/tmp' tmpfs after rebooting
txt_major "Mounting a 'tmpfs' on '/mnt/tmp'..."
if mount $(_v) --mkdir -t tmpfs -o 'size=100%' tmpfs /mnt/tmp; then
	txt_base "Successfully mounted a tmpfs on '/mnt/tmp'"
	echo ''
	findmnt --mountpoint /mnt/tmp -o TARGET,FSTYPE,SIZE,OPTIONS | sed -E 's|([a-zA-Z0-9]) |\1     |g'
	echo ''
else
	err_base "Failed to mount a tmpfs on '/mnt/tmp'"
	err_base "This isn't ideal but shouldn't cause any issues"
	err_base "Continuing..."
fi

# Creates a basic 'crypttab'
# You need this if you want the system to auto-unencrypt 
# any partitions not unencrypted in the initramfs
fish "$ZAI_DIR/config/crypttab.fish"

# Adds some very minor tweaks to sudoers
# These are mostly objective (changing the sudo group from 'wheel' -> 'sudo')
# But does include a fix for using the profile-sync-daemon in overlay mode
fish "$ZAI_DIR/sudoers/sudoers.fish"

# Now we mount the local repo, if enabled, into the new root partition
if [[ ${ZAI_PKG_LOCALREPO,,} =~ ^true$ ]]; then
	txt_major "Mounting local repo into chroot..."
	if mount $(_v) --mkdir --bind /repo /mnt/repo; then
		txt_minor "Successfully mounted local repo in chroot"
	else
		err_major "Failed to mount local repo into chroot"
		abort
	fi
fi

# Now we move all the scripts and logs into the new root and redirect future logs into there
txt_major "Copying '$ZAI_DIR' into chroot..."
if rsync -ra "$ZAI_DIR/" '/mnt/zai'; then
	
	# This just stops scripts from saving logs to a 
	# directory we would not be preserving
	old_zai="$ZAI_DIR"
	ZAI_DIR='/mnt/zai' 

	txt_major "Copied '$old_zai' to '/mnt/zai' successfully"
else
	err_major "Failed to copy '$ZAI_DIR' to '/mnt/zai'"
	abort
fi

# Keep our 'pacman.conf' changes so we don't need to do them again
txt_minor "Moving modified livecd 'pacman.conf' into chroot..."
mv $(_v) /mnt/etc/pacman.conf  /mnt/zai/backups/pacman.conf
cp $(_v) /etc/pacman.conf  	/mnt/etc/pacman.conf
pretty_diff "/mnt/zai/backups/pacman.conf" "/mnt/etc/pacman.conf"

# Save settings for chroot
fish "$ZAI_DIR/config/preserve_env.fish"; echo ''

txt_major "If this all looks good, use 'arch-chroot /mnt' and continue installation with '/zai/run-chroot.fish'."
# Done!
