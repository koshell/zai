#!/usr/bin/env python3
"""
Pacman handler
"""

__author__ = "Zaiju"
__version__ = "0.1.0"
__license__ = "GPL3"

import re
import subprocess
from pathlib import Path
from subprocess import run
from typing import List, Set

from .common import replace_line

parallel_downloads: int = 5
multilib: bool = True
powerpill_patch: bool = True
local_repo: bool = True


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


def pre_install():
    pacman_conf = Path("/etc/pacman.conf")
    parallel_downloads: int = 5
    multilib: bool = True
    powerpill_patch: bool = True
    local_repo: bool = True

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


def pacstrap():
    kernel: str = "linux"
    kernel_packages: Set[str] = {kernel, f"{kernel}-docs", f"{kernel}-headers"}
    bootstrap_packages: Set[str] = {
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

    bootstrap_packages.add(*kernel_packages)

    if local_repo:
        bootstrap_packages.add("paru")

    return run(
        [
            "pacstrap",
            "-K",
            "/mnt",
            *bootstrap_packages,
        ],
    )
