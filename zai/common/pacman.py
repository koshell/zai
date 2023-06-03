#!/usr/bin/env python3
"""
Pacman handler
"""

__author__ = "Zaiju"
__version__ = "0.1.0"
__license__ = "GPL3"

import pathlib
import re
import subprocess
from io import TextIOWrapper
from pathlib import Path
from subprocess import run
from typing import List, Optional, Set

from .functions import replace_line
from .types import RichConsole, StrPath

parallel_downloads: int = 5
multilib: bool = True
powerpill_patch: bool = True
local_repo: bool = True


class Pacman:
    def __init__(
        self,
        pacman_conf_path: StrPath,
        parallel_downloads: int = 6,
        enable_multilib: bool = True,
        enable_powerpill_patch: bool = True,
        enable_local_repo: bool = True,
    ) -> None:
        self.pacman_conf = Path(pacman_conf_path)
        self.parallel_downloads: int = parallel_downloads
        self.enable_multilib: bool = enable_multilib
        self.enable_powerpill_patch: bool = enable_powerpill_patch
        self.enable_local_repo: bool = enable_local_repo

    @staticmethod
    def gpg_tweaks() -> int:
        gpg_conf_path = Path("/etc/pacman.d/gnupg/gpg.conf")
        response: int
        with open(
            gpg_conf_path,
            "a",
        ) as gpg_conf:
            response = gpg_conf.write("auto-key-retrieve")
        return response

    @staticmethod
    def install(
        *packages: str,
        colour: bool = True,
        download_timeout: bool = False,
    ):
        opts = [
            "--sync",  # -S
            "--noconfirm",
            "--needed",
        ]

        if colour:
            opts.append("--color=always")
        else:
            opts.append("--color=never")

        if not download_timeout:
            opts.append("--disable-download-timeout")

        return subprocess.run(
            [
                "/bin/pacman",
                *opts,
                *packages,
            ]
        )

    @staticmethod
    def refresh(
        colour: bool = True,
        download_timeout: bool = False,
    ):
        opts = [
            "--sync",  # -S
            "--refresh",  # -y
            "--noconfirm",
        ]

        if colour:
            opts.append("--color always")
        else:
            opts.append("--color never")

        if not download_timeout:
            opts.append("--disable-download-timeout")
        return subprocess.run(
            [
                "/bin/pacman",
                *opts,
            ]
        )

    @staticmethod
    def update(
        colour: bool = True,
        download_timeout: bool = False,
    ):
        opts = [
            "--sync",  # -S
            "--refresh",  # -y
            "--sysupgrade",  # -u
            "--noconfirm",
            "--needed",
        ]

        if colour:
            opts.append("--color always")
        else:
            opts.append("--color never")

        if not download_timeout:
            opts.append("--disable-download-timeout")

        return subprocess.run(
            [
                "/bin/pacman",
                *opts,
            ]
        )

    def config_tweaks(
        self,
        pacman_conf: Optional[StrPath] = None,
        parallel_downloads: Optional[int] = None,
        enable_multilib: Optional[bool] = None,
        enable_powerpill_patch: Optional[bool] = None,
        enable_local_repo: Optional[bool] = None,
    ):
        # region defaults
        if pacman_conf is None:
            pacman_conf = self.pacman_conf

        if parallel_downloads is None:
            parallel_downloads = self.parallel_downloads

        if enable_multilib is None:
            enable_multilib = self.enable_multilib

        if enable_powerpill_patch is None:
            enable_powerpill_patch = self.enable_powerpill_patch

        if enable_local_repo is None:
            enable_local_repo = self.enable_local_repo

        # endregion

        # txt_major "Applying pre-install pacman configuration settings..."

        # txt_minor "Enabling coloured pacman output..."
        replace_line("#Color", "Color", pacman_conf)

        # txt_minor "Enabling parallel downloads..."
        replace_line(
            r"^#ParallelDownloads.*",
            f"ParallelDownloads = {parallel_downloads}",
            pacman_conf,
            regex=True,
        )

        if multilib:
            # fmt: off
            replace_line(
                "#[multilib]\n" +
                "#Include = /etc/pacman.d/mirrorlist",

                "[multilib]\n" +
                "Include = /etc/pacman.d/mirrorlist",

                pacman_conf,
                multiline=True
            )
            # fmt: on

        # txt_major "Applying 'powerpill' patch"

        if powerpill_patch:
            repos_to_patch: List[str] = ["core", "extra", "community"]
            if multilib:
                repos_to_patch.append("multilib")

            for repo in repos_to_patch:
                # fmt: off
                replace_line(
                    f"[{repo}]\n" +
                    "Include = /etc/pacman.d/mirrorlist",

                    f"[{repo}]\n" +
                    "SigLevel = PackageRequired\n" +
                    "Include = /etc/pacman.d/mirrorlist",

                    pacman_conf,
                    multiline=True
                )
                # fmt: on

        if local_repo:
            # fmt: off
            hook_string: str = str(
                "#[testing]\n" +
                "#Include = /etc/pacman.d/mirrorlist"
            )
            replace_line(
                hook_string,
                hook_string + "\n\n" +
                "# Local repo at '/repo'\n"
                "[repo]\n"
                "SigLevel = Optional TrustAll\n"
                "Server = file:///repo",
                pacman_conf,
                multiline=True,
            )
            # fmt: on

        # txt_major "Finished applying pre-install pacman configuration settings"
        # return

    @staticmethod
    def pacstrap(
        *extra_packages: str,
        kernels: Set[str] = {"linux"},
        kernel_docs: bool = True,
        kernel_headers: bool = True,
        target: Optional[StrPath] = None,
        paru: bool = True,
    ):
        bootstrap_packages: Set[str] = {
            *kernels,
            "base-devel",
            "base",
            "bat",
            "diffutils",
            "fish",
            "linux-firmware",
            "nano",
            "python",
            "rsync",
        }

        if kernel_docs:
            for kernel in kernels:
                bootstrap_packages.add(f"{kernel}-docs")

        if kernel_headers:
            for kernel in kernels:
                bootstrap_packages.add(f"{kernel}-headers")

        for package in extra_packages:
            bootstrap_packages.add(package)

        if target is None:
            target = Path("/mnt")

        if local_repo and paru:
            bootstrap_packages.add("paru")

        return run(
            [
                "pacstrap",
                "-K",
                str(target),
                *bootstrap_packages,
            ],
        )
