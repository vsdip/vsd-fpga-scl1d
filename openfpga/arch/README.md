# SCL1D architecture inputs

Commit the validated SCL-specific VPR/OpenFPGA XMLs here:

- `vpr_arch_2x2.xml`: 2×2 fixed layout, 32 LUT4s, 64 user FFs, W=20, L1/L2, 8 GPIO.
- `vsd_openfpga_arch_scl1d.xml`: SCL circuit-library bindings.
- `scl1d_simulation_setting.xml`: simulator timing and include paths.

The architecture must bind physical models to the canonical cells in the C1D digital payload. Keep the following wrappers in `rtl/`: `DFFL11` scan FF, `DFCL11` user FF where reset is needed, `MX2101` routing mux, `DELBUF`/`INVR01` buffers, and an explicit `in/out/oeb` GPIO wrapper. Do not copy Sky130 or Caravel names into these files.
