#!/usr/bin/env python3
"""
Pre-arch-chroot portion
"""

__author__ = "Zaiju"
__version__ = "0.1.0"
__license__ = "GPL3"

import argparse
import logging
import os
from os import chmod, curdir
from pathlib import Path
from shutil import copyfile
from stat import S_IRUSR
from subprocess import run

import rich

efi_partition = Path()


def main():
    # set drive_path "/dev/$ZAI_BLK"
    # set boot_path (string join '' $drive_path $ZAI_BLK_PP '1')

    # txt_major "Formatting partitions..."
    # txt_minor "Formatting 'boot' partition..."
    run(["mkfs.fat", "-F", "32", "-n", "boot", "$boot_path"])

    # txt_minor "Formatting 'swap' partition..."
    run(["mkswap", "/dev/mapper/luks-swap", "--label", "swap"])

    # txt_minor "Formatting 'root' partition..."
    run(["mkfs.ext4", "-L", "root", "-E", "discard", "/dev/mapper/luks-roots"])

    # txt_major "Finished formatting and mounting the partitions"
    # return
