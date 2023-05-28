#!/usr/bin/env python3
"""
Pre-arch-chroot portion
"""

__author__ = "Zaiju"
__version__ = "0.1.0"
__license__ = "GPL3"


def main():
    discard: bool = True
    home_uuid: str = "2130216506"
    swap_uuid: str = "2130216506"

    if discard:
        discard_str: str = " discard"
    else:
        discard_str: str = str()

    crypttab_config = [
        "",  # Newline for nicer formatting
        f"luks-home UUID={home_uuid} /crypto_keyfile.bin" + discard_str,
        f"luks-swap UUID={swap_uuid} /crypto_keyfile.bin" + discard_str,
    ]
    # txt_major "Configuring '/etc/crypttab'..."
    with open("/mnt/etc/crypttab", "a") as f:
        f.writelines(crypttab_config)
    return
