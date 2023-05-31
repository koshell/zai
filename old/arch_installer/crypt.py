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
import subprocess
from os import curdir
from pathlib import Path
from shutil import copyfile
from subprocess import run
from typing import Dict, List

import rich


def main():
    # The first partition can't be encrypted because
    # it needs to be read by the bootloader
    partitions: List[Path] = list()

    root_partition = Path("")
    # "Starting partition encryption..."

    # "Generating keyfile..."
    keyfile = Path("/crypto_keyfile.bin")

    if keyfile.exists():
        backup_keyfile = Path("/", str(keyfile.stem) + ".bak")
        copyfile(str(keyfile), str(backup_keyfile))
        keyfile.unlink()

    subprocess.run(["openssl", "genrsa", "-out", str(keyfile), "4096"])

    # txt_minor "Encrypting partitions..."
    for partition in partitions:
        subprocess.run(
            ["cryptsetup", "--batch-mode", "luksFormat", str(partition), str(keyfile)]
        )

    # txt_major "Add traditional password for the root partition"

    subprocess.run(
        [
            "cryptsetup",
            f"--key-file={str(keyfile)}",
            "luksAddKey",
            str(root_partition),
        ]
    )

    # txt_minor "Opening 'luks-root' partition..."

    subprocess.run(
        [
            "cryptsetup",
            "--allow-discards",  # TODO Check if discard enabled
            "--batch-mode",
            f"--key-file={str(keyfile)}",
            "open",
            str(root_partition),
            "luks-root",
        ]
    )

    # cryptsetup 	--allow-discards \
    # 		--batch-mode \
    # 		--key-file=/crypto_keyfile.bin \
    # 		open $_par3 luks-root

    # txt_minor "Opening 'luks-swap' partition..."
    # cryptsetup 	--allow-discards \
    # 		--batch-mode \
    # 		--key-file=/crypto_keyfile.bin \
    # 		open $_par2 luks-swap

    # txt_major "Finished encrypting the partitions"
    # return
