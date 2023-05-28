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

KEYFILE = Path("/crypto_keyfile.bin")


def main(partitions: List[Path], root_partition: Path):
    # The first partition can't be encrypted because
    # it needs to be read by the bootloader

    # "Starting partition encryption..."

    # "Generating keyfile..."

    # backup exisiting keyfile if it exists
    if KEYFILE.exists():
        backup_keyfile = Path("/", str(KEYFILE.stem) + ".bak")
        copyfile(str(KEYFILE), str(backup_keyfile))
        KEYFILE.unlink()

    subprocess.run(["openssl", "genrsa", "-out", str(KEYFILE), "4096"])

    # txt_minor "Encrypting partitions..."
    for partition in partitions:
        subprocess.run(
            ["cryptsetup", "--batch-mode", "luksFormat", str(partition), str(KEYFILE)]
        )

    # txt_major "Add traditional password for the root partition"
    subprocess.run(
        [
            "cryptsetup",
            f"--key-file={str(KEYFILE)}",
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
            f"--key-file={str(KEYFILE)}",
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
