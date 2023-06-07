#!/usr/bin/env fish

# For logging
set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format variables
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

set drive_path "/dev/$ZAI_BLK"
set boot_path (string join '' $drive_path $ZAI_BLK_PP '1')

txt_major "Formatting partitions..."
txt_minor "Formatting 'boot' partition..."
mkfs.fat -F 32 -n boot $boot_path
txt_minor "Formatting 'swap' partition..."
mkswap /dev/mapper/luks-swap --label swap
txt_minor "Formatting 'root' partition..."
mkfs.ext4 -L root -E discard /dev/mapper/luks-root 

txt_major "Mounting partitions..."
txt_minor "Mounting swap partition..."
swapon -v --discard /dev/mapper/luks-swap
txt_minor "Mounting root partition..."
mount -v -t ext4 -o discard /dev/mapper/luks-root /mnt
txt_minor "Mounting boot partition..."
mount -v --mkdir -o discard $boot_path /mnt/boot

txt_major "Copying keyfile into root partition..."
cp -v /crypto_keyfile.bin /mnt/crypto_keyfile.bin
txt_minor "Updating keyfile permissions..."
chmod u=r,g=,o= -c /mnt/crypto_keyfile.bin
txt_major "Finished formatting and mounting the partitions"
return
