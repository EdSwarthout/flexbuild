# Copyright 2025 NXP
#
# SPDX-License-Identifier: BSD-3-Clause

# Coral Gasket Driver
#
# The Coral Gasket Driver allows usage of the [Coral EdgeTPU](https://coral.ai/) on Linux systems. The driver contains two modules:
#
# * Gasket: Gasket (Google ASIC Software, Kernel Extensions, and Tools) is a top level driver for lightweight communication with Google ASICs.
# * Apex: Apex refers to the [EdgeTPU v1](https://coral.ai/technology)

gasket_module:
	$(call fbprint_n,"Fetching gasket_driver") && \
	$(call download_repo,gasket_driver,linux) && \
	$(call patch_apply,gasket_driver,linux) && \
	$(call download_repo,linux,linux) && \
	if [ ! -d $(FBOUTDIR)/linux/kernel/$(DESTARCH)/$(SOCFAMILY) ]; then \
		bld linux -m $(MACHINE); \
	fi && \
	opdir=$(KERNEL_OUTPUT_PATH)/$(KERNEL_BRANCH) && mkdir -p $$opdir && \
	\
	cd $(PKGDIR)/linux/gasket_driver/src && \
	$(call fbprint_b,"gasket_driver") && \
	$(MAKE) KERNEL_DIR=$(KERNEL_PATH) O=$$opdir && \
	$(MAKE) KERNEL_DIR=$(KERNEL_PATH) O=$$opdir INSTALL_MOD_PATH=$$opdir/tmp modules_install && \
	$(call fbprint_d,"gasket_driver")
