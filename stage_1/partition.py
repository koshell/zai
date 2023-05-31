#!/usr/bin/env python3
"""
Partitioning
"""

__author__ = "Zaiju"
__version__ = "0.1.0"
__license__ = "GPL3"

import subprocess
from itertools import chain
from pathlib import Path
from subprocess import run
from typing import Dict, List, Optional

from ..common.types import StrPath

BYTE = 1
KB = 1024 * BYTE
MB = 1024 * KB
GB = 1024 * MB
TB = 1024 * GB

BYTE_STR = ['b','byte']
KB_STR = ['kb','kib']
MB_STR = ['mb','mib']
GB_STR = ['gb','gib']
TB_STR = ['tb','tib']


GPT = "gpt"
MBR = "msdos"


class DataSize:
    def __init__(
        self,
        size_bytes: Optional[int] = None,
        *,
        size_kibibytes: Optional[int] = None,
        size_mebibytes: Optional[int] = None,
        size_gibibytes: Optional[int] = None,
        size_tebibytes: Optional[int] = None,
    ):
        if size_bytes is None:
            if size_kibibytes is None:
                if size_mebibytes is None:
                    if size_gibibytes is None:
                        if size_tebibytes is None:
                            raise ValueError(
                                "No size passed to DataSize class")
                        else:
                            self.__size: int = int(size_tebibytes * TB)
                    else:
                        self.__size: int = int(size_gibibytes * GB)
                else:
                    self.__size: int = int(size_mebibytes * MB)
            else:
                self.__size: int = int(size_kibibytes * KB)
        else:
            self.__size: int = int(size_bytes * BYTE)

        return

    @property
    def b(self) -> int:
        return self.__size

    @property
    def kb(self) -> float:
        return round(self.__size / KB, 3)

    @property
    def mb(self) -> float:
        return round(self.__size / MB, 3)

    @property
    def gb(self) -> float:
        return round(self.__size / GB, 3)

    @property
    def tb(self) -> float:
        return round(self.__size / TB, 3)


class Partition_Controller:
    def __init__(
        self,
        device: StrPath,
        partitions: List[int],
        partition_table: str = GPT,
        unit: int = BYTE,
    ) -> None:
        if partition_table not in [GPT, MBR]:
            raise ValueError(
                f"Expected '{GPT}' or '{MBR}' but got '{partition_table}'")
        self.partition_table: str = partition_table

        if not Path(device).exists():
            raise Exception()

        self.__device: str = str(Path(device).absolute())

        cmd = run(["blockdev", "--getsize64", self.__device],
                  capture_output=True)
        cmd.stdout.decode()

        self.__device_size: DataSize = DataSize(
            int(cmd.stdout.decode().strip()))

        self.__partitions = list()
        first_partition = partitions.pop(0)
        # Offset the first partition by 1 MiB
        self.__partitions.append(
            {"start": "0%", "end": f"{( first_partition * unit ) + MB}B"}
        )

        for partition in partitions:
            self.add_partition(partition)

        return

    def add_partition(self, size: int, unit: int = BYTE) -> None:
        if (self.__partitions[-1]["end"] + size) > self.__device_size.b:
            raise ValueError(
                "Partition spans from "
                + f"{rount(self.__partitions[-1]['end'] / MB,0)} -> {round((self.__partitions[-1]['end'] + size) / MB,0)}MiB"
                + f" but device size is {self.__device_size.mb}"
            )

        self.__partitions.append(
            {
                "start": f"{self.__partitions[-1]['end']}B",
                "end": f"{self.__partitions[-1]['end'] + (size * unit)}B",
            }
        )
        return

    def write_to_disk(self, end_percentage: Optional[int] = None):
        # God this whole function is a hack
        if end_percentage is not None:
            self.__partitions[-1]["end"] = f"{end_percentage}%"

        partitions: list = list()
        while True:
            try:
                part: dict = self.__partitions.pop(0)
                partitions.append(
                    ["mkpart", "none", part["start"], part["end"]])
            except IndexError:
                break

        cmd = subprocess.run(
            [
                "parted",
                *[
                    "--script",
                    "--fix",
                    "--align=optimal",
                ],
                self.__device,
                *[
                    "mklabel",
                    self.partition_table,
                ],
                *list(
                    # Unfolds the nested list of lists into the main list
                    chain.from_iterable(partitions)
                ),
            ],
            capture_output=True,
            check=True,
        )

        subprocess.run(["parted", self.__device, "unit", "GiB", "print"])

        return cmd
