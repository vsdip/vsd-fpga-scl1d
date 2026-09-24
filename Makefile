SHELL := /usr/bin/env bash
ROOT := $(CURDIR)
.PHONY: doctor install-pdk inspect openfpga-shell run-2x2 run-fabric fabric-diagram clean

FABRIC_SIZE ?= 2x2

doctor:
	bash scripts/codespace_doctor.sh

install-pdk:
	bash scripts/install-scl1d-pdk.sh "$(ARCHIVE)"

inspect:
	python3 scripts/inspect_scl1d.py --pdk-root "$${SCL1D_PDK_ROOT:-$(ROOT)/pdk/local}" --out docs/PDK_INVENTORY.md

openfpga-shell:
	bash scripts/openfpga_shell.sh

run-2x2:
	FABRIC_SIZE=2x2 bash scripts/run_2x2.sh

run-fabric:
	FABRIC_SIZE="$(FABRIC_SIZE)" bash scripts/run_2x2.sh

fabric-diagram:
	python3 scripts/render_fabric.py --arch openfpga/arch/vpr_arch_2x2.xml --device "$(FABRIC_SIZE)" --out "results/$(FABRIC_SIZE)/fabric_arch.svg"
	rsvg-convert -o "results/$(FABRIC_SIZE)/fabric_arch.png" "results/$(FABRIC_SIZE)/fabric_arch.svg"

clean:
	find results -mindepth 1 -maxdepth 1 ! -name .gitkeep -exec rm -rf {} +
