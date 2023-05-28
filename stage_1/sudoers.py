#!/usr/bin/env python3
"""
#TODO
"""

__author__ = "Zaiju"
__version__ = "0.1.0"
__license__ = "GPL3"

from pathlib import Path
from shutil import copyfile

from .common import replace_line

ZAI_DIR = Path(".")
SUDOERS_D = Path("/mnt/etc/sudoers.d").absolute()
SUDOERS = Path("/mnt/etc/sudoers")
POLKIT_D = Path("/etc/polkit-1/rules.d")


def main():
    pass

    drop_in_glob = Path(ZAI_DIR / "sudoers").glob("*.sudoers")
    for drop_in in drop_in_glob:
        # because path is object not string
        copyfile(drop_in.absolute(), SUDOERS_D / drop_in.stem)

    # txt_minor "Removing sudo powers from 'wheel' group..."
    replace_line("%wheel ALL=(ALL:ALL) ALL", "#%wheel ALL=(ALL:ALL) ALL", str(SUDOERS))

    # echo "Updating polkit to use 'sudo' instead of 'wheel'..."
    copyfile(
        Path(ZAI_DIR / "sudoers" / "sudo_polkit.rules"),
        Path(POLKIT_D / "40-default.rules"),
    )
