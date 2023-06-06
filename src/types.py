from typing import TYPE_CHECKING
if TYPE_CHECKING:
    from pathlib import Path
    from rich
    StrPath = str | Path
    RichConsole = rich.console.Console
