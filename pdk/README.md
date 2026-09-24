# SCL1D external PDK contract

Set `SCL1D_PDK_ROOT` to the extracted digital C1D payload root. The expected subtree is:

```text
$SCL1D_PDK_ROOT/open_source_scl_c1d/open_pdks/sclc1d/libs.ref/digital_c1d/
  lef/{tech_c1d.lef,core_c1d.lef,io_c1d.lef,corner_c1d.lef}
  lib/{c1d_core_typ.lib,c1d_core_min.lib,c1d_core_max.lib}
  lib/{scl1u_pads_typ.lib,scl1u_pads_min.lib,scl1u_pads_max.lib}
  verilog/c1d.v
  cdl/core_iolib_c1d.cdl
  gds/{core_c1d.gds,io_c1d.gds}

$SCL1D_PDK_ROOT/padframe/PadFrame_C1D/
  pad_frame_gds/frame{1,2,3,4,5}mmx{1,2,3,4,5}mm.gds
  pad_frame_cdl/frame{1,2,3,4,5}mmx{1,2,3,4,5}mm.cdl
  klayout/gds/io_pad_c1d.gds
```

The repository does not include the PDK archive. `scripts/install-scl1d-pdk.sh` accepts the complete SCL archive and finds this subtree automatically.
