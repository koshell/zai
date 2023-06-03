#!/usr/bin/env python3
"""
Module Docstring
"""
from __future__ import annotations

__author__ = "Zaiju"
__version__ = "0.1.0"
__license__ = "GPL3"
__package__ = "."

import argparse
import sys
from typing import Any
from pathlib import Path


from .base import Zaiju_Arch_Installer


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="Z.A.I.",
        description="Installs Arch Linux",
        epilog="Created by Zaiju",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        dest="debug",
        default=False,
    )
    parser.add_argument(
        "--stage",
        action="store",
        dest="stage",
        type=int,
        nargs=1,
    )
    parser.add_argument(
        "--config",
        action="store",
        dest="config",
        type=Path,
        nargs=1,
    )
    parser.add_argument(
        "--zai-home",
        action="store",
        dest="zai_home",
        type=Path,
        nargs=1,
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Verbosity (-v, -vv, etc)",
    )
    parser.add_argument(
        "--version",
        action="version",
        version="%(prog)s (version {version})".format(version=__version__),
    )
    arguments: dict[str, Any] = dict()
    for arg in parser.parse_args()._get_kwargs():
        try:
            arguments[arg[0]] = arg[1][0]
        except TypeError:
            arguments[arg[0]] = arg[1]

    zai = Zaiju_Arch_Installer(
        zai_home=arguments["zai_home"],
        debug=arguments["debug"],
        stage=arguments["stage"],
        config_file=arguments["config"],
    )

    zai.start()
    sys.exit()
