#!/usr/bin/env bash
# shellcheck disable=
#
readonly __version__='0.0.1'
readonly __author__='zaiju-code'

# Script root directory
# shellcheck disable=SC2155
export ZAI_DIR="$(dirname -- "$(readlink -f "$0")")"

# For logging
_name="$(_tmp="$(basename "$0")"; echo "${_tmp%.*}")"

# Load config values
# shellcheck source=0_config
source "$ZAI_DIR/0_config"

# Load colour and format functions
# shellcheck source=source/format.bash
source "$ZAI_DIR/source/format.bash"

# Load helper functions
# shellcheck source=source/functions.bash
source "$ZAI_DIR/source/functions.bash"

# Needed to set '_backup_dir' and '_log_dir'
reset_dirs

if [[ ! $ZAI_DIR == '/zai' ]]; then
	clear

	_txtclean; 			echo -en "\nStarting " | tee -a "$(_log)"
	_txtbold; _txtgrn; 	echo "Zaiju's Arch Installer" | tee -a "$(_log)"
	_txtclean; 			echo -e "Version: ${__version__}\n" | tee -a "$(_log)"

	txt_major "Copying scripts to '/zai'..."
	zai_verbose "$( rm -rfv /zai 2>> "$(_err)" )"
	mapfile -t file_list <<< "$(find "$ZAI_DIR" -mindepth 1 -maxdepth 1)"
	zai_verbose "$(	mkdir -pv /zai 2>> "$(_err)" )"
	cp_status=0
	for file in "${file_list[@]}"; do
		if basename "$file" | grep -qvEe '^\.'; then
			zai_verbose "$( cp -avr "$file" '/zai/' 2>> "$(_err)"; cp_status=$(( $cp_status + $? )) )";
		fi
	done
	if [[ $cp_status -eq 0 ]]; then
		export ZAI_DIR='/zai'
		txt_major "Passing execution into '/zai'..."
		# shellcheck disable=SC2093
		exec '/zai/1_run-livecd.bash'
		# If exec succeeded we shouldn't ever run the following command
		err_major "Failed to pass execution into '/zai'"
		abort
	else
		err_major "Copying scripts failed"
		abort
	fi
fi

# Need to update '_backup_dir' and '_log_dir' if we moved $ZAI_DIR
reset_dirs

# VM testing
if [[ ${ZAI_VMDEGUB,,} =~ ^true$ ]]; then
	txt_major "Creating symlinks for testing inside a VM..."
	# shellcheck disable=SC2129
	zai_verbose "$( ln -vs /dev/vda  "/dev/${ZAI_BLK}" 					2>> "$(_err)" )"
	zai_verbose "$( ln -vs /dev/vda1 "/dev/${ZAI_BLK}${ZAI_BLK_PP}1"	2>> "$(_err)" )"
	zai_verbose "$( ln -vs /dev/vda2 "/dev/${ZAI_BLK}${ZAI_BLK_PP}2"	2>> "$(_err)" )"
	zai_verbose "$( ln -vs /dev/vda3 "/dev/${ZAI_BLK}${ZAI_BLK_PP}3"	2>> "$(_err)" )"
	zai_verbose "$( ln -vs /dev/vda4 "/dev/${ZAI_BLK}${ZAI_BLK_PP}4"	2>> "$(_err)" )"
	txt_base "Finished creating symlinks"
fi

# Creating backup directory
zai_verbose "$( mkdir -vp "/mnt/$_backup_dir" 2>> "$(_err)" )"

# Get pacman to automatically retrieve gpg keys
ver_minor "Setting 'pacman' to auto rereieve gpg keys..."
echo 'auto-key-retrieve' >> /etc/pacman.d/gnupg/gpg.conf 

# Installing really useful packages that save us a lot of pain
txt_major "Installing 'bat', 'rsync', and 'fish' for easier scripting..."
zai_verbose "$( pacman -Sy --noconfirm --needed --color always bat fish rsync 2>> "$(_err)" )"

# Sometimes file permissions get messed up during the copy process, this attempts to fix them
txt_major "Making sure file permissions are correct..."
zai_verbose "$( \
	find "$ZAI_DIR" -mindepth 1 -type f | \
	grep -iE '(\.bash)|(\.fish)|(\.sh)' | \
	xargs chmod +x -c 2>> "$(_err)" 	  \
)"

# Just prints time and date information so the user is aware
# of any issues now rather then later
txt_major "Double check that the time & date is correct:"
echo ''		| tee -a "$(_log)"
timedatectl | tee -a "$(_log)" 2>> "$(_err)"
echo '' 	| tee -a "$(_log)"
pause

# Partition '$ZAI_BLOCK'
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
genfstab -U /mnt >> /mnt/etc/fstab 2>> "$(_err)"
cat /mnt/etc/fstab >> "$(_log)" 2>> "$(_err)"
bat --paging never --language fstab /mnt/etc/fstab 2>> "$(_err)"

# Having a functioning tmpfs inside the new root will make compilation
# faster if we are doing that and otherwise has no real drawbacks
#
# It is intentionally created after the fstab to avoid it trying to
# add it to the generated 'fstab' file, instead we will let systemd
# handle automatic creation of the '/tmp' tmpfs after rebooting
txt_major "Mounting a 'tmpfs' on '/mnt/tmp'..."

if zai_verbose "$( mount -v --mkdir -t tmpfs -o 'size=100%' tmpfs /mnt/tmp 2>> "$(_err)" )"; then
	txt_base "Successfully mounted a tmpfs on '/mnt/tmp'"
	echo '' | tee -a "$(_log)"
	# Increases the spacing between columns for nicer reading
	_added_spaces=4
	_spaces=''
	# shellcheck disable=SC2034
	for i in $(seq 1 $(( 1 + _added_spaces ))); do
  		_spaces+=' '
	done
	findmnt --mountpoint /mnt/tmp \
		-o TARGET,FSTYPE,SIZE,OPTIONS | \
		sed -E "s|([[:graph:]]) |\1${_spaces}|g" | \
		tee -a "$(_log)" 2>> "$(_err)"
	echo '' | tee -a "$(_log)"
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
	if zai_verbose "$( mount -v --mkdir --bind /repo /mnt/repo 2>> "$(_err)" )"; then
		txt_minor "Successfully mounted local repo in chroot"
	else
		err_major "Failed to mount local repo into chroot"
		abort
	fi
fi

# Now we recursively move $ZAI_DIR into the new root
txt_major "Copying '$ZAI_DIR' into chroot..."
# If logs are being stored below $ZAI_DIR as is the default then we need to temporarily redirect them elsewhere
# before we update the location of the logs and start writing to them like normal
if rsync -rah --no-motd --stats --inplace --verbose "$ZAI_DIR/" '/mnt/zai' >> /tmp/rsync.log 2>> /tmp/rsync.err ; then
	
	# This just stops scripts from saving logs to a 
	# directory we would not be preserving
	old_zai="$ZAI_DIR"
	export ZAI_DIR='/mnt/zai' 

	# Need to update '_backup_dir' and '_log_dir' if we moved $ZAI_DIR
	reset_dirs

	# Appending our temporarily relocated logs back onto their correct file
	cat /tmp/rsync.err >> "$(_err)" 2>> /dev/null 
	zai_verbose "$( cat /tmp/rsync.log 2>> /dev/null )"

	txt_major "Copied '$old_zai' to '/mnt/zai' successfully"
else
	err_major "Failed to copy '$ZAI_DIR' to '/mnt/zai'"
	abort
fi

# Keep our 'pacman.conf' changes so we don't need to do them again
txt_minor "Moving modified livecd 'pacman.conf' into chroot..."
zai_verbose "$( mkdir -vp "$_backup_dir/etc" 									2>> "$(_err)" )"
zai_verbose "$( mv -vf '/mnt/etc/pacman.conf' "$_backup_dir/etc/pacman.conf"  	2>> "$(_err)" )"
zai_verbose "$( cp -vf '/etc/pacman.conf' 	  '/mnt/etc/pacman.conf' 			2>> "$(_err)" )"
pretty_diff "$_backup_dir/etc/pacman.conf"    "/mnt/etc/pacman.conf"

# Save settings for chroot
fish "$ZAI_DIR/config/preserve_env.fish"; echo ''

txt_major "If this all looks good, use 'arch-chroot /mnt' and continue installation with '/zai/2_run-chroot.fish'"
# Done!
