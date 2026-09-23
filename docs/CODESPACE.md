# Codespace setup

1. Create a Codespace from `github.com/vsdip/vsd-fpga-scl1d` on `main`.
2. Obtain the SCL C1D PDK through the authorised SCL/eChipHub route. Do not commit the PDK to GitHub.
3. Upload the archive into the Codespace, then run:

```bash
# Use an ASCII alias; this avoids locale/encoding issues in wget filenames.
PDK_ZIP="$(find . -maxdepth 1 -type f -name '*PDK.zip' -print -quit)"
test -n "$PDK_ZIP"
cp -- "$PDK_ZIP" ./SCL_PDK.zip
make install-pdk ARCHIVE="$PWD/SCL_PDK.zip"
export SCL1D_PDK_ROOT="$PWD/pdk/local"
make doctor
make inspect
```

If the Codespace enters recovery mode, check `.devcontainer/devcontainer.json`
before rebuilding. The OpenFPGA image is prebuilt, but it must not be forced to
run as a guessed `openfpga` user; keep `overrideCommand: true` and let the image
choose its default user. Also keep `postCreateCommand` non-failing until the PDK
has been installed.

The default devcontainer uses the OpenFPGA-maintained prebuilt image. For native ARM64 or a pinned local build:

```bash
bash scripts/install-openfpga-native.sh
source openfpga/OpenFPGA/openfpga.sh
```

The project is PDK-aware but does not redistribute SCL files. The generator uses SCL cells as external Verilog, LEF, Liberty, CDL and GDS assets.

## Build sequence

```text
VPR architecture + BLIF
  -> VPR pack/place/route
  -> read_openfpga_arch
  -> link_openfpga_arch
  -> build_fabric
  -> repack
  -> build_architecture_bitstream
  -> build_fabric_bitstream
  -> write_fabric_verilog / write_verilog_testbench
  -> write_pnr_sdc / write_analysis_sdc
```

Run `make run-2x2` after the SCL-specific architecture XML and primitive wrappers are committed under `openfpga/arch/` and `rtl/`.
