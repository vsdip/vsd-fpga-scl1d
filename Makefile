SHELL := /usr/bin/env bash
ROOT := $(CURDIR)
.PHONY: doctor install-pdk inspect openfpga-shell run-2x2 clean
doctor:
	bash scripts/codespace_doctor.sh
install-pdk:
	bash scripts/install-scl1d-pdk.sh "$(ARCHIVE)"
inspect:
	python3 scripts/inspect_scl1d.py --pdk-root "$${SCL1D_PDK_ROOT:-$(ROOT)/pdk/local}" --out docs/PDK_INVENTORY.md
openfpga-shell:
	bash scripts/openfpga_shell.sh
run-2x2:
	bash scripts/run_2x2.sh
clean:
	find results -mindepth 1 -maxdepth 1 ! -name .gitkeep -exec rm -rf {} +
