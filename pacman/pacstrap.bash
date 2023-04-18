#!/usr/bin/env bash

_name='pacstrap'

# Load colour and format functions
# shellcheck source=../source/format.bash
source "$ZAI_DIR/source/format.bash"

# Load helper functions
# shellcheck source=../source/functions.bash
source "$ZAI_DIR/source/functions.bash"

txt_major "Installing essential packages..."
if [[ ${ZAI_PKG_LOCALREPO,,} =~ ^true$ ]]; then
	pacstrap -K /mnt \
		base \
		base-devel \
		linux-pure-bcachefs-git \
		linux-pure-bcachefs-git-docs \
		linux-pure-bcachefs-git-headers \
		linux-firmware \
		fish \
		paru \
		limine \
		diffutils \
		nano \
		bat \
		rsync | tee -a "$(_log)"
else
	pacstrap -K /mnt \
		base \
		linux \
		linux-headers \
		base-devel \
		fish \
		diffutils \
		nano \
		bat \
		rsync | tee -a "$(_log)"
fi
txt_major "Finished installing essential packages"
