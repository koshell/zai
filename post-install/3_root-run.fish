#!/usr/bin/env fish

set _name ( path change-extension '' ( basename ( status filename )))

set -x ZAI_DIR '/zai'

# Load config values
source "$ZAI_DIR/post-install-env"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

# Load colour and format variables
source "$ZAI_DIR/source/format.fish"

reset_dirs

txt_major "Formatting 'luks-home'..."
zai_verbose "$( \
	bcachefs format \
		--discard \
		--label=home \
		--background_compression=lz4 \
		/dev/mapper/luks-home )"

txt_minor "Removing the '/home' directory..."
zai_verbose "$( rm -rfv /home )"

txt_minor "Recreating '/home' and setting the 'i' flag..."
# This prevents the system from creating files in /home
# if there is every an issue with mounting the partition.
zai_verbose "$( mkdir -v /home )"
zai_verbose "$( chattr -v +i /home )"

txt_major "Mounting 'luks-home' on '/home'..."
if not zai_verbose "$( mount.bcachefs -v /dev/mapper/luks-home /home -o discard )"
	err_major "Failed to mount '/home'"
	err_base "    Check 'dmesg' for what errors were raised."
	err_base "    The errors are rarely propogated to userspace."
	err_minor "Aborting to avoid read/write issues..."
	exit 1
end
txt_minor "Succesfully mounted '/home'"
ver_base "Backing up original '/etc/fstab'..."
zai_verbose "$( mkdir -pv  )"
zai_verbose "$( cp -fv /etc/fstab "$_backup_dir/etc/fstab" )"
txt_major "Updating '/etc/fstab'..."
set -l _fstab_string ( string join ' ' \
	"UUID=$( string trim $( blkid -s UUID -o value /dev/mapper/luks-home ) )" \
	'/home' \
	'bcachefs'	\
	'defaults,relatime' \
	'0' \
	'2' )
echo -e "\n# /dev/mapper/luks-home"	| tee -a '/etc/fstab' >> (_log)
echo "$_fstab_string"				| tee -a '/etc/fstab' >> (_log)

pretty_diff "$_backup_dir/etc/fstab" "/etc/fstab"

# The following involves us building a regex with the sudo groups and trying
# to inverse match it against the user groups. The goal is to potentially
# catch and fix any issues of a sudo only group accidentally being assigned
# to normal users
ver_minor "Doing some sanity checking of the user groups to be added..."

# Building list of sudo groups
set sudo_groups ''
if not string match -rqi '^true$' $ZAI_SUDO_DISABLE_WHEEL 
	set -a sudo_groups 'wheel'
end
if test -n $ZAI_SUDO_ADD_GROUP
	set -a sudo_groups "$( string lower $( string trim $ZAI_SUDO_ADD_GROUP ))"
end
for _group in $ZAI_USERS_GROUPS_SUDOS
	set -a sudo_groups "$( string lower $( string trim $_group ))"
end

# Format the regex expression 
set sudo_regex "($( string join ')|(' $_sudo_group_regex ))"

set sanitised_groups ''
for group in $ZAI_USERS_GROUPS 
	if echo $group | grep -iqvwE "$sudo_regex"
		set -a sanitised_groups "$group"
	else
		err_minor "The group '$group' appears to be assigned to super users AND normal users"
		err_base "That could be a dangerous mistake to overlook so we will not assign it to normal users"
	end
end

txt_major "Creating normal user groups..."
for group in $sanitised_groups
	txt_minor "Creating group '$group'"
	zai_verbose "$( groupadd -f $group 2>> $(_err) )"
end

txt_major "Creating super user groups..."
for group in $sudo_groups
	txt_minor "Creating group '$group'"
	zai_verbose "$( groupadd -f $group 2>> $(_err) )" 
end

txt_major "Creating human user accounts..."
for user in $ZAI_USERS
	txt_minor "Creating user '$user'..."
	zai_verbose "$( useradd --create-home --user-group $user 2>> $(_err) )"
end

txt_major "Adding secondary groups to users..."
for user in $ZAI_USERS
	txt_minor "Adding groups to '$user'..."
	for group in $sanitised_groups
		ver_base "Appending group '$group' to '$user'..."
    	zai_verbose "$( usermod -aG $group $user 2>> $(_err) )" 
	end
end

txt_major "Adding secondary groups to super users..."
for user in $ZAI_SUDOS
	txt_minor "Adding groups to '$user'..."
	for group in $sudo_groups
		ver_base "Appending group '$group' to '$user'..."
    	zai_verbose "$( usermod -aG $group $user 2>> $(_err) )" 
	end
end

txt_major "Set the password for '$ZAI_USERS_ADMIN'"
passwd $ZAI_USERS_ADMIN

txt_major "Finished post-install steps!"
ver_minor "Don't forget to copy any config files you want into your \$HOME before logging in as '$ZAI_USERS_ADMIN'"
