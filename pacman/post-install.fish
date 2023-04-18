#!/usr/bin/env fish

set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format variables
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

# Set config location
set _conf '/etc/pacman.conf'

txt_major "Applying post-install pacman configuration settings..."


txt_minor "Enabling coloured pacman output..."
if replace_line '#Color' 'Color' $_conf
	txt_base "Successfully enabled coloured pacman output"
else
	err_base "Failed to enable coloured pacman output"
end

txt_minor "Enabling parallel downloads..."
if sed -ir "s|^#ParallelDownloads.*|ParallelDownloads = "$ZAI_PKG_PD"|g" $_conf
	txt_base "Successfully enabled parallel downloads"
else
	err_base "Failed to enable parallel downloads"
end

if string match -rqi '^true$' $ZAI_PKG_MULTILIB
	txt_minor "Enabling [multilib] repo..."
	set _sed_string (string join '' \
		's|'\
		'#\[multilib\]\n' \
		'#Include = /etc/pacman.d/mirrorlist|' \
		'\[multilib\]\n' \
		'Include = /etc/pacman.d/mirrorlist|g')
	sed -zri $_sed_string $_conf; set _sed_exit $status
	if test $_sed_exit -eq 0
		txt_base "Successfully enabled [multilib] repo"
	else
		err_base "Failed to enable [multilib] repo"
		err_base "Is it already enabled?"
	end
end

if string match -rqi '^true$' $ZAI_PKG_POWERPILL
	for repo in core extra community 
		txt_minor "Patching [$repo] repo..."
		set _sed_string (string join '' \
			's|'\
			"\[$repo\]\n" \
			'Include = /etc/pacman.d/mirrorlist' \
			'|' \
			"\[$repo\]\n" \
			'SigLevel = PackageRequired\n' \
			'Include = /etc/pacman.d/mirrorlist' \
			'|g')
		sed -zri $_sed_string $_conf; set _sed_exit $status
		if test $_sed_exit -eq 0
			txt_base "Successfully patched [$repo] repo"
		else
			err_base "Failed to patch [$repo] repo"
		end
	end

	# Patch [multilib] if it is enabled
	if string match -rqi '^true$' $ZAI_PKG_MULTILIB
		txt_minor "Patching [multilib] repo..."
		set _sed_string (string join '' \
			's|'\
			"\[multilib\]\n" \
			'Include = /etc/pacman.d/mirrorlist' \
			'|' \
			"\[multilib\]\n" \
			'SigLevel = PackageRequired\n' \
			'Include = /etc/pacman.d/mirrorlist' \
			'|g')
		sed -zri $_sed_string $_conf; set _sed_exit $status
		if test $_sed_exit -eq 0
			txt_base "Successfully patched [multilib] repo"
		else
			err_base "Failed to patch [multilib] repo"
		end
	end
end

if string match -rqi '^true$' $ZAI_PKG_LOCALREPO
	txt_minor "Enabling local repo..."
	set _sed_string (string join '' \
		's|' \
		'#\[testing\]\n' \
		'#Include = /etc/pacman.d/mirrorlist|' \
		'#\[testing\]\n' \
		'#Include = /etc/pacman.d/mirrorlist\n' \
		'\n' \
		"# Local repo at '/repo'\n" \
		'\[repo\]\n' \
		'SigLevel = Optional TrustAll\n' \
		'Server = file:///repo|g')
	sed -zri "$_sed_string" $_conf; set _sed_exit $status
	if test $_sed_exit -eq 0
		txt_base "Successfully enabled local repo"
	else
		err_base "Failed to enable local repo"
		err_base "Disabling local repo for the rest of the installation"
		set -U ZAI_PKG_LOCALREPO 'false'
	end
end


txt_major "Finished applying post-install pacman configuration settings"
return