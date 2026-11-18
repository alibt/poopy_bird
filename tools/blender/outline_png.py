#!/usr/bin/env python3
"""Dilate a PNG's alpha into a dark outline. Used by the Blender export pipeline."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageFilter


def outline(
    path: Path,
    *,
    width: int = 5,
    color: tuple[int, int, int] = (20, 20, 28),
) -> None:
    im = Image.open(path).convert("RGBA")
    alpha = im.getchannel("A")
    rim = alpha.filter(ImageFilter.MaxFilter(width * 2 + 1))
    base = Image.new("RGBA", im.size, (*color, 0))
    base.putalpha(rim)
    Image.alpha_composite(base, im).save(path)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=Path)
    parser.add_argument("--width", type=int, default=5)
    parser.add_argument("--color", default="20,20,28")
    args = parser.parse_args()
    rgb = tuple(int(p) for p in args.color.split(","))
    outline(args.path, width=args.width, color=rgb)  # type: ignore[arg-type]
    print(f"[poopy-bird] outlined {args.path}")


if __name__ == "__main__":
    main()
