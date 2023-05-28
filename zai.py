#!/usr/bin/env python3
"""
Module Docstring
"""

__author__ = "Zaiju"
__version__ = "0.1.0"
__license__ = "GPL3"


import argparse
import json
import logging
import os
import pathlib
from os import curdir
from pathlib import Path
from typing import Optional

import jsonschema
import pikaur
import rich
from jsonschema import validate

from arch_installer import stage_1 as zai_1
from arch_installer import stage_2 as zai_2
from arch_installer import stage_3 as zai_3

# region env_flags

if "ZAI_DEBUG" in os.environ:
    DEBUG: bool = True
else:
    DEBUG: bool = False

if "ZAI_VM" in os.environ:
    VM: bool = True
else:
    VM: bool = False

# endregion


class Zaiju_Arch_Installer:
    def __init__(
        self,
        *args,
        zai_home: Optional[Path] = None,
    ):
        self.zai_home = zai_home

    # region zai_home

    @property
    def zai_home(self) -> Path:
        return self._zai_home

    @zai_home.setter
    def zai_home(self, zai_home: Optional[Path] = None) -> None:
        if zai_home is not None:
            if isinstance(zai_home, Path):
                self._zai_home = zai_home
                return
            else:
                raise TypeError(f"Expected type 'Path', got type '{type(zai_home)}'")
        elif "ZAI_HOME" in os.environ:
            self._zai_home = Path(os.environ["ZAI_HOME"])
            return
        else:
            self._zai_home = Path(__file__).parent.absolute()
            return

    # endregion

    def main(args):
        zai_1.main()
        zai_2.main()
        zai_3.main()


if __name__ == "__main__":
    """This is executed when run from the command line"""
    parser = argparse.ArgumentParser()

    # Required positional argument
    # parser.add_argument("arg", help="Required positional argument")

    # Optional argument flag which defaults to False
    parser.add_argument("-f", "--flag", action="store_true", default=False)

    # Optional argument which requires a parameter (eg. -d test)
    parser.add_argument("-n", "--name", action="store", dest="name")

    # Optional verbosity counter (eg. -v, -vv, -vvv, etc.)
    parser.add_argument(
        "-v", "--verbose", action="count", default=0, help="Verbosity (-v, -vv, etc)"
    )

    # Specify output of "--version"
    parser.add_argument(
        "--version",
        action="version",
        version="%(prog)s (version {version})".format(version=__version__),
    )

    args = parser.parse_args()

    global ZAI_DIR

    main(args)
    exit()
