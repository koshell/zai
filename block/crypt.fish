#!/usr/bin/env fish

# For logging
set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format variables
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

# The first partition can't be encrypted because
# it needs to be read by the bootloader
set _par2 (string join '' "/dev/$ZAI_BLK" $ZAI_BLK_PP "2")  
set _par3 (string join '' "/dev/$ZAI_BLK" $ZAI_BLK_PP "3") 
set _par4 (string join '' "/dev/$ZAI_BLK" $ZAI_BLK_PP "4") 

txt_major "Starting partition encryption..."

txt_minor "Generating keyfile..."
rm -f /crypto_keyfile.bin &> /dev/null
openssl genrsa -out /crypto_keyfile.bin 4096

txt_minor "Encrypting partitions..."
cryptsetup --batch-mode luksFormat $_par2 /crypto_keyfile.bin
cryptsetup --batch-mode luksFormat $_par3 /crypto_keyfile.bin
cryptsetup --batch-mode luksFormat $_par4 /crypto_keyfile.bin

txt_major "Add traditional password for the root partition"
cryptsetup --key-file=/crypto_keyfile.bin luksAddKey $_par3

txt_major "Add traditional password for the swap partition"
cryptsetup --key-file=/crypto_keyfile.bin luksAddKey $_par2

txt_minor "Opening 'luks-swap' partition..."
cryptsetup 	--allow-discards \
		--batch-mode \
		--key-file=/crypto_keyfile.bin \
		open $_par2 luks-swap

txt_minor "Opening 'luks-root' partition..."
cryptsetup 	--allow-discards \
		--batch-mode \
		--key-file=/crypto_keyfile.bin \
		open $_par3 luks-root

txt_major "Finished encrypting the partitions"
return
