from pathlib import Path
from subprocess import run

from .types import RichConsole, StrPath


def replace_line(
    search: str,
    replace: str,
    file_path: StrPath,
    regex: bool = False,
    multiline: bool = False,
):
    file_path = Path(file_path)
    if not file_path.exists():
        raise FileNotFoundError(str(file_path))

    # Use 'sed' instead of reinveting the wheel
    # Escape the use of | in any of the strings
    search = search.replace("|", r"\|")
    replace = replace.replace("|", r"\|")

    opts: str = "-i"
    if regex:
        opts += "r"
    if multiline:
        opts += "z"

    return run(
        [
            "sed",
            opts,
            f"s|{search}|{replace}|g",
            str(file_path),
        ]
    )
