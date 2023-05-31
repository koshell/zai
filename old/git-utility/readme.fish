#!/usr/bin/env fish

set -x ZAI_DIR  ( path dirname  ( path dirname ( status filename )))

# Load colour and format variables
source "$ZAI_DIR/source/format.fish"

# Load helper functions
source "$ZAI_DIR/source/functions.fish"

set file_list (find . -mindepth 1 -type f | \
    grep -E '(\.bash$)|(\.fish$)|(\.sh$)')

set total_lines (cat $file_list | \
    grep -vxE '([[:blank:]]*#.*)|([[:blank:]]*)' | \
    wc -l)

replace_line "a total of [[:digit:]]* lines" \
    "a total of $total_lines lines" \
    "$ZAI_DIR/README.md"
