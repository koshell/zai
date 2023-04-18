#!/usr/bin/env fish

# For logging
set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format variables
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

set _swap (string join '' "/dev/$ZAI_BLK" $ZAI_BLK_PP '2')
set _swap_uuid (blkid -s UUID -o value $_swap)

set _home (string join '' "/dev/$ZAI_BLK" $ZAI_BLK_PP '4')
set _home_uuid (blkid -s UUID -o value $_home)

txt_major "Configuring '/etc/crypttab'..."

echo '' >> /mnt/etc/crypttab # Add a blank line
echo "luks-swap UUID=$_swap_uuid /crypto_keyfile.bin discard" >> /mnt/etc/crypttab
echo "luks-home UUID=$_home_uuid /crypto_keyfile.bin discard" >> /mnt/etc/crypttab

bat --paging never --language crypttab /mnt/etc/crypttab

txt_major "Finished configuring '/etc/crypttab'."
return