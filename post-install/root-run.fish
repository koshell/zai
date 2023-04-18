#!/usr/bin/env fish

set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format variables
source "/zai/source/format.fish"

set primary_user "zaiju"
set ZAI_USERS $primary_user # 'second_user' 'sudo_user'
set ZAI_SUDOS $primary_user # 'sudo_user'
set ZAI_BACKUP '/zai/backups'

set _user_groups psd libvirt steam download
set _sudo_groups sudo audit hydrus


txt_major "Formatting 'luks-home'..."
mkdir -p "/{$ZAILOG}/bcachefs"
bcachefs format \
	--discard \
	--label=home \
	--background_compression=lz4 \
	/dev/mapper/luks-home \
	&> "/{$ZAILOG}/bcachefs/home-format.log"

txt_minor "Removing the '/home' directory..."
rm -rfv /home


txt_minor "Recreating '/home' and setting the 'i' flag..."
# This prevents the system from creating files in /home
# if there is every an issue with mounting the partition.
mkdir -v /home
chattr -v +i /home

txt_major "Mounting 'luks-home' on '/home'..."
if not mount.bcachefs /dev/mapper/luks-home /home -o discard
	txt_major "{$txtred}{$txtbold}Failed to mount '/home'{$txtclean}"
	echo "    Check 'dmesg' for what errors were raised."
	echo "    The errors are rarely propogated to userspace."
	echo -e "$major Aborting to avoid read/write issues..."
	return 1
end
txt_major "Succesfully mounted '/home'"

# Add /home mount to fstab

txt_major "Creating normal user groups..."
for _group in $_user_groups
	txt_minor "Creating group '$_group'"
	groupadd $_group &> /dev/null
end

txt_major "Creating sudo user groups..."
for _group in $_sudo_groups
	txt_minor "Creating group '$_group'"
	groupadd $_group &> /dev/null
end

txt_major "Creating user accounts..."
for _user in $ZAI_USERS
	txt_minor "Creating user '$_user'..."
	useradd -mU $_user
end

txt_major "Adding secondary groups to normal users..."
for _user in $ZAI_USERS
	txt_minor "Ading groups to $_user..."
	for _group in $_user_groups
    	groupadd $_group &> /dev/null
		echo "    Appending group '$_group'"
    	usermod --append -G $_group $_user
	end
end

txt_major "Adding secondary groups to super users..."
for _user in $ZAI_SUDOS
	txt_minor "Ading groups to $_user..."
	for _group in $_sudo_groups
    	groupadd $_group &> /dev/null
		echo "    Appending group '$_group'"
    	usermod --append -G $_group $_user
	end
end

echo "Set the password for '$primary_user':"
passwd $primary_user

echo "Moving various backup files to '/root'..."

mkdir -pv /root/zai/backups

mkdir -v /
mv /etc/locale.gen.bak /root/zai/backups/etc/locale.gen

echo "Finished post install steps, don't forget to copy config files over before logging in as '$_user'!"
