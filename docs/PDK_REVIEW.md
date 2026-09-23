# SCL 1.2 µm C1D review for `vsd-fpga-scl1d`

This review is based on the supplied `SCL 1.2 µm PDK.zip` release. The digital kit contains a two-metal technology LEF, core and I/O LEFs, Liberty timing corners, Verilog models, CDL, GDS and OpenLane/OpenROAD templates. The archive also contains an analog kit with pad and test structures; that analog kit is useful for circuit work but is not the cell source for the OpenFPGA digital fabric.

## Cell groups

The digital standard-cell set has the expected primitives for a first fabric: AND/NAND/NOR/OR gates up to eight inputs, decoders, `MX2101` 2:1 and `MX4122` 4:1 multiplexers, `DFFL11`/`DFCL11`/`DFPC11`/`DFPR11` flip-flops, latches, six inverter drive strengths, clock drivers, buffers, tri-state cells, XOR/XNOR and fillers. The Liberty file also contains `VDDCON` and `VSSCON` tie cells.

The digital I/O set contains 18 pad choices: bidirectional BPD cells, CMOS input cells, Schmitt input cells, output cells, and `PVDD01`/`PVSS01` power pads. The LEF pad depth is 304.9 µm. Signal pad widths are approximately 201.6–285.6 µm; the corner is 304.9 µm square. The pad ring therefore dominates the 5 mm package outline, while the core remains large enough for a small fabric.

The LEF core site is 48.7 µm high. Standard-cell widths are on a 4.2 µm grid; for example, `INVR01` is 12.6 × 48.7 µm, `DFFL11` is 84.0 × 48.7 µm, `DFCL11` is 100.8 × 48.7 µm, `MX2101` is 32.6 × 48.7 µm, `MX4122` is 121.8 × 48.7 µm, and the fillers are 8/4/2/1/0.01 µm wide. The Liberty `area` values are library units and should not be mixed with LEF geometry; physical sizing uses LEF/GDS.

## Important technology facts

- Metal 1 is horizontal with 4.0 µm pitch; metal 2 is vertical with 4.2 µm pitch.
- The technology is a 5 V digital library. The Liberty corners are named TT 27°C/5 V, FF −25°C/5.5 V, and SS 125°C; check the SS file’s voltage-map metadata before using it for signoff.
- The kit provides a 2-metal routing stack. This makes routing congestion, power distribution, configuration-chain length and clock fanout the main limits.
- `TBUF01`/`TINV01` and pad bidirectional controls exist, but the FPGA routing fabric should use explicit muxes and buffers. Internal tri-state routing makes verification and two-metal physical routing harder.
- `DFFL11` has a 84.0 × 48.7 µm LEF footprint. A 4-input LUT needs 16 configuration bits, so the 32-LUT reference already requires 512 configuration flip-flops before routing mux and I/O configuration bits. This is the reason to start with the validated 2×2 target.

## Padframe arithmetic

The project’s padframe target is 5 mm × 5 mm with 44 signal I/Os excluding power and ground. A 304.9 µm deep corner and roughly 200–286 µm wide signal pad leave about 4.39 mm of usable square core span after the inner pad-ring edge, before the core ring and routing keep-out. The 44 signal I/Os are feasible around the perimeter, but their exact pitch, power-pad count and pad ordering must be frozen in the pad-ring DEF before fabric size is treated as final.

## Recommended fabric sizes

| Milestone | VPR fabric | Logic resources | Configuration estimate | Recommendation |
|---|---:|---:|---:|---|
| Generation 0 | 2×2 CLBs | 4 CLBs, 16 FLEs, 32 LUT4s, 64 user FFs | 2,321 bits in the validated reference chain | Use for first SCL OpenFPGA→GDS→silicon qualification |
| Generation 1 | 4×4 CLBs | 16 CLBs, 64 FLEs, 64 LUT4s, 64 user FFs | roughly 4×–8× Gen-0 after routing/I/O configuration | Attempt only after 2×2 physical closure |
| Deferred | 8×8 CLBs | 64 CLBs, 256 FLEs | likely too large and routing-heavy for the first 5 mm padframe | Do not make this the first silicon target |

The area estimate from configuration storage alone is not a complete floorplan: each LUT4 has 16 configuration bits, while routing muxes, switch blocks, connection blocks, buffers, clock distribution and power straps add significant area. Therefore “routable” must be proven by OpenROAD placement and detailed routing, not inferred from a cell-count ratio.

## Cell mapping for OpenFPGA

| Fabric function | SCL implementation |
|---|---|
| LUT configuration / scan chain | `DFFL11` as `ccff`, with `Q` and `QB` mapped in the exact port order validated from `c1d.v` and CDL |
| User FF | `DFCL11` when active-low clear is required; otherwise `DFFL11` |
| 2:1 routing mux | `MX2101` |
| 4:1 mux tree | `MX4122` or a tree of `MX2101` cells |
| Local buffer / inverter | `DELBUF`, `INVR01`–`INVR06` |
| Clock fanout | `CDRI01`/`CDRI02` followed by a deliberately constrained clock tree |
| GPIO physical model | wrapper with explicit `in`, `out`, `oeb` semantics around `IPAD20`/`IPAD30`, `OPAD02`/`OPAD04`, or a BPD variant |
| Core constants | `VDDCON`, `VSSCON` |
| Row closure | `FILLER1`–`FILLER5` |

Before the first real generation run, validate every wrapper’s port order in three places: Liberty pin names, Verilog module declaration, and CDL/GDS extracted pin order. The source has historical duplicate/variant subcircuits such as `MX2101_old`, `_dummy`, `_magic`, and `_123`; use only the canonical digital LEF/Liberty/Verilog cells in the selected flow.

## Closure gates

1. `make doctor` passes in a fresh Codespace.
2. The SCL primitive wrappers compile with `c1d.v` in functional mode.
3. OpenFPGA generates the 2×2 structural fabric and serial bitstream.
4. Icarus runs the generated AND2 testbench.
5. The generated fabric is synthesized and placed with the SCL LEF/Liberty.
6. OpenROAD detailed routing completes using only metal 1/metal 2, with no unresolved opens, shorts or antenna errors.
7. KLayout DRC/LVS runs against the SCL decks and the padframe integration is checked.
8. Only after these pass should 4×4 be attempted.
