# vsd-fpga-scl1d

Generate and view an FPGA fabric with OpenFPGA in GitHub Codespaces.

## Start

Create a Codespace from this repository. The VPR GUI installs automatically during Codespace creation.

Upload `SCL 1.2 µm PDK.zip` to the repository root, then run:

```bash
cd /workspaces/vsd-fpga-scl1d
make install-pdk ARCHIVE="$PWD/SCL 1.2 µm PDK.zip"
make doctor
```

## Generate the existing 2x2 fabric

```bash
make run-2x2
make view-fabric
```

Open forwarded **port 6080** to see the VPR window in noVNC. Generated Verilog, bitstreams, logs, and diagrams are in `results/2x2/`.

## Generate another existing size

The architecture already defines **2x2**, **4x4**, and **20x10** layouts:

```bash
make run-fabric FABRIC_SIZE=4x4
make view-fabric FABRIC_SIZE=4x4
```

For 20x10:

```bash
make run-fabric FABRIC_SIZE=20x10
make view-fabric FABRIC_SIZE=20x10
```

A 20x10 layout contains 200 CLB positions, with up to 1,600 LUT4 positions. Its generated files are in `results/20x10/`.

## Add a new size

Add a `fixed_layout` inside the `<layout>` section of `openfpga/arch/vpr_arch_2x2.xml`. For an 8x6 CLB fabric, include the one-tile I/O perimeter in the width and height:

```xml
<fixed_layout name="8x6" width="10" height="8">
  <perimeter type="io" priority="100" />
  <corners type="EMPTY" priority="101" />
  <fill type="clb" priority="10" />
</fixed_layout>
```

Then run:

```bash
make run-fabric FABRIC_SIZE=8x6
make view-fabric FABRIC_SIZE=8x6
```

These commands generate a logical FPGA fabric and its VPR view. They do not produce a placed-and-routed GDS chip.
