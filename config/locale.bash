#!/usr/bin/env bash
# shellcheck disable=SC2155

_name='locale-conf'

# Load colour and format variables
# shellcheck source=../source/format.bash
source "${ZAI_DIR}/source/format.bash"

# Load helper functions
# shellcheck source=../source/functions.bash
source "${ZAI_DIR}/source/functions.bash"

txt_major "Setting the locale..."

txt_minor "Backing up original 'locale.gen'..."
cp -v /etc/locale.gen /etc/locale.gen.bak

txt_minor "Enabling 'en_AU.UTF-8', 'en_US.UTF-8', and 'ja_JP.UTF-8'..."
sed -i 's/#en_AU.UTF-8 UTF-8/en_AU.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
sed -i 's/#ja_JP.UTF-8 UTF-8/ja_JP.UTF-8 UTF-8/g' /etc/locale.gen

diff -u /etc/locale.gen.bak /etc/locale.gen --minimal | \
tee -a /root/locale-sed.log | \
bat --language diff --paging never --file-name 'locale.gen.bak -> locale.gen' -

txt_minor "Generating locale..."
locale-gen | tee -a /root/locale-gen.log 
txt_major "Finished setting the locale"