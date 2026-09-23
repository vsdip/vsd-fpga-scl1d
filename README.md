# vsd-fpga-scl1d

OpenFPGA-based Generation-0 embedded FPGA fabric for the SCL 1.2 µm C1D process.

This repository contains the OpenFPGA/VPR flow, SCL-aware documentation, test
benchmarks and automation scripts. The SCL PDK itself is not redistributed or
committed to GitHub. Obtain it through the authorised SCL/eChipHub route and
install it locally inside the Codespace.

## Current status

The first recommended silicon target is a validated 2×2 fabric:

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

This is a qualification target for SCL 1.2 µm. Attempt a 4×4 fabric only after
the 2×2 fabric passes generation, simulation, synthesis, placement, routing,
DRC/LVS and padframe integration. An 8×8 fabric is not recommended as the first
fabric for a 5 mm × 5 mm padframe.

## GitHub Codespaces setup

The devcontainer uses the OpenFPGA-maintained prebuilt image. The image already
contains VPR and Icarus. The repository scripts resolve the OpenFPGA executable
from the image layout; users should not run the native OpenFPGA build in the
normal Codespace.

Create a Codespace from:

```text
https://github.com/vsdip/vsd-fpga-scl1d
