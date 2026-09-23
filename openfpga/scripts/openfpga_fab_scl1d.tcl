# Generation-0 SCL1D OpenFPGA sequence. Paths are relative.
vpr ${VPR_ARCH_FILE} ${VPR_TESTBENCH_BLIF} --clock_modeling route --route_chan_width ${OPENFPGA_VPR_ROUTE_CHAN_WIDTH}
read_openfpga_arch -f ${OPENFPGA_ARCH_FILE}
read_openfpga_simulation_setting -f ${OPENFPGA_SIM_SETTING_FILE}
link_openfpga_arch --activity_file ${ACTIVITY_FILE} --sort_gsb_chan_node_in_edges
check_netlist_naming_conflict --fix --report ${OPENFPGA_OUTPUT_DIR}/netlist_renaming.xml
pb_pin_fixup
lut_truth_table_fixup
build_fabric --compress_routing --duplicate_grid_pin
repack
build_architecture_bitstream --write_file ${OPENFPGA_OUTPUT_DIR}/fabric_independent_bitstream.xml
build_fabric_bitstream
write_fabric_bitstream --format plain_text --file ${OPENFPGA_OUTPUT_DIR}/fabric_bitstream.bit
write_fabric_bitstream --format xml --file ${OPENFPGA_OUTPUT_DIR}/fabric_bitstream.xml
write_fabric_verilog --file ${OPENFPGA_OUTPUT_DIR}/SRC --explicit_port_mapping --include_timing --include_signal_init --support_icarus_simulator --print_user_defined_template
write_verilog_testbench --file ${OPENFPGA_OUTPUT_DIR}/SRC --reference_benchmark_file_path ${VPR_TESTBENCH_VERILOG} --print_top_testbench --print_preconfig_top_testbench --print_simulation_ini ${OPENFPGA_OUTPUT_DIR}/simulation_deck.ini --explicit_port_mapping
write_pnr_sdc --file ${OPENFPGA_OUTPUT_DIR}/SDC
write_analysis_sdc --file ${OPENFPGA_OUTPUT_DIR}/SDC_analysis
exit
