#!/usr/bin/env fish

set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format functions
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

txt_major "Agressivly cleaning up any orphaned packages..."

txt_major "Searching for typical orphans..."
set _orphans (pacman -Qttdq)
if test -z $_orphans || echo $_orphans | grep -Eq 'there is nothing to do' -
    txt_minor "No standard orphans found"

else
    echo "$_orphans" >> /root/orphan.list
    txt_major "Attempting to remove orphans in bulk..."
    if pacman -Rns --noconfirm --color always $_orphans
        txt_minor "Bulk removal was succesful"

    else
        err_minor "Bulk removal failed, starting individual removal..."
        for i in $_orphans
            echo '============'
            txt_minor "Removing '$i'..."
            pacman -Rns --noconfirm --color always $i || err_base "Failed to remove '$i'" | tee -a /root/orphan.log
        end
        echo '============'
    end
end

echo
txt_major "Searching for unneeded or circular orphans..."
set _orphans (pacman -Qqd | pacman -Rsu --print --print-format %n -)
if test -z $_orphans || echo $_orphans | grep -Eq 'there is nothing to do' -
    txt_minor "No unneeded or circular orphans found"

else
    echo "$_orphans" >> /root/orphan.list
    txt_major "Attempting to remove unneeded or circular orphans in bulk..."
    if pacman -Rns --noconfirm --color always $_orphans
        txt_minor "Bulk removal was succesful, continuing..."
    else
        err_minor "Bulk removal failed, starting individual removal..."
        for i in $_orphans
            echo '============'
            txt_minor "Removing '$i'..."
            pacman -Rns --noconfirm --color always $i || err_base "Failed to remove '$i'" | tee -a /root/orphan.log
        end
        echo '============'
    end
end
sort /root/orphan.list | bat --paging never --file-name '/root/orphan.list' 2>/dev/null
sleep 1
txt_major "Finished removing orphans."
return