#!/usr/bin/env python3
"""Draw the logical tile grid from a fixed VPR layout (not a physical GDS)."""

from __future__ import annotations

import argparse
import xml.etree.ElementTree as ET
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--arch", type=Path, required=True)
    parser.add_argument("--device", required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()

    root = ET.parse(args.arch).getroot()
    layout = next(
        (item for item in root.findall("./layout/fixed_layout")
         if item.get("name") == args.device),
        None,
    )
    if layout is None:
        parser.error(f"fixed_layout {args.device!r} is not defined in {args.arch}")

    width = int(layout.attrib["width"])
    height = int(layout.attrib["height"])
    expected = f"{width - 2}x{height - 2}"
    if expected != args.device or width < 3 or height < 3:
        parser.error("expected an NxM core with one perimeter I/O row")

    step = 68 if max(width, height) <= 10 else 40
    gap = 5
    margin = 75
    canvas_width = 2 * margin + width * step
    canvas_height = 2 * margin + height * step + 50
    title = f"{args.device} logical FPGA tile grid"

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" '
        f'width="{canvas_width}" height="{canvas_height}" '
        f'viewBox="0 0 {canvas_width} {canvas_height}">',
        '<rect width="100%" height="100%" fill="#f8fafc"/>',
        f'<text x="{margin}" y="35" font-family="DejaVu Sans, sans-serif" '
        f'font-size="22" fill="#15315b">{title}</text>',
        f'<text x="{margin}" y="57" font-family="DejaVu Sans, sans-serif" '
        f'font-size="13" fill="#475569">'
        f'{(width - 2) * (height - 2)} CLBs  |  '
        f'{2 * (width - 2) + 2 * (height - 2)} perimeter I/O sites'
        '</text>',
    ]

    for y in range(height):
        for x in range(width):
            edge_x = x in (0, width - 1)
            edge_y = y in (0, height - 1)
            if edge_x and edge_y:
                continue  # Empty corners in the architecture XML.

            is_io = edge_x or edge_y
            color = "#c9e2e8" if is_io else "#a9c4ed"
            stroke = "#477583" if is_io else "#315f98"
            label = "IO" if is_io else "CLB"
            xx = margin + x * step + gap
            yy = margin + y * step + gap
            size = step - 2 * gap

            parts.append(
                f'<rect x="{xx}" y="{yy}" width="{size}" height="{size}" '
                f'rx="4" fill="{color}" stroke="{stroke}"/>'
            )
            parts.append(
                f'<text x="{xx + size // 2}" y="{yy + size // 2 + 4}" '
                f'text-anchor="middle" font-family="DejaVu Sans, sans-serif" '
                f'font-size="{11 if step >= 60 else 8}" '
                f'fill="#132c4b">{label}</text>'
            )

    parts.append(
        f'<text x="{margin}" y="{canvas_height - 22}" '
        'font-family="DejaVu Sans, sans-serif" font-size="12" '
        'fill="#64748b">Logical VPR architecture. '
        'Tiles and gaps are schematic; no physical placement, routing or GDS.</text>'
    )
    parts.append("</svg>")

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("\n".join(parts) + "\n", encoding="utf-8")
    print(args.out)


if __name__ == "__main__":
    main()
