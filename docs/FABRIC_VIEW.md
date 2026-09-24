# View and resize the OpenFPGA fabric

## Open the Codespace desktop

Create a Codespace after the noVNC files are committed. In VS Code, open
**Ports**, find **FPGA noVNC Desktop** on port `6080`, select
**Open in Browser**, then select **Connect**. Keep the port private.

Upload the September PDK archive into the repository workspace with the
filename `SCL 1.2 µm PDK.zip`. In the Codespaces terminal:

```bash
cd /workspaces/vsd-fpga-scl1d
make install-pdk ARCHIVE="$PWD/SCL 1.2 µm PDK.zip"
make doctor
make inspect
make run-2x2
```

After OpenFPGA reports `Finish execution with 0 errors`, open the
architectural fabric diagram on the noVNC desktop:

```bash
export DISPLAY=:1
ristretto results/2x2/fabric_arch.png &
```

The diagram shows the logical CLB grid and I/O sites. The generated
structural Verilog is in `results/2x2/SRC/`; bitstreams are in
`results/2x2/`.

## View the supplied 5 mm padframe separately

```bash
export DISPLAY=:1
tech="$SCL1D_PDK_ROOT/open_source_scl_c1d/open_pdks/sclc1d/libs.tech/klayout/tech"
frame="$SCL1D_PDK_ROOT/padframe/PadFrame_C1D/pad_frame_gds/frame5mmx5mm.gds"
klayout -nn "$tech/scl_c1d.lyt" -l "$tech/scl_c1d.lyp" "$frame" &
```

This opens the PDK's padframe GDS. It does **not** show the FPGA placed
inside the padframe. The OpenFPGA run currently produces Verilog and
bitstreams, not a physically placed and routed FPGA GDS.

## Preview or generate another size

Existing fixed layouts in `openfpga/arch/vpr_arch_2x2.xml` are `2x2`,
`4x4`, and `20x10`.

Preview the 4×4 logical grid without running OpenFPGA:

```bash
make fabric-diagram FABRIC_SIZE=4x4
ristretto results/4x4/fabric_arch.png &
```

Request a full OpenFPGA generation run for that device:

```bash
make run-fabric FABRIC_SIZE=4x4
```

The script passes `--device 4x4` to VPR and writes outputs to
`results/4x4/`. **Only the 2×2 OpenFPGA run has previously completed.**
The larger runs require validation in a new Codespace.

## Add a different size

For example, to add a 3×3 CLB array, place this element inside `<layout>`
in `openfpga/arch/vpr_arch_2x2.xml`:

```xml
<fixed_layout name="3x3" width="5" height="5">
  <perimeter type="io" priority="100" />
  <corners type="EMPTY" priority="101" />
  <fill type="clb" priority="10" />
</fixed_layout>
```

The total XML width and height are the desired CLB counts **plus two**
for the perimeter I/O ring. Then run:

```bash
make fabric-diagram FABRIC_SIZE=3x3
make run-fabric FABRIC_SIZE=3x3
```

A size-only change reuses `openfpga/arch/vsd_openfpga_arch_scl1d.xml`
when the CLB, I/O site, routing segments and programming architecture
stay the same. If those resources change, update both architecture XMLs
and the corresponding wrapper RTL.

The current AND2 BLIF is only a small test design. A larger fabric
generated with AND2 is mostly unused. To test another design, update
the BLIF, Verilog and activity-file paths in `scripts/run_2x2.sh`.

With the current empty-corner I/O ring, an N×M array provides
`2N + 2M` logical I/O sites: 2×2 has 8, 4×4 has 16, and 20×10 has 60.
These are not bonded pads. The September 5 mm padframe has 44 signal
pads. Physical fit, routing, power, timing, DRC and LVS need a
separate physical-design flow.
