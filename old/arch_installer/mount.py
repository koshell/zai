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
    # txt_major "Mounting partitions..."
    # txt_minor "Mounting root partition..."
    run(["mount", "-v", "-t", "ext4", "-o", "discard", "/dev/mapper/luks-root", "/mnt"])

    # txt_minor "Mounting swap partition..."
    run(["swapon", "-v", "--discard", "/dev/mapper/luks-swap"])

    # txt_minor "Mounting boot partition..."
    run(["mount", "-v", "--mkdir", "-o", "discard", "$boot_path", "/mnt/boot"])

    # txt_major "Copying keyfile into root partition..."
    copyfile("/crypto_keyfile.bin", "/mnt/crypto_keyfile.bin")

    # txt_minor "Updating keyfile permissions..."
    chmod("/mnt/crypto_keyfile.bin", S_IRUSR)

    # txt_major "Finished formatting and mounting the partitions"
    # return
