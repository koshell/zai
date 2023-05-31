#!/usr/bin/env bash
# shellcheck disable=SC2155

_name="$(_tmp="$(basename "$0")"; echo "${_tmp%.*}")"

# Load colour and format variables
# shellcheck source=../source/format.bash
source "${ZAI_DIR}/source/format.bash"

# Load helper functions
# shellcheck source=../source/functions.bash
source "${ZAI_DIR}/source/functions.bash"

txt_major "Setting the locale..."

ver_base "Backing up original 'locale.gen'..."
cp -v /etc/locale.gen "$ZAI_DIR/backups/etc/locale.gen" >> "$(_log)"

for locale in "${ZAI_LOCALE[@]}"; do

	# It's easy to accidentally leave trailing or leading whitespace 
	# that confuses sed, this quickly strips that whitespace
	locale="$(echo "$locale" | awk '{$1=$1;print}')"
	txt_minor "Enabling '$locale'..."
	if replace_line "#${locale}" "${locale}" "/etc/locale.gen"; then
		txt_base "Successfully enabled '$locale'"
	else
		err_base "Failed to enable '$locale'"
	fi
done

diff -u "${ZAI_DIR}/backups/etc/locale.gen" /etc/locale.gen --minimal >> "$(_log)"
pretty_diff "${ZAI_DIR}/backups/etc/locale.gen" /etc/locale.gen

txt_minor "Generating locale..."
locale-gen | tee -a "$(_log)"
txt_major "Finished setting the locale"
