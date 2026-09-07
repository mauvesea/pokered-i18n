#!/usr/bin/env python3
"""Import localized assembly blocks from another pokered disassembly.

Only blocks whose global labels exist in both trees are replaced. The target
label declaration is preserved, so differences between local and exported
symbols do not leak in from the source repository.
"""

from __future__ import annotations

import argparse
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
import re
import sys


GLOBAL_LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_#]*)(::?)(.*?)(\r?\n)?$")
LOCALIZED_DATA_ROUTES = (
    ("data/{locale}/yes_no_menu_strings.asm", "data/yes_no_menu_strings.asm"),
    ("data/battle/{locale}/stat_names.asm", "data/battle/stat_names.asm"),
    ("data/battle/{locale}/stat_mod_names.asm", "data/battle/stat_mod_names.asm"),
    ("data/events/{locale}/trades.asm", "data/events/trades.asm"),
    ("data/items/{locale}/names.asm", "data/items/names.asm"),
    ("data/maps/{locale}/names.asm", "data/maps/names.asm"),
    ("data/moves/{locale}/field_move_names.asm", "data/moves/field_move_names.asm"),
    ("data/player/{locale}/names.asm", "data/player/names.asm"),
    ("data/player/{locale}/names_list.asm", "data/player/names_list.asm"),
    ("data/pokemon/{locale}/dex_entries.asm", "data/pokemon/dex_entries.asm"),
    ("data/pokemon/{locale}/names.asm", "data/pokemon/names.asm"),
    ("data/trainers/{locale}/names.asm", "data/trainers/names.asm"),
    ("data/types/{locale}/names.asm", "data/types/names.asm"),
)


@dataclass(frozen=True)
class LabelBlock:
    label: str
    path: Path
    lines: tuple[str, ...]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="source disassembly root")
    parser.add_argument("locale", help="destination locale directory, such as de")
    parser.add_argument(
        "--report",
        type=Path,
        required=True,
        help="path for the unmatched-label report",
    )
    parser.add_argument(
        "--write",
        action="store_true",
        help="write matched source blocks into the destination files",
    )
    return parser.parse_args()


def find_blocks(path: Path) -> tuple[list[str], list[LabelBlock]]:
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    starts: list[tuple[int, str]] = []
    for index, line in enumerate(lines):
        match = GLOBAL_LABEL_RE.match(line)
        if match:
            starts.append((index, match.group(1)))

    blocks: list[LabelBlock] = []
    for position, (start, label) in enumerate(starts):
        end = starts[position + 1][0] if position + 1 < len(starts) else len(lines)
        blocks.append(LabelBlock(label, path, tuple(lines[start:end])))
    return lines, blocks


def destination_routes(root: Path, locale: str) -> list[tuple[Path, Path]]:
    routes = [
        (path, Path("text") / path.name)
        for path in sorted((root / "text" / locale).glob("*.asm"))
    ]
    routes.extend(
        (path, Path("data/text") / path.name)
        for path in sorted((root / "data" / "text" / locale).glob("text_*.asm"))
    )
    routes.append(
        (
            root / "data" / "text" / locale / "dex_text.asm",
            Path("data/pokemon/dex_text.asm"),
        )
    )
    routes.append(
        (
            root / "data" / "text" / locale / "move_names.asm",
            Path("data/moves/names.asm"),
        )
    )
    routes.extend(
        (root / destination.format(locale=locale), Path(source))
        for destination, source in LOCALIZED_DATA_ROUTES
    )
    return routes


def preserve_target_label(target_line: str, source_line: str) -> str:
    target = GLOBAL_LABEL_RE.match(target_line)
    source = GLOBAL_LABEL_RE.match(source_line)
    if target is None or source is None or target.group(1) != source.group(1):
        raise ValueError("attempted to combine different labels")
    ending = source.group(4) or ""
    return target.group(1) + target.group(2) + source.group(3) + ending


def write_report(
    report_path: Path,
    source_root: Path,
    project_root: Path,
    locale: str,
    matched: int,
    unmatched_destinations: list[LabelBlock],
    unmatched_sources: list[LabelBlock],
) -> None:
    lines = [
        f"Locale import ({locale}): labels not found\n",
        f"Source: {source_root}\n",
        f"Matched labels: {matched}\n",
        f"Destination labels not found in source: {len(unmatched_destinations)}\n",
        f"Source labels without a destination: {len(unmatched_sources)}\n",
        "\n",
        "Destination labels not found in source:\n",
    ]
    lines.extend(
        f"- {block.label} ({block.path.relative_to(project_root)})\n"
        for block in unmatched_destinations
    )
    lines.append("\nSource labels without a destination:\n")
    lines.extend(
        f"- {block.label} ({block.path.relative_to(source_root)})\n"
        for block in unmatched_sources
    )
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text("".join(lines), encoding="utf-8")


def main() -> None:
    args = parse_args()
    project_root = Path(__file__).resolve().parent.parent
    source_root = args.source.resolve()
    routes = destination_routes(project_root, args.locale)

    missing_destinations = [path for path, _ in routes if not path.is_file()]
    missing_sources = [source_root / path for _, path in routes if not (source_root / path).is_file()]
    if missing_destinations or missing_sources:
        for path in missing_destinations:
            print(f"missing destination: {path}", file=sys.stderr)
        for path in missing_sources:
            print(f"missing source: {path}", file=sys.stderr)
        raise SystemExit(1)

    source_blocks: defaultdict[str, list[LabelBlock]] = defaultdict(list)
    for source_path in dict.fromkeys(source_root / source for _, source in routes):
        _, blocks = find_blocks(source_path)
        for block in blocks:
            source_blocks[block.label].append(block)

    duplicate_sources = {
        label: blocks for label, blocks in source_blocks.items() if len(blocks) != 1
    }
    if duplicate_sources:
        for label, blocks in sorted(duplicate_sources.items()):
            locations = ", ".join(str(block.path) for block in blocks)
            print(f"duplicate source label {label}: {locations}", file=sys.stderr)
        raise SystemExit(1)

    matched = 0
    unmatched: list[LabelBlock] = []
    seen_destinations: dict[str, Path] = {}
    changed_files = 0

    for destination_path, _ in routes:
        original_lines, destination_blocks = find_blocks(destination_path)
        # Rebuild by walking the parsed blocks; content before the first label
        # remains local to this project.
        first_start = next(
            (
                index
                for index, line in enumerate(original_lines)
                if GLOBAL_LABEL_RE.match(line)
            ),
            len(original_lines),
        )
        output = original_lines[:first_start]

        for block in destination_blocks:
            previous = seen_destinations.get(block.label)
            if previous is not None:
                raise SystemExit(
                    f"duplicate destination label {block.label}: "
                    f"{previous}, {destination_path}"
                )
            seen_destinations[block.label] = destination_path

            candidates = source_blocks.get(block.label, [])
            if not candidates:
                unmatched.append(block)
                output.extend(block.lines)
                continue

            source_block = candidates[0]
            replacement = list(source_block.lines)
            replacement[0] = preserve_target_label(block.lines[0], replacement[0])
            output.extend(replacement)
            matched += 1

        if output != original_lines:
            changed_files += 1
        if args.write and output != original_lines:
            destination_path.write_text("".join(output), encoding="utf-8")

    unmatched_sources = [
        blocks[0]
        for label, blocks in sorted(source_blocks.items())
        if label not in seen_destinations
    ]
    write_report(
        args.report.resolve(),
        source_root,
        project_root,
        args.locale,
        matched,
        unmatched,
        unmatched_sources,
    )
    action = "imported" if args.write else "would import"
    print(
        f"{action} {matched} matching labels; "
        f"{len(unmatched)} destination and {len(unmatched_sources)} source labels not found; "
        f"{changed_files} files {'changed' if args.write else 'would change'}"
    )


if __name__ == "__main__":
    main()
