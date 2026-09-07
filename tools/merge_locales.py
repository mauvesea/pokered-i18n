#!/usr/bin/env python3
"""Merge five 1 MiB locale ROMs into MBC5 language bank pages."""

from pathlib import Path
import sys


BANK_SIZE = 0x4000
PAGE_BANKS = 0x40
PAGE_SIZE = BANK_SIZE * PAGE_BANKS
MBC5_SIZE = 0x800000
LANGUAGES = ("en", "de", "es", "fr", "it")


def main() -> None:
    if len(sys.argv) != 7:
        raise SystemExit(
            "usage: merge_locales.py OUTPUT EN_ROM DE_ROM ES_ROM FR_ROM IT_ROM"
        )

    output = Path(sys.argv[1])
    inputs = [Path(name) for name in sys.argv[2:]]
    result = bytearray(MBC5_SIZE)

    for index, (language, path) in enumerate(zip(LANGUAGES, inputs)):
        rom = path.read_bytes()
        if len(rom) != PAGE_SIZE:
            raise SystemExit(
                f"{path}: expected a 1 MiB {language} ROM, got {len(rom)} bytes"
            )
        start = index * PAGE_SIZE
        result[start : start + PAGE_SIZE] = rom

    # rgbfix recalculates these after updating the final 8 MiB header.
    result[0x14D:0x150] = b"\0\0\0"
    output.write_bytes(result)


if __name__ == "__main__":
    main()
