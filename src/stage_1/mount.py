#!/usr/bin/env python3
"""
Pre-arch-chroot portion
"""

__author__ = "Zaiju"
__version__ = "0.1.0"
__license__ = "GPL3"

from pathlib import Path
from shutil import copyfile
from stat import S_IRUSR
from subprocess import run
from enum import Enum

efi_partition: Path


class partition_type(Enum):
    ext4 = "ext4"
    bcachefs = "bcachefs"


def mount(
    partition: Path, target: Path, format_type: partition_type | None
) -> Exception | None:
    try:
        # txt_major "Mounting partitions..."
        # txt_minor "Mounting root partition..."
        run(
            [
                "mount",
                "-v",
                "-t",
                "ext4",
                "-o",
                "discard",
                "/dev/mapper/luks-root",
                "/mnt",
            ],
            check=True,
        )

        # txt_minor "Mounting swap partition..."
        run(["swapon", "-v", "--discard", "/dev/mapper/luks-swap"], check=True)

        # txt_minor "Mounting boot partition..."
        run(
            ["mount", "-v", "--mkdir", "-o", "discard", "$boot_path", "/mnt/boot"],
            check=True,
        )

        # txt_major "Copying keyfile into root partition..."
        copyfile("/crypto_keyfile.bin", "/mnt/crypto_keyfile.bin")

        # txt_minor "Updating keyfile permissions..."
        Path("/mnt/crypto_keyfile.bin").chmod(S_IRUSR)

        # txt_major "Finished formatting and mounting the partitions"
        return
    except Exception as e:
        return e
