# Copyright 2024 NXP
#
# SPDX-License-Identifier: BSD-3-Clause


# NXP i.MX Security Middleware Library


imx_smw:
ifeq ($(CONFIG_SMW),y)
	@[ $(SOCFAMILY) != IMX ] && exit || \
	 $(call repo-mngr,fetch,imx_smw,apps/security) && \
	 if [ ! -f $(DESTDIR)/usr/lib/libteec.so ]; then \
	     CONFIG_OPTEE=y bld optee_client -r $(DISTROTYPE):$(DISTROVARIANT) -a $(DESTARCH); \
	 fi && \
	 $(call fbprint_b,"imx_smw") && \
	 cd $(SECDIR)/imx_smw && \
	 export CC="$(CROSS_COMPILE)gcc --sysroot=$(RFSDIR)" && \
	 mkdir -p build_$(DISTROTYPE)_$(ARCH) && \
	 cmake  -S $(SECDIR)/imx_smw \
		-B build_$(DISTROTYPE)_$(ARCH) \
		-DCMAKE_BUILD_TYPE=release \
		-DTA_DEV_KIT_ROOT=$(DESTDIR)/usr/include/optee/export-user_ta \
		-DTEEC_ROOT=$(RFSDIR) \
		-DJSONC_ROOT=$(RFSDIR)/usr/lib/aarch64-linux-gnu \
		-DTEE_TA_DESTDIR=/usr/lib $(LOG_MUTE) && \
	 cmake --build build_$(DISTROTYPE)_$(ARCH) -j$(JOBS) --target all $(LOG_MUTE) && \
	 cmake --install build_$(DISTROTYPE)_$(ARCH) --prefix /usr $(LOG_MUTE) && \
	 $(call fbprint_d,"imx_smw")
endif
