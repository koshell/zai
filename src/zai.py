#!/usr/bin/env python3
"""
Module Docstring
"""
from __future__ import annotations

__author__ = "Zaiju"
__version__ = "0.1.0"
__license__ = "GPL3"

import json
import os
from copy import deepcopy
from pathlib import Path
from typing import TYPE_CHECKING

from .stage_1 import Stage_One
from .stage_2 import Stage_Two
from .stage_3 import Stage_Three

if TYPE_CHECKING:
    from decimal import Decimal as decimal
    from logging import Logger
    from typing import Any

    from _typeshed import StrPath, SupportsWrite
    from rich.console import Console as RichConsole

    NUMBER_TYPE = int | float | decimal

    # Valid JSON types
    JSON_VALUE_TYPE = str | NUMBER_TYPE | bool | None
    JSON_OBJ_TYPE = type[dict[str, JSON_VALUE_TYPE] | list[JSON_VALUE_TYPE]]
    JSON_TYPE = type[
        JSON_OBJ_TYPE | JSON_VALUE_TYPE | list[JSON_OBJ_TYPE] | dict[str, JSON_OBJ_TYPE]
    ]

STRIP_CHARS = " " + "'" + '"'


class Zaiju_Arch_Installer:
    """_summary_

    Args:
        zai_home (Optional[StrPath], optional): _description_. Defaults to None.
        debug (bool, optional): _description_. Defaults to False.
        stage (Optional[int], optional): _description_. Defaults to None.
        config_file (Optional[StrPath], optional): _description_. Defaults to None.
    """

    DEFAULT_CONFIG: dict[str, Any] = {}

    def __init__(
        self,
        *,
        zai_home: StrPath | None = None,
        debug: bool = False,
        stage: int | None = None,
        config_file: StrPath | None = None,
    ) -> None:
        # Load default config
        self.__config: dict[str, Any] = deepcopy(Zaiju_Arch_Installer.DEFAULT_CONFIG)

        # If <zai_home> was set use that
        if zai_home is not None:
            self.__config["zai_home"] = Path(str(zai_home).strip(STRIP_CHARS))

        # Otherwise use $ZAI_HOME if it is set
        elif "ZAI_HOME" in os.environ:
            self.__config["zai_home"] = Path(
                str(os.environ["ZAI_HOME"]).strip(STRIP_CHARS)
            )
        else:
            # Finally use the current working directory
            self.__config["zai_home"] = Path.cwd()

        # If $ZAI_DEBUG is set enable debug
        if "ZAI_DEBUG" in os.environ:
            self.__config["debug"] = True

        # If <debug> was set enable debug
        else:
            self.__config["debug"] = debug

        # If <stage> was set use it
        if stage is not None:
            self.__stage: int = int(stage)

        # If $ZAI_STAGE exists use that
        elif "ZAI_STAGE" in os.environ:
            self.__stage: int = int(os.environ["ZAI_STAGE"])

        # Otherwise stage = 1
        else:
            self.__stage: int = 1

        # If $ZAI_VM exists set it
        if "ZAI_VM" in os.environ:
            self.__config["vm"] = True
        else:
            self.__config["vm"] = False

        if config_file is not None:
            self.__load_config(read_config(config_file))

    def __load_config(
        self: Zaiju_Arch_Installer, raw_config: dict[str, None | StrPath]
    ) -> None:
        for top_level in raw_config:
            if top_level in self.__config:
                if isinstance(self.__config[top_level], list | dict) and isinstance(
                    raw_config[top_level], list | dict
                ):
                    pass
            else:
                self.__config[top_level] = raw_config[top_level]

    def stage_one(self: Zaiju_Arch_Installer) -> None:
        Stage_One(config=self.__config).main()

    def stage_two(self: Zaiju_Arch_Installer) -> None:
        Stage_Two(config=self.__config).main()

    def stage_three(self: Zaiju_Arch_Installer) -> None:
        Stage_Three(config=self.__config).main()

    def start(self: Zaiju_Arch_Installer) -> None:
        match self.__stage:
            case 1:
                self.stage_one()
            case 2:
                self.stage_two()
            case 3:
                self.stage_three()
            case _:
                raise ValueError(f"Invalid stage: {self.__stage}")


def read_config(config_path: StrPath) -> dict:
    config_file = Path(str(config_path).strip(STRIP_CHARS))
    return_dict: dict
    with Path.open(config_file) as conf:
        return_dict = json.load(conf)
    return return_dict


class Stage_Base:
    """_summary_

    Raises:
        ValueError: _description_
    """

    def __init__(
        self,
        config: dict[str, Any],
        *,
        console: RichConsole | None = ...,
        logger: Logger | None = ...,
    ) -> None:
        self.__config = config
        self.__console = console
        self.__logger = logger

    def _print(
        self,
        *values: object,
        sep: str | None = ...,
        end: str | None = ...,
        file: SupportsWrite[str] | None = ...,
        flush: bool = ...,
        **kwargs: object,
    ) -> None:
        if self.__console is None:
            print(*values, sep=sep, end=end, file=file, flush=flush)
            return
        else:
            self.__console.print(*values, sep=sep, end=end, **kwargs)
            return
