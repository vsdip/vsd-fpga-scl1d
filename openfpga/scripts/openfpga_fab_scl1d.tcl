# Generation-0 SCL1D OpenFPGA sequence.

vpr $::env(VPR_ARCH_FILE) \
    $::env(VPR_TESTBENCH_BLIF) \
    --clock_modeling route \
    --route_chan_width 100 \
    --absorb_buffer_luts off \
    --skip_sync_clustering_and_routing_results on

read_openfpga_arch -f $::env(OPENFPGA_ARCH_FILE)

read_openfpga_simulation_setting \
    -f $::env(OPENFPGA_SIM_SETTING_FILE)
    
link_openfpga_arch \
    --activity_file $::env(ACTIVITY_FILE)

check_netlist_naming_conflict \
    --fix \
    --report $::env(OPENFPGA_OUTPUT_DIR)/netlist_renaming.xml

pb_pin_fixup
lut_truth_table_fixup

build_fabric \
    --compress_routing \
    --duplicate_grid_pin

repack

build_architecture_bitstream \
    --write_file $::env(OPENFPGA_OUTPUT_DIR)/fabric_independent_bitstream.xml

build_fabric_bitstream

write_fabric_bitstream \
    --format plain_text \
    --file $::env(OPENFPGA_OUTPUT_DIR)/fabric_bitstream.bit

write_fabric_bitstream \
    --format xml \
    --file $::env(OPENFPGA_OUTPUT_DIR)/fabric_bitstream.xml

write_fabric_verilog \
    --file $::env(OPENFPGA_OUTPUT_DIR)/SRC \
    --explicit_port_mapping \
    --include_timing \
    --include_signal_init \
    --support_icarus_simulator \
    --print_user_defined_template


write_pnr_sdc \
    --file $::env(OPENFPGA_OUTPUT_DIR)/SDC

write_analysis_sdc \
    --file $::env(OPENFPGA_OUTPUT_DIR)/SDC_analysis

exit
