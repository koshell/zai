#!/usr/bin/env fish

set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format functions
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

txt_major "Configuring sudoers..."



txt_minor "Removing sudo powers from 'wheel' group..."
cp (_v) '/mnt/etc/sudoers' "$ZAI_DIR/backups/etc/sudoers" | tee -a "$(_log)"
sed -i 's/%wheel ALL=(ALL:ALL) ALL/#%wheel ALL=(ALL:ALL) ALL/g' /mnt/etc/sudoers
pretty_diff  "$ZAI_DIR/backups/etc/sudoers" /mnt/etc/sudoers

txt_minor "Installing drop-in sudoers files..."
mkdir -p (_v) /mnt/etc/sudoers.d

for i in (find "$ZAI_DIR/sudoers" -mindepth 1 -maxdepth 1 -type f | grep -iE '^.*\.sudoers$')
    cp (_v) "$i" /mnt/etc/sudoers.d/ | tee -a "$(_log)"
    if test $pipestatus[1] -eq 0
        ver_base "Successfully copied '$i'"
    else
        err_minor "Failed to copy '$i'"
        err_base "A partially configured 'sudoers' is very dangerous"
        abort
    end
end

txt_minor "Removing extensions from the drop-in sudoers files so they will be processed correctly..."
path change-extension '' /mnt/etc/sudoers.d/*.sudoers

echo "Updating polkit to use 'sudo' instead of 'wheel'..."
set _polkit_dropin (string join '' \
    'polkit.addAdminRule(function(action, subject) {\n' \
    '    return ["unix-group:sudo"];\n' \
    '});')
mkdir -p /etc/polkit-1/rules.d
if echo -e $_polkit_dropin > /etc/polkit-1/rules.d/40-default.rules
    txt_minor "Updated polkit successfully"
    bat --paging never /etc/polkit-1/rules.d/40-default.rules
else
    err_minor "Failed to update polkit"
    if string match -rqi '^true$' $ZAI_IGNOREFAIL
        err_base "Continuing anyway..."
    else
        err_base "Aborting..."
        exit 1
    end
end
txt_major "Finished configuring sudoers"
return