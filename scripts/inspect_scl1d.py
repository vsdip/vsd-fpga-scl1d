#!/usr/bin/env python3
"""Inventory the installed SCL C1D digital PDK and padframes."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def add_lef_sizes(lines: list[str], path: Path, title: str) -> None:
    lines.extend([
        "",
        title,
        "",
        "| Cell | Width (µm) | Height (µm) | Area (µm²) |",
        "|---|---:|---:|---:|",
    ])
    if not path.is_file():
        return

    contents = path.read_text(errors="ignore")
    for macro in re.finditer(
        r"(?im)^macro\s+(\S+)(.*?)(?=^macro|\Z)",
        contents,
        re.S | re.M,
    ):
        size = re.search(
            r"(?im)^\s*SIZE\s+([\d.]+)\s+BY\s+([\d.]+)",
            macro.group(2),
        )
        if size:
            width, height = map(float, size.groups())
            lines.append(
                f"| `{macro.group(1)}` | {width:g} | {height:g} "
                f"| {width * height:,.1f} |"
            )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pdk-root", required=True)
    parser.add_argument("--out", required=True)
    args = parser.parse_args()

    root = Path(args.pdk_root)
    base = (
        root
        / "open_source_scl_c1d"
        / "open_pdks"
        / "sclc1d"
        / "libs.ref"
        / "digital_c1d"
    )
    pad = root / "padframe" / "PadFrame_C1D"

    lines = [
        "# SCL 1.2 µm C1D PDK inventory",
        "",
        f"Root: `{base}`",
        "",
        "## Digital payload",
        "",
        "| Asset | Present |",
        "|---|---|",
    ]

    digital_files = [
        "lef/tech_c1d.lef",
        "lef/core_c1d.lef",
        "lef/io_c1d.lef",
        "lef/corner_c1d.lef",
        "lib/c1d_core_typ.lib",
        "lib/c1d_core_min.lib",
        "lib/c1d_core_max.lib",
        "lib/scl1u_pads_typ.lib",
        "lib/scl1u_pads_min.lib",
        "lib/scl1u_pads_max.lib",
        "verilog/c1d.v",
        "cdl/core_iolib_c1d.cdl",
        "gds/core_c1d.gds",
        "gds/io_c1d.gds",
    ]
    for relative_path in digital_files:
        present = "yes" if (base / relative_path).is_file() else "NO"
        lines.append(f"| `{relative_path}` | {present} |")

    add_lef_sizes(lines, base / "lef" / "core_c1d.lef", "## Core cell LEF sizes")
    add_lef_sizes(lines, base / "lef" / "io_c1d.lef", "## I/O cell LEF sizes")

    lines.extend([
        "",
        "## Liberty cell areas",
        "",
        "| Cell | Area (Liberty units) |",
        "|---|---:|",
    ])
    liberty = base / "lib" / "c1d_core_typ.lib"
    if liberty.is_file():
        contents = liberty.read_text(errors="ignore")
        for cell in re.finditer(
            r"""(?m)^\s*cell\s*\(\s*["']?([^)\"']+)["']?\s*\)\s*\{"""
            r"(.*?)(?=^\s*cell\s*\(|\Z)",
            contents,
            re.S,
        ):
            area = re.search(
                r"(?m)^\s*area\s*:\s*([\d.eE+-]+)",
                cell.group(2),
            )
            if area:
                lines.append(
                    f"| `{cell.group(1).strip()}` | {area.group(1)} |"
                )

    lines.extend(["", "## CDL subcircuits", ""])
    cdl = base / "cdl" / "core_iolib_c1d.cdl"
    names = (
        re.findall(
            r"(?im)^\.subckt\s+(\S+)",
            cdl.read_text(errors="ignore"),
        )
        if cdl.is_file()
        else []
    )
    lines.append(
        f"Found **{len(names)}** `.subckt` entries, "
        "including implementation and pad variants."
    )
    lines.extend(["", ", ".join(f"`{name}`" for name in names)])

    lines.extend(["", "## GDS payload", ""])
    gds_dir = base / "gds"
    if gds_dir.is_dir():
        for path in sorted(gds_dir.iterdir()):
            if path.is_file():
                lines.append(f"- `{path.name}` ({path.stat().st_size:,} bytes)")

    lines.extend([
        "",
        "## SCL standard padframes",
        "",
        "| Die size | GDS | CDL |",
        "|---|---|---|",
    ])
    for mm in range(1, 6):
        name = f"frame{mm}mmx{mm}mm"
        frame_gds = pad / "pad_frame_gds" / f"{name}.gds"
        frame_cdl = pad / "pad_frame_cdl" / f"{name}.cdl"
        gds_present = "yes" if frame_gds.is_file() else "NO"
        cdl_present = "yes" if frame_cdl.is_file() else "NO"
        lines.append(
            f"| {mm}×{mm} mm | {gds_present} | {cdl_present} |"
        )

    pad_cell_gds = pad / "klayout" / "gds" / "io_pad_c1d.gds"
    lines.append(
        f"Pad-cell GDS: {'yes' if pad_cell_gds.is_file() else 'NO'}"
    )

    output = Path(args.out)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text("\n".join(lines) + "\n")
    print(output)


if __name__ == "__main__":
    main()
