#!/usr/bin/env python3
"""
Partitioning
"""

__author__ = "Zaiju"
__version__ = "0.1.0"
__license__ = "GPL3"

import subprocess
from pathlib import Path
from re import sub

BYTE = 1
KB = 1024 * BYTE
MB = 1024 * KB
GB = 1024 * MB

GPT = "gpt"
MBR = "msdos"


class Partition_Manager:
    def __init__(self, device: str | Path, partition_table: str = GPT) -> None:
        if partition_table not in [GPT, MBR]:
            raise ValueError(f"Expected '{GPT}' or '{MBR}' but got '{partition_table}'")
        self._partition_table: str = partition_table

        if not Path(device).exists():
            raise Exception()

        self._device: str = str(Path(device).absolute())

    def write_to_disk(self):
        subprocess.run(
            [
                "parted",
                *[
                    "--script",
                    "--fix",
                    "--align=optimal",
                ],
                self._device,
                *[
                    "mklabel",
                    self._partition_table,
                ],
                *["mkpart", "none", "0%", "1025MiB"],
                *["mkpart", "none", "1025MiB", "33793MiB"],
                *["mkpart", "none", "33793MiB", "164865MiB"],
                *["mkpart", "none", "164865MiB", "100%"],
            ]
        )

    subprocess.run(["parted", "/dev/$ZAI_BLK", "unit", "GiB", "print"])
