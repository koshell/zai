#!/usr/bin/env python3
"""
Module Docstring
"""
from __future__ import annotations

__author__ = "Zaiju"
__version__ = "0.1.0"
__license__ = "GPL3"

import argparse
import json
import logging
import os
import pathlib
import sys
from os import curdir
from pathlib import Path
from typing import TYPE_CHECKING, Any, Optional

import jsonschema
import pikaur
import rich
from jsonschema import validate

from .stage_1.main import Stage_One
from .stage_2.main import Stage_Two
from .stage_3.main import Stage_Three

if TYPE_CHECKING:
    from _typeshed import StrPath

STRIP_PATH = " " + "'" + '"'


class Zaiju_Arch_Installer:
    """
    TODO
    """

    def __init__(
        self,
        *,
        zai_home: Optional[StrPath] = None,
        debug: bool = False,
        stage: Optional[int] = None,
        config_file: Optional[StrPath] = None,
    ) -> None:
        self.__config: dict[str, Any] = dict()
        if zai_home is not None:
            self.__config["zai_home"] = Path(str(zai_home).strip(STRIP_PATH))
        elif "ZAI_HOME" in os.environ:
            self.__config["zai_home"] = Path(
                str(os.environ["ZAI_HOME"]).strip(STRIP_PATH)
            )
        else:
            self.__config["zai_home"] = Path(__file__).parent.absolute()

        if "ZAI_DEBUG" in os.environ:
            self.__config["debug"] = True
        else:
            self.__config["debug"] = debug

        if stage is not None:
            self.__stage: int = int(stage)
        elif "ZAI_STAGE" in os.environ:
            self.__stage: int = int(os.environ["ZAI_STAGE"])
        else:
            self.__stage: int = 1

        if "ZAI_VM" in os.environ:
            self.__config["vm"] = True
        else:
            self.__config["vm"] = False

    def stage_one(self) -> None:
        Stage_One(config=self.__config).main()

    def stage_two(self) -> None:
        Stage_Two(config=self.__config).main()

    def stage_three(self) -> None:
        Stage_Three(config=self.__config).main()

    def start(self) -> None:
        match self.__stage:
            case 1:
                self.stage_one()
            case 2:
                self.stage_two()
            case 3:
                self.stage_three()
            case _:
                raise ValueError(f"Invalid stage: {self.__stage}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        prog="Z.A.I.",
        description="Installs Arch Linux",
        epilog="Created by Zaiju",
    )

    # Optional argument flag which defaults to False
    parser.add_argument("--debug", action="store_true", dest="debug", default=False)

    parser.add_argument("--stage", action="store", dest="stage", type=int, nargs=1)

    parser.add_argument("--config", action="store", dest="config", type=Path, nargs=1)

    # Optional argument which requires a parameter (eg. -d test)
    parser.add_argument("--zai-home", action="store", dest="zai_home", type=Path, nargs=1)

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

    # Unwrap argparse into a dict
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
