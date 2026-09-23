# vsd-fpga-scl1d

OpenFPGA-based Generation-0 embedded FPGA fabric for the SCL 1.2 Âµm C1D process.

This repository contains the OpenFPGA/VPR flow, SCL-aware documentation, test
benchmarks and automation scripts. The SCL PDK itself is not redistributed or
committed to GitHub. Obtain it through the authorised SCL/eChipHub route and
install it locally inside the Codespace.

## Current status

The first recommended silicon target is a validated 2Ã—2 fabric:

- 4 CLBs
- 16 FLEs
- 32 LUT4s
- 64 user flip-flops
- 20 routing tracks
- L1/L2 routing
- 8 GPIO
- approximately 2,321 configuration-chain bits
- 5 V operation
- 1 MHz initial user-clock target

This is a qualification target for SCL 1.2 Âµm. Attempt a 4Ã—4 fabric only after
the 2Ã—2 fabric passes generation, simulation, synthesis, placement, routing,
DRC/LVS and padframe integration. An 8Ã—8 fabric is not recommended as the first
fabric for a 5 mm Ã— 5 mm padframe.

## GitHub Codespaces setup

The devcontainer uses the OpenFPGA-maintained prebuilt image. The image already
contains VPR and Icarus. The repository scripts resolve the OpenFPGA executable
from the image layout; users should not run the native OpenFPGA build in the
normal Codespace.

Create a Codespace from:

```text
https://github.com/vsdip/vsd-fpga-scl1d
```

The container configuration must contain:

```json
{
  "name": "VSD FPGA SCL1D",
  "image": "ghcr.io/lnis-uofu/openfpga-master:latest",
  "overrideCommand": true,
  "containerEnv": {
    "VSD_FPGA_ROOT": "${containerWorkspaceFolder}",
    "SCL1D_PDK_ROOT": "${containerWorkspaceFolder}/pdk/local"
  },
  "postCreateCommand": "echo 'Codespace ready. Install the SCL PDK, then run: make doctor'"
}
```

Do not force the image to run as `remoteUser: openfpga`. Codespaces may provide
the image's valid runtime user automatically.

## Install the SCL PDK

Keep the downloaded archive outside Git. The `.gitignore` file excludes ZIP and
TAR archives, and `pdk/local/` is also excluded.

From the repository root:

```bash
cd /workspaces/vsd-fpga-scl1d

# Find the downloaded archive and create an ASCII-safe filename.
PDK_ZIP="$(find . -maxdepth 1 -type f -name '*PDK.zip' -print -quit)"
test -n "$PDK_ZIP"
cp -- "$PDK_ZIP" ./SCL_PDK.zip

make install-pdk ARCHIVE="$PWD/SCL_PDK.zip"
export SCL1D_PDK_ROOT="$PWD/pdk/local"
```

The installer accepts the complete SCL archive, including the nested digital
payload, and installs:

```text
pdk/local/open_source_scl_c1d/open_pdks/sclc1d/libs.ref/digital_c1d/
â”œâ”€â”€ lef/{tech_c1d.lef,core_c1d.lef,io_c1d.lef,corner_c1d.lef}
â”œâ”€â”€ lib/{nldm_tt_27_1p5.lib,nldm_ff_m25_1p55.lib,nldm_ss_125_2p45.lib}
â”œâ”€â”€ verilog/c1d.v
â”œâ”€â”€ cdl/core_iolib_c1d.cdl
â””â”€â”€ gds/{core_c1d.gds,io_c1d.gds}
```

## Verify the environment

Run:

```bash
make doctor
```

Expected checks:

```text
OpenFPGA: /opt/openfpga/openfpga/openfpga
VPR: VPR FPGA Placement and Routing.
Icarus: Icarus Verilog version 11.0
doctor: PASS
```

If the OpenFPGA path needs to be inspected manually:

```bash
find /opt/openfpga -maxdepth 4 -type f -executable \
  \( -name openfpga -o -name openfpga_shell \) -print
```

The repository uses `scripts/openfpga_tool.sh` to locate the executable. Do not
assume that `openfpga_shell` is a standalone command in the prebuilt image.

Generate the PDK inventory with:

```bash
make inspect
```

The report is written to `docs/PDK_INVENTORY.md`.

## OpenFPGA command wrapper

Use the repository wrapper rather than calling an assumed binary name:

```bash
bash scripts/openfpga_shell.sh --help
```

It supports both the prebuilt Codespaces image and a native OpenFPGA checkout.
The native installer is intended for ARM64 or non-Codespaces environments only:

```bash
bash scripts/install-openfpga-native.sh
source openfpga/OpenFPGA/openfpga.sh
```

## 2Ã—2 fabric flow

Before running the fabric flow, the following validated project inputs must be
present:

```text
openfpga/arch/vpr_arch_2x2.xml
openfpga/arch/vsd_openfpga_arch_scl1d.xml
openfpga/arch/scl1d_simulation_setting.xml       # optional
rtl/<validated SCL primitive wrappers>.v
```

The architecture files must bind the SCL C1D cells to the OpenFPGA circuit
models. Do not replace them with Sky130 or Caravel cell names.

Once those files and wrappers are committed:

```bash
make run-2x2
```

The flow is:

```text
VPR architecture + BLIF
  â†’ VPR pack/place/route
  â†’ OpenFPGA architecture linking
  â†’ fabric generation
  â†’ configuration bitstream generation
  â†’ structural Verilog generation
  â†’ simulation testbench generation
```

Results are written under `results/2x2/`.

## SCL cell mapping

| Fabric function | SCL cell or implementation |
|---|---|
| Configuration-memory scan FF | `DFFL11` |
| User logic FF | `DFCL11` or `DFFL11` |
| 2:1 routing mux | `MX2101` |
| 4:1 mux tree | `MX4122` or `MX2101` tree |
| Local buffer/inverter | `DELBUF`, `INVR01`â€“`INVR06` |
| Clock fanout | `CDRI01`/`CDRI02` with constrained clock routing |
| Input/output GPIO | Explicit `in`, `out`, `oeb` wrapper around SCL pad cells |
| Core power ties | `VDDCON`, `VSSCON` |
| Row closure | `FILLER1`â€“`FILLER5` |

Validate every wrapper against the SCL Verilog, Liberty, LEF, CDL and GDS views.
Pay particular attention to pin order and active-low control signals.

## 5 mm Ã— 5 mm padframe guidance

The SCL I/O cells are approximately 305 Âµm deep and approximately 200â€“286 Âµm
wide. The pad ring therefore consumes a substantial portion of the outline.
The 2Ã—2 fabric is the correct first closure target. Fabric size must ultimately
be decided by OpenROAD placement/routing, power straps, configuration-chain
length, clock fanout, antenna checks, DRC/LVS and the final pad-ring DEFâ€”not by
standard-cell count alone.

## Repository boundaries

This repository covers:

- OpenFPGA/VPR architecture inputs
- SCL primitive wrappers
- generated fabric Verilog and bitstreams
- small functional benchmarks
- PDK inspection and Codespace automation
- the path to synthesis, placement, routing and GDS

It does not redistribute the SCL PDK and does not yet include a CPU, bus, BRAM,
DSP, production padframe, or signoff timing characterization.

## Troubleshooting

### `make doctor` reports OpenFPGA missing

Check the executable location:

```bash
find /opt/openfpga -maxdepth 4 -type f -executable \
  \( -name openfpga -o -name openfpga_shell \) -print
```

Then make sure the repository contains the updated `scripts/openfpga_tool.sh`,
`scripts/openfpga_shell.sh` and `scripts/codespace_doctor.sh` files.

### Codespace enters recovery mode

Check that:

- `remoteUser: openfpga` is absent;
- `overrideCommand` is `true`;
- `postCreateCommand` is only an `echo` command;
- `make doctor` is not executed automatically before the PDK is installed.

Commit and push the configuration, then run **Codespaces: Rebuild Container**.

### `make run-2x2` reports missing XML files

The validated architecture XMLs and SCL primitive wrappers have not yet been
committed. Add those files from the validated 2Ã—2 OpenFPGA run before attempting
fabric generation.

## License and PDK boundary

The repository automation is intended for VSD's SCL 1.2 Âµm FPGA development flow.
The SCL PDK remains subject to its own access terms and must be obtained from the
authorised source.
