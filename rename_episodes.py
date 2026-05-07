#!/usr/bin/env python3
import os
import sys
import re
import argparse
from pathlib import Path


def extract_episode_number(filename):
    """Extract episode number from filename using advanced pattern matching."""
    # Strip extension and lowercase for consistent matching
    name = Path(filename).stem.lower()

    # Pre-check: S##E## format before any cleaning
    se_match = re.search(r"s\d+e(\d{1,4})(?:v\d+)?", name, re.IGNORECASE)
    if se_match:
        ep_num = int(se_match.group(1))
        if 1 <= ep_num <= 9999:
            return ep_num

    # Remove common metadata that can contain numbers (ep count, seasons, years, resolutions)
    ignore_patterns = [
        r"\(\d+\s*ep\)",  # (12 ep)
        r"\[\d+\s*ep\]",  # [12 ep]
        r"complete\s*series",  # complete series
        r"season\s*\d+",  # season 1
        r"s\d+",  # s01
        r"\b(19|20)\d{2}\b",  # years (1900-2099)
        r"\b(2160p?|1080p?|720p?|480p?|360p?|4k|hd|fhd|uhd)\b",  # resolution tags
    ]

    clean_name = name
    for pattern in ignore_patterns:
        clean_name = re.sub(pattern, "", clean_name, flags=re.IGNORECASE)

    # Patterns in order of priority (higher = earlier)
    patterns = [
        # 1. Explicit episode markers: Episode, Ep, Ep., E
        r"(?:[Ee]pisode|[Ee]p\.?)[\s_]?(\d{1,4})",
        r"\b[Ee](\d{1,4})\b",
        # 2. Numbers surrounded by separators
        r"[-_\s\[\]\(](\d{1,4})[-_\s\[\]\)]",
        # 3. Numbers at end after a separator
        r"[-_\s](\d{1,4})$",
        # 4. Numbers at beginning before a separator
        r"^(\d{1,4})[-_\s]",
        # 5. Any isolated number (last resort)
        r"\b(\d{1,4})\b",
    ]

    # Try each pattern on the cleaned name
    for pattern in patterns:
        match = re.search(pattern, clean_name)
        if match:
            try:
                ep_num = int(match.group(1))
                if 1 <= ep_num <= 9999:  # sanity check
                    return ep_num
            except ValueError:
                continue

    # Fallback: try original name with only explicit markers (in case cleaning removed something crucial)
    fallback_patterns = [
        r"(?:[Ee]pisode|[Ee]p\.?)[\s_]?(\d{1,4})",
        r"\b[Ee](\d{1,4})\b",
    ]
    for pattern in fallback_patterns:
        match = re.search(pattern, name)
        if match:
            try:
                ep_num = int(match.group(1))
                if 1 <= ep_num <= 9999:
                    return ep_num
            except ValueError:
                continue

    return None


def rename_episodes(directory, show_name, padding=3, dry_run=False, interactive=False):
    video_extensions = {".mp4", ".mkv", ".avi", ".mov", ".flv", ".webm", ".m4v"}

    video_files = []
    for file in Path(directory).iterdir():
        if file.is_file() and file.suffix.lower() in video_extensions:
            ep_num = extract_episode_number(file.name)
            if ep_num is not None:
                video_files.append((ep_num, file))
            else:
                print(
                    f"WARNING: Could not extract episode number from: {file.name} — skipping"
                )

    if not video_files:
        print("No video files with detectable episode numbers found.")
        sys.exit(1)

    # Sort by episode number
    video_files.sort(key=lambda x: x[0])

    # Check for duplicate episode numbers
    ep_numbers = [ep for ep, _ in video_files]
    duplicates = set()
    for ep in set(ep_numbers):
        if ep_numbers.count(ep) > 1:
            duplicates.add(ep)

    if duplicates:
        print(
            f"\n⚠️  WARNING: Multiple files have the same episode number: {sorted(duplicates)}"
        )
        print("This could indicate incorrect episode number detection.")
        if interactive:
            response = input("Continue anyway? (y/N): ")
            if response.lower() != "y":
                print("Aborted.")
                sys.exit(1)
        else:
            print("Use --interactive flag to confirm or fix issues.\n")

    # Check for potential overwrites
    target_paths = {}
    rename_operations = []
    for ep_num, file_path in video_files:
        new_name = f"{show_name} - E{ep_num:0{padding}d}{file_path.suffix}"
        new_path = file_path.parent / new_name
        if new_path in target_paths:
            print(f"❌ CONFLICT: {new_name} would be created from both:")
            print(f"   - {target_paths[new_path].name}")
            print(f"   - {file_path.name}")
            print("This would cause overwrites! Aborting.")
            sys.exit(1)
        target_paths[new_path] = file_path
        rename_operations.append((file_path, new_path))

    renamed_count = 0
    for file_path, new_path in rename_operations:
        if dry_run:
            print(f"[DRY RUN] {file_path.name}  ->  {new_path.name}")
            continue

        try:
            if new_path.exists():
                print(
                    f"❌ ERROR: {new_path.name} already exists! Skipping {file_path.name}"
                )
                continue
            file_path.rename(new_path)
            print(f"Renamed: {file_path.name}  ->  {new_path.name}")
            renamed_count += 1
        except Exception as e:
            print(f"Error renaming {file_path.name}: {e}")

    if not dry_run:
        print(f"\nRenamed {renamed_count} files successfully.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Rename anime/TV episode files by episode number.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  rename_episodes ~/Videos/Anime/HxH-2011 "Hunter x Hunter"
  rename_episodes ~/Videos/Anime/Redo-of-Healer "Redo of Healer" --dry-run
  rename_episodes ~/Videos/Anime/My-Show "My Show" --padding 2 --interactive
        """,
    )
    parser.add_argument("directory", help="Directory containing episode files")
    parser.add_argument("show_name", help="Show name to use in renamed files")
    parser.add_argument(
        "--padding",
        type=int,
        default=3,
        help="Zero-padding for episode number (default: 3 → E001)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview renames without actually doing anything",
    )
    parser.add_argument(
        "--interactive",
        "-i",
        action="store_true",
        help="Ask for confirmation when issues are detected",
    )

    args = parser.parse_args()

    if not os.path.isdir(args.directory):
        print(f"Error: Directory '{args.directory}' does not exist")
        sys.exit(1)

    rename_episodes(
        args.directory, args.show_name, args.padding, args.dry_run, args.interactive
    )
