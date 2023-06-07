#!/usr/bin/env bash

_name="$(_tmp="$(basename "$0")"; echo "${_tmp%.*}")"

# Load colour and format functions
# shellcheck source=../source/format.bash
source "$ZAI_DIR/source/format.bash"

# Load helper functions
# shellcheck source=../source/functions.bash
source "$ZAI_DIR/source/functions.bash"

# Main difference between the $ZAI_PKG_LOCALREPO
# version vs otherwise is we bootstrap paru
txt_major "Installing essential packages..."
if [[ ${ZAI_PKG_LOCALREPO,,} =~ ^true$ ]]; then
	pacstrap -K /mnt \
		base \
		base-devel \
		fish \
		paru \
		diffutils \
		nano \
		bat \
		rsync | tee -a "$(_log)"
else
	pacstrap -K /mnt \
		base \
		base-devel \
		fish \
		diffutils \
		nano \
		bat \
		rsync | tee -a "$(_log)"
fi
txt_major "Finished installing essential packages"
