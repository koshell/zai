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
from pathlib import Path
from typing import TYPE_CHECKING, Any, Optional

from stage_one import Stage_One
from stage_three import Stage_Three
from stage_two import Stage_Two

if TYPE_CHECKING:
    from _typeshed import StrPath

STRIP_CHARS = " " + "'" + '"'


class Zaiju_Arch_Installer:
    """_summary_

    Args:
        zai_home (Optional[StrPath], optional): _description_. Defaults to None.
        debug (bool, optional): _description_. Defaults to False.
        stage (Optional[int], optional): _description_. Defaults to None.
        config_file (Optional[StrPath], optional): _description_. Defaults to None.
    """

    def __init__(
        self,
        *,
        zai_home: Optional[StrPath] = None,
        debug: bool = False,
        stage: Optional[int] = None,
        config_file: Optional[StrPath] = None,
    ) -> None:
        # Create an empty dict to store the config values
        self.__config: dict[str, Any] = dict()

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
            self.__config["zai_home"] = Path(__file__).parent.absolute()

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
        else:
            self.__load_config(Zaiju_Arch_Installer.default_config)
        print("done")

    def __load_config(self, raw_config: dict) -> None:
        for key in self.__config:
            raw_config[key] = self.__config[key]
        self.__config = raw_config
        return

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


def read_config(config_path: StrPath) -> dict:
    config_file = Path(str(config_path).strip(STRIP_CHARS))
    return_dict: dict
    with open(config_file) as conf:
        return_dict = json.load(conf)
    return return_dict


