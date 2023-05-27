#!/usr/bin/env bash
# shellcheck disable=SC2155

_name="$(_tmp="$(basename "$0")"; echo "${_tmp%.*}")"

# Load colour and format variables
# shellcheck source=../source/format.bash
source "$ZAI_DIR/source/format.bash"

# Load helper functions
# shellcheck source=../source/functions.bash
source "$ZAI_DIR/source/functions.bash"

readonly _root="/dev/${ZAI_BLK}${ZAI_BLK_PP}3"
readonly _root_uuid="$(blkid -s UUID -o value "$_root")"

readonly _swap="/dev/${ZAI_BLK}${ZAI_BLK_PP}2"
readonly _swap_uuid="$(blkid -s UUID -o value "$_swap")"

txt_major "Installing 'limine' bootloader..."

txt_minor "Copying 'BOOTX64.EFI'..."
mkdir -vp /boot/EFI/BOOT
cp -v /usr/share/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI

txt_minor "Copying pacman hook..."
mkdir -vp /etc/pacman.d/hooks
cp -v "$ZAI_DIR/limine/limine-deploy.hook" /etc/pacman.d/hooks/limine-deploy.hook

txt_minor "Copying 'limine.cfg'..."
cp -v "$ZAI_DIR/limine/limine.cfg" /boot/limine.cfg

txt_minor "Updating 'limine.cfg' with UUID of '$_root'..."
echo "    CMDLINE=rd.luks.name=$_root_uuid=luks-root rd.luks.options=$_root_uuid=discard root=/dev/mapper/luks-root rw rd.luks.name=$_swap_uuid=luks-swap rd.luks.options=$_swap_uuid=discard resume=/dev/mapper/luks-swap rootflags=discard loglevel=3" >> /boot/limine.cfg

bat --paging never /boot/limine.cfg

txt_major "Finished installing the 'limine' bootloader."
