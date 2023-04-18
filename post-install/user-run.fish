#!/usr/bin/env fish

set _name ( path change-extension '' ( basename ( status filename )))

# Load colour and format variables
source "/zai/source/format.fish"

echo "Enabling some important userspace services..."
systemctl --user enable modprobed-db
systemctl --user enable gamemoded
systemctl --user enable gpg-agent
set -U BORG_REPO /srv/borg
echo "Done!"
