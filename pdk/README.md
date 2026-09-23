# SCL1D external PDK contract

Set `SCL1D_PDK_ROOT` to the extracted digital C1D payload root. The expected subtree is:

```text
$SCL1D_PDK_ROOT/open_source_scl_c1d/open_pdks/sclc1d/libs.ref/digital_c1d/
  lef/{tech_c1d.lef,core_c1d.lef,io_c1d.lef,corner_c1d.lef}
  lib/{nldm_tt_27_1p5.lib,nldm_ff_m25_1p55.lib,nldm_ss_125_2p45.lib}
  verilog/c1d.v
  cdl/core_iolib_c1d.cdl
  gds/{core_c1d.gds,io_c1d.gds}
```

The repository does not include the PDK archive. `scripts/install-scl1d-pdk.sh` accepts the complete SCL archive and finds this subtree automatically.
