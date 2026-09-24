#!/usr/bin/env python3
"""Generate a deterministic SCL C1D inventory from LEF, Liberty, CDL and GDS payloads."""
from __future__ import annotations
import argparse,re
from pathlib import Path

def first(root, rel):
    p=root/rel
    return p if p.exists() else None

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--pdk-root',required=True); ap.add_argument('--out',required=True); a=ap.parse_args()
    root=Path(a.pdk_root); base=root/'open_source_scl_c1d/open_pdks/sclc1d/libs.ref/digital_c1d'
    lef=base/'lef'; lib=base/'lib'; cdl=base/'cdl'; gds=base/'gds'
    lines=['# SCL 1.2 µm C1D PDK inventory','',f'Root: `{base}`','']
    lines += ['## Digital payload','', '| Asset | Present |', '|---|---|']
    for rel in ['lef/tech_c1d.lef','lef/core_c1d.lef','lef/io_c1d.lef','lef/corner_c1d.lef','lib/c1d_core_typ.lib','lib/c1d_core_min.lib','lib/c1d_core_max.lib','verilog/c1d.v','cdl/core_iolib_c1d.cdl','gds/core_c1d.gds','gds/io_c1d.gds']:
        lines.append(f'| `{rel}` | {"yes" if (base/rel).is_file() else "NO"} |')
    lines += ['', '## Core cell LEF sizes (µm)', '', '| Cell | Width | Height | Area |', '|---|---:|---:|---:|']
    core=lef/'core_c1d.lef'
    if core.is_file():
        txt=core.read_text(errors='ignore')
        for m in re.finditer(r'(?im)^macro\s+(\S+)(.*?)(?=^macro|\Z)',txt,re.S|re.M):
            s=re.search(r'(?im)^\s*SIZE\s+([\d.]+)\s+BY\s+([\d.]+)',m.group(2));
            if s:
                w,h=map(float,s.groups()); lines.append(f'| `{m.group(1)}` | {w:g} | {h:g} | {w*h:,.1f} |')
    lines += ['', '## I/O cell LEF sizes (µm)', '', '| Cell | Width | Height | Area |', '|---|---:|---:|---:|']
    io=lef/'io_c1d.lef'
    if io.is_file():
        txt=io.read_text(errors='ignore')
        for m in re.finditer(r'(?im)^macro\s+(\S+)(.*?)(?=^macro|\Z)',txt,re.S|re.M):
            s=re.search(r'(?im)^\s*SIZE\s+([\d.]+)\s+BY\s+([\d.]+)',m.group(2));
            if s:
                w,h=map(float,s.groups()); lines.append(f'| `{m.group(1)}` | {w:g} | {h:g} | {w*h:,.1f} |')
    lines += ['', '## Liberty cell areas', '', '| Cell | Area (Liberty units) |', '|---|---:|']
    lp=lib/'c1d_core_typ.lib'
    if lp.is_file():
        txt=lp.read_text(errors='ignore')
        for m in re.finditer(r'(?m)^\s*cell\s*\(\s*["\']?([^\)"\']+)["\']?\s*\)\s*\{(.*?)(?=^\s*cell\s*\(|\Z)',txt,re.S):
            area=re.search(r'(?m)^\s*area\s*:\s*([\d.eE+-]+)',m.group(2))
            if area: lines.append(f'| `{m.group(1).strip()}` | {area.group(1)} |')
    lines += ['', '## CDL subcircuits', '']
    cp=cdl/'core_iolib_c1d.cdl'
    names=[]
    if cp.is_file(): names=re.findall(r'(?im)^\.subckt\s+(\S+)',cp.read_text(errors='ignore'))
    lines.append(f'Found **{len(names)}** `.subckt` entries, including implementation and pad variants.')
    lines.append('')
    lines.append(', '.join('`'+x+'`' for x in names))
    lines += ['', '## GDS payload', '']
    if gds.is_dir():
        for p in sorted(gds.glob('*')): lines.append(f'- `{p.name}` ({p.stat().st_size:,} bytes)')
            pad = root/'padframe/PadFrame_C1D'
    lines += ['', '## SCL standard padframes', '',
              '| Die size | GDS | CDL |', '|---|---|---|']
    for mm in range(1, 6):
        name = f'frame{mm}mmx{mm}mm'
        gd = pad/'pad_frame_gds'/f'{name}.gds'
        cd = pad/'pad_frame_cdl'/f'{name}.cdl'
        lines.append(
            f'| {mm}×{mm} mm | '
            f'{"yes" if gd.is_file() else "NO"} | '
            f'{"yes" if cd.is_file() else "NO"} |'
        )
    lines.append(
        f'Pad-cell GDS: '
        f'{"yes" if (pad/"klayout/gds/io_pad_c1d.gds").is_file() else "NO"}'
    )
    Path(a.out).write_text('\n'.join(lines)+'\n')
    print(a.out)
if __name__=='__main__': main()
