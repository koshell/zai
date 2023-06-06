#!/usr/bin/env fish

set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format functions
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

# Update '_backup_dir' and '_log_dir'
reset_dirs

txt_major "Configuring 'sudoers'..."

txt_minor "Installing drop-in sudoers files..."
mkdir -pv /mnt/etc/sudoers.d >> "$(_log)" 2>> "$(_err)"

for i in (find "$ZAI_DIR/sudoers" -mindepth 1 -maxdepth 1 -type f | grep -iE '^.*\.sudoers$')
    cp -vf "$i" /mnt/etc/sudoers.d/ 2>> "$(_err)" | tee -a "$(_log)"
    if test $pipestatus[1] -eq 0
        ver_base "Successfully copied '$i'"
    else
        err_minor "Failed to copy '$i'"
        err_base "A partially configured 'sudoers' is very dangerous"
        abort
    end
end

if string match -rqi '^true$' $ZAI_DISABLE_WHEEL
    txt_minor "Removing sudo powers from 'wheel' group..."
    cp -vf '/mnt/etc/sudoers' "$ZAI_DIR/backups/etc/sudoers" 2>> "$(_err)" | tee -a "$(_log)"
    sed -i 's/%wheel ALL=(ALL:ALL) ALL/#%wheel ALL=(ALL:ALL) ALL/g' /mnt/etc/sudoers
    pretty_diff  "$ZAI_DIR/backups/etc/sudoers" /mnt/etc/sudoers

    echo "Updating polkit to use 'sudo' instead of 'wheel'..."
    mkdir -vp /etc/polkit-1/rules.d >> "$(_log)" 2>> "$(_err)"
    if cp -vf "$ZAI_DIR/sudoers/sudo_polkit.rules" /etc/polkit-1/rules.d/40-default.rules >> "$(_log)" 2>> "$(_err)"
        txt_minor "Updated polkit successfully"
        bat --paging never /etc/polkit-1/rules.d/40-default.rules
    else
        err_minor "Failed to update polkit"
        abort
    end
else
    ver_minor "Removing 'sudo' group drop-in file as it is disabled in config..."
    rm -vf /mnt/etc/sudoers.d/10_sudo.sudoers 2>> "$(_err)" | tee -a "$(_log)"
    if test $pipestatus[1] -eq 0
        ver_base "Successfully removed '$i'"
    else
        err_minor "Failed to remove '$i'"
        err_base "$( string join '' \
            'This is unlikely to break installation ' \
            'but you should remove the file ' \
            'manually once installation is complete' )"
    end
end

txt_minor "Removing extensions from the drop-in sudoers files so they will be processed correctly..."
ver_base "God 'sudoers' syntax is fucked..."
path change-extension '' /mnt/etc/sudoers.d/*.sudoers

txt_major "Finished configuring 'sudoers'"
return