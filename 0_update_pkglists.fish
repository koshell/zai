#!/usr/bin/env fish

# For logging
set _name ( path change-extension '' ( basename ( status filename )))

set -x ZAI_DIR ( path dirname ( status filename ))

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

# Load colour and format variables
source "$ZAI_DIR/source/format.fish"

set pkglist (cat "$ZAI_DIR/pacman/pkglist.txt" | sort | uniq)
echo -e '\n' > "$ZAI_DIR/newlist.txt"

for pkg in $pkglist
    echo -e "###### $pkg\n"  >> "$ZAI_DIR/newlist.txt"
    pacman -Si "$pkg"  >> "$ZAI_DIR/newlist.txt"
    echo '' >> "$ZAI_DIR/newlist.txt"
    pkgfile -b -l $pkg | grep -vE '^repo/' >> "$ZAI_DIR/newlist.txt"
    echo -e '\n#########################################'  >> "$ZAI_DIR/newlist.txt"
end

set pkglist (cat "$ZAI_DIR/pacman/aurlist.txt" | sort | uniq)
echo -e "\nAur..."   >> "$ZAI_DIR/newlist.txt"
echo "#########################################"   >> "$ZAI_DIR/newlist.txt"
for pkg in $pkglist
    echo -e "###### $pkg\n"  >> "$ZAI_DIR/newlist.txt"
    paru -Sia "$pkg"  >> "$ZAI_DIR/newlist.txt"
    #echo '' >> "$ZAI_DIR/newlist.txt"
    #pkgfile -b -l $pkg | grep -vE '^repo/' >> "$ZAI_DIR/newlist.txt"
    echo -e '\n#########################################'  >> "$ZAI_DIR/newlist.txt"
end

