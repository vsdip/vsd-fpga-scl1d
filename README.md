# vsd-fpga-scl1d

An OpenFPGA-based Generation-0 embedded FPGA fabric for the indigenous SCL 1.2 µm C1D process. The repository is designed for GitHub Codespaces and keeps the SCL PDK external.

## Recommended first silicon target

Use the already validated **2×2 fabric** as the baseline: 4 CLBs, 16 FLEs, 32 LUT4s, 64 user FFs, 20 routing tracks, L1/L2 routing, 8 GPIO, one 2,321-bit serial CCFF chain, 5 V, and a 1 MHz user-clock target. This is a silicon qualification target, not a feature-complete SoC.

A 4×4 fabric should be treated as a second milestone after the 2×2 passes OpenFPGA generation, simulation, OpenROAD placement/routing, DRC/LVS and pad-ring integration. Do not choose 8×8 for a 5 mm × 5 mm padframe at this process node.

## Quick start

```bash
# in a Codespace
make install-pdk ARCHIVE="$HOME/SCL 1.2 µm PDK.zip"
export SCL1D_PDK_ROOT="$PWD/pdk/local"
make doctor
make inspect
```

The exact OpenFPGA architecture XML and SCL primitive wrapper must be validated against the PDK’s `c1d.v`, `core_c1d.lef`, Liberty, CDL and GDS before running `make run-2x2`.

## PDK-aware cell mapping

- Configuration memory: `DFFL11` (scan FF; 84.0 × 48.7 µm in LEF).
- User logic FF: `DFCL11` or `DFFL11`, depending on reset policy.
- Routing MUX: `MX2101` (2:1) or `MX4122` (4:1); avoid internal tri-state routing.
- Buffers: `DELBUF`, `INVR01`–`INVR06`, and `CDRI01`/`CDRI02` for clock fanout.
- GPIO: use the explicit `in/out/oeb` wrapper around a selected BPD/IPAD/OPAD cell; do not infer an internal pad from a core standard cell.
- Power: `PVDD01`/`PVSS01` at the pad ring and `VDDCON`/`VSSCON` in the core where required.

## Repository boundaries

This project covers the OpenFPGA/VPR architecture, SCL primitive wrappers, generated structural Verilog, serial bitstream, AND2 qualification, and the path to GDS. CPU, bus, BRAM, DSP, pad-frame signoff and production timing characterization are later milestones.

See [docs/CODESPACE.md](docs/CODESPACE.md), [docs/PDK_REVIEW.md](docs/PDK_REVIEW.md), and [pdk/README.md](pdk/README.md).
