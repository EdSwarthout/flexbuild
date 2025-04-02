# Copyright 2025 NXP
#
# SPDX-License-Identifier: BSD-3-Clause

#	@$(call repo-mngr,fetch,gasket_module,linux) && \
#	 $(call repo-mngr,fetch,$(KERNEL_TREE),linux) && \



gasket_module:
	 curbrch=`cd $(KERNEL_PATH) && git branch | grep ^* | cut -d' ' -f2` && \
	 opdir=$(KERNEL_OUTPUT_PATH)/$$curbrch && mkdir -p $$opdir/tmp && \
	 cd $(PKGDIR)/linux/gasket-driver/src && \
	 $(call fbprint_b,"gasket driver") && \
	 $(MAKE) KERNEL_DIR=$(KERNEL_PATH) O=$$opdir && \
	 $(call fbprint_b,"gasket driver to $$opdir/tmp modules_install") && \
	 $(MAKE) KERNEL_DIR=$(KERNEL_PATH) O=$$opdir INSTALL_MOD_PATH=$$opdir/tmp modules_install && \
	 $(call fbprint_d,"gasket driver module")
