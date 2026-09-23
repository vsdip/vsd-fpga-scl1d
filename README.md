# vsd-fpga-scl1d

A small OpenFPGA fabric targeting the SCL 1.2 µm C1D digital PDK. The first milestone is a 2×2 CLB fabric, generated and tested in GitHub Codespaces.

**Current result:** The AND2 benchmark completed VPR routing and the OpenFPGA generation flow. OpenFPGA wrote fabric Verilog, bitstreams and SDC files, then reported `Finish execution with 0 errors`. Physical placement, metal routing, DRC/LVS and padframe integration are still to be done.

The SCL PDK is installed locally. It is not included in this repository.

## Fabric defined by the current architecture

| Resource | 2×2 architecture |
|---|---:|
| CLBs | 4 |
| FLEs | 32: eight per CLB |
| LUT4 positions | 32: one per FLE |
| User flip-flop positions | Up to 64: two per FLE |
| Perimeter GPIO positions | 8 |

The VPR architecture defines L1, L2 and L4 routing segments. The current OpenFPGA script requests **VPR channel width 100**; this is a logical routing setting, not a measured number of physical metal tracks. One completed generation run reported **2,232 fabric bitstream bits**. Recheck that count whenever the architecture changes.

The simulation settings file specifies 1 MHz as an operating frequency. This is a flow setting, **not** a verified maximum clock frequency for silicon.

## Start a Codespace

Create a Codespace from [vsdip/vsd-fpga-scl1d](https://github.com/vsdip/vsd-fpga-scl1d).

The repository’s `.devcontainer/devcontainer.json` builds `.devcontainer/Dockerfile` from the OpenFPGA image and runs as `openfpga_user`. The Dockerfile installs development utilities, including `unzip` and `sudo`. A fresh Codespace still needs a local copy of the SCL PDK.

Use a terminal in the repository root:

```bash
cd /workspaces/vsd-fpga-scl1d
```

Do not run `make doctor` until the PDK installation below is complete.

## Install the SCL PDK

Obtain the SCL 1.2 µm C1D PDK through your authorised source. Upload the ZIP **into the Codespace workspace**, rather than committing it to GitHub.

If the downloaded filename contains `µ` or other special characters, give it an ASCII filename:

```bash
cd /workspaces/vsd-fpga-scl1d

PDK_ZIP="$(find . -maxdepth 1 -type f -name '*PDK.zip' -print -quit)"
test -n "$PDK_ZIP" || { echo "PDK ZIP not found in repository root"; exit 1; }
cp -- "$PDK_ZIP" ./SCL_PDK.zip

make install-pdk ARCHIVE="$PWD/SCL_PDK.zip"
export SCL1D_PDK_ROOT="$PWD/pdk/local"
```

If your archive is already named `SCL_PDK.zip`, run only the `make install-pdk` and `export` commands.

The installer unpacks the nested digital payload under:

```text
pdk/local/open_source_scl_c1d/open_pdks/sclc1d/libs.ref/digital_c1d/
```

That directory should contain the core and I/O LEFs, Liberty files, `c1d.v`, CDL and GDS cell libraries. `pdk/local/` and ZIP files are excluded by `.gitignore`.

## Check the installation

```bash
make doctor
make inspect
bash scripts/openfpga_shell.sh --help
```

In the tested Codespace, `make doctor` found:

```text
OpenFPGA: /opt/openfpga/build/openfpga/openfpga
VPR: VPR FPGA Placement and Routing.
Icarus: Icarus Verilog version 11.0
doctor: PASS
```

The executable path may differ in another image. The repository wrapper locates it; use `bash scripts/openfpga_shell.sh`, not an assumed `openfpga_shell` command.

`make inspect` writes a PDK inventory to `docs/PDK_INVENTORY.md`. Review that file before committing it, since running the command updates the inventory with paths from your current Codespace.

## Generate the 2×2 fabric

The required VPR architecture, OpenFPGA architecture, simulation settings, AND2 benchmark and SCL primitive wrappers are committed to the repository.

Run:

```bash
make run-2x2
```

Look for **`Finish execution with 0 errors`** at the end of the OpenFPGA output. Key generated files are under `results/2x2/`:

```text
results/2x2/
├── fabric_bitstream.bit
├── fabric_bitstream.xml
├── fabric_independent_bitstream.xml
├── SRC/                 # Generated structural fabric Verilog
├── SDC/                 # Physical-design constraints
└── SDC_analysis/        # Analysis constraints
```

The script runs VPR pack/place/route, links the OpenFPGA architecture, builds the fabric, generates bitstreams and writes Verilog and SDC files. **It does not currently generate or run a Verilog testbench.**

`results/` is excluded by `.gitignore`. A new Codespace must run the flow again to recreate these files.

## What the SCL mapping currently covers

`rtl/vsd_scl_primitives.v` defines wrappers using these SCL digital cells:

| Function | Cell used by the wrapper |
|---|---|
| Configuration flip-flop | `DFFL11` |
| User flip-flop with clear and scan selection | `DFCL11` and `MX2101` |
| Routing mux | `MX2101` |
| Inverter | `INVR01` or `INVR02` |
| Buffer | `DELBUF` |
| OR gate | `OR2101` |

The current GPIO wrapper is a **functional simulation model** with temporary bidirectional behavior. It is not a placed SCL I/O pad or a finished padframe.

**Before treating the generated Verilog as physically mapped SCL hardware:** the committed OpenFPGA architecture XML refers to `rtl/primitives/vsd_scl_primitives.v`, while the repository currently stores the wrapper at `rtl/vsd_scl_primitives.v`. Its technology section also references a PTM 45 nm model. These references need correction and SCL-specific validation. Successful fabric generation alone does not establish correct SCL timing or physical cell mapping.

## Viewing the result

The OpenFPGA result is **Verilog and bitstream data, not a routed GDS layout**. Inspect generated structural Verilog under `results/2x2/SRC/`.

The PDK’s `core_c1d.gds` and `io_c1d.gds` show individual SCL library cells. Opening either in KLayout through a Codespace desktop or noVNC session displays those library cells; it does **not** display the generated FPGA fabric. A view of the full fabric requires synthesis, physical placement and routing, and GDS export.

KLayout and noVNC are not installed by this repository’s current Dockerfile. Install and configure a desktop viewer separately if needed.

## 5 mm × 5 mm target

The proposed padframe outline is 5 mm × 5 mm. The SCL pad cells occupy substantial perimeter space, so **2×2 is the first physical closure target**. The present VPR routing success does not prove that the design fits or routes on the PDK’s physical metal layers.

Before selecting a larger fabric, complete:

1. Functional simulation with the SCL models.
2. Synthesis and cell mapping against SCL Liberty and Verilog.
3. Floorplanning with the intended SCL I/O cells, power pads and core boundary.
4. Placement, clock and power planning, and detailed routing using the available metal layers.
5. DRC, LVS and timing checks on the resulting layout.

Consider 4×4 only after those checks pass for 2×2.

## Troubleshooting

### `make install-pdk` cannot find the archive

Put the ZIP in the Codespace workspace and pass its full path in quotes:

```bash
make install-pdk ARCHIVE="$PWD/SCL_PDK.zip"
```

### `make doctor` reports missing PDK files

Recheck that installation completed and that the root points to `pdk/local`:

```bash
export SCL1D_PDK_ROOT="$PWD/pdk/local"
make doctor
```

### `make doctor` reports OpenFPGA missing

Check the binary location:

```bash
find /opt/openfpga -maxdepth 4 -type f -executable \
  \( -name openfpga -o -name openfpga_shell \) -print
```

Then check that the Codespace was built from this repository’s `.devcontainer` configuration.

### The Codespace opens in recovery mode

Inspect the Codespace creation log. The committed configuration builds `.devcontainer/Dockerfile`, sets `remoteUser` to `openfpga_user`, and uses a `postCreateCommand` that only prints a message. After fixing a configuration error on GitHub, rebuild the container.

### `sudo` is unavailable

The repository Dockerfile installs `sudo` for `openfpga_user`. Rebuild the Codespace from the current `.devcontainer` files. Removing an APT lock file will not fix a container that was built without `sudo`.

## Repository scope

The repository tracks the OpenFPGA/VPR inputs, primitive wrappers, benchmarks, scripts and documentation. It does not redistribute the SCL PDK or commit generated `results/` files. A CPU, BRAM, DSP, production padframe and signoff-ready physical flow are outside the current 2×2 generation milestone.
