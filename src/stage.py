from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from logging import Logger
    from typing import Literal

    from _typeshed import SupportsWrite
    from rich.console import Console as RichConsole
    from rich.console import JustifyMethod, OverflowMethod
    from rich.style import Style


class Stage:
    def __init__(
        self,
        config: dict[str, Any],
        *,
        console: RichConsole | None = None,
        logger: Logger | None = None,
    ) -> None:
        self.__config = config
        self.__console = console
        self.__logger = logger

    def print(
        self,
        *values: object,
        sep: str | None = " ",
        end: str | None = "\n",
        file: SupportsWrite[str] | None = None,
        flush: Literal[False] = False,
        style: str | Style | None = None,
        justify: JustifyMethod | None = None,
        overflow: OverflowMethod | None = None,
        no_wrap: bool | None = None,
        emoji: bool | None = None,
        markup: bool | None = None,
        highlight: bool | None = None,
        width: int | None = None,
        height: int | None = None,
        crop: bool = True,
        soft_wrap: bool | None = None,
        new_line_start: bool = False,
    ) -> None:
        if self.__console is None:
            print(*values, sep=sep, end=end, file=file, flush=flush)
            return
        else:
            if sep is None:
                sep = ""
            if end is None:
                end = ""
            self.__console.print(
                *values,
                sep=sep,
                end=end,
                style=style,
                justify=justify,
                overflow=overflow,
                no_wrap=no_wrap,
                emoji=emoji,
                markup=markup,
                highlight=highlight,
                width=width,
                height=height,
                crop=crop,
                soft_wrap=soft_wrap,
                new_line_start=new_line_start,
            )
            return
