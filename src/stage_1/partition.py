#!/usr/bin/env python3
"""
Partitioning
"""

__author__ = "Zaiju"
__version__ = "0.1.0"
__license__ = "GPL3"

from math import floor
import subprocess
from itertools import chain
from pathlib import Path
from subprocess import run
from typing import List, Optional
from enum import Enum
from typing import TYPE_CHECKING


if TYPE_CHECKING:
    from _typeshed import StrPath
    from decimal import Decimal as decimal

Block_Device = Path


class IEC(Enum):
    Byte = 1
    KiB = 1024
    MiB = 1024 * 1024
    GiB = 1024 * 1024 * 1024
    TiB = 1024 * 1024 * 1024 * 1024


class IS(Enum):
    Byte = 1
    KB = 1000
    MB = 1000 * 1000
    GB = 1000 * 1000 * 1000
    TB = 1000 * 1000 * 1000 * 1000


DATA_UNIT = IS | IEC


class Filesystem(Enum):
    Bcachefs = "bcachefs"
    Btrfs = "btrfs"
    Ext4 = "ext4"
    Fat12 = "-F 12"
    Fat16 = "-F 16"
    Fat32 = "-F 32"
    Ntfs = "ntfs"
    Reiser4 = "reiser4"
    Swap = "swap"


class Partition_Table(Enum):
    GPT = "gpt"
    MBR = "msdos"


class Size_Bytes:
    def __init__(
        self,
        size: int | float | decimal,
        unit: IEC | IS = IEC.Byte,
        decimals: int = 2,
    ):
        self.size_in_bytes: int = floor(size * unit.value)
        self.decimals: int = decimals

    def __int__(self) -> int:
        return int(self.size_in_bytes)

    @property
    def b(self) -> int:
        return self.size_in_bytes

    @property
    def kb(self) -> float:
        return round(self.size_in_bytes / IS.KB.value, self.decimals)

    @property
    def kib(self) -> float:
        return round(self.size_in_bytes / IEC.KiB.value, self.decimals)

    @property
    def mb(self) -> float:
        return round(self.size_in_bytes / IS.MB.value, self.decimals)

    @property
    def mib(self) -> float:
        return round(self.size_in_bytes / IEC.MiB.value, self.decimals)

    @property
    def gb(self) -> float:
        return round(self.size_in_bytes / IS.GB.value, self.decimals)

    @property
    def gib(self) -> float:
        return round(self.size_in_bytes / IEC.GiB.value, self.decimals)

    @property
    def tb(self) -> float:
        return round(self.size_in_bytes / IS.TB.value, self.decimals)

    @property
    def tib(self) -> float:
        return round(self.size_in_bytes / IEC.TiB.value, self.decimals)


class Partition:
    def __init__(
        self,
        partition_size: Size_Bytes,
        target_block_device: Block_Device,
        filesystem: Filesystem = Filesystem.Ext4,
        format_args: list[tuple[str]] | None = None,
        mount_args: list[tuple[str]] | None = None,
    ) -> None:
        self.partition_size: Size_Bytes = partition_size
        self.target_block_device: Block_Device = target_block_device
        self.filesystem: Filesystem = filesystem
        self.format_args: list[tuple[str]] | None = format_args
        self.mount_args: list[tuple[str]] | None = mount_args


class Partition_Controller:
    def __init__(
        self,
        boot_partition: Partition,
        root_partition: Partition,
        secondary_partitions: List[Partition],
        scheme: Partition_Table = Partition_Table.GPT,
        unit: DATA_UNIT = IEC.Byte,
    ) -> None:
        self.partition_scheme: Partition_Table = scheme

        self.__partitions.append(
            {"start": "0%", "end": f"{( first_partition * unit ) + MB}B"}
        )

        return

    @staticmethod
    def get_block_device_size(block_device: Block_Device) -> Size_Bytes:
        size_cmd = run(
            ["blockdev", "--getsize64", str(block_device)], capture_output=True
        )
        return Size_Bytes(int(size_cmd.stdout.decode().strip()), IEC.Byte)

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
                partitions.append(["mkpart", "none", part["start"], part["end"]])
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
