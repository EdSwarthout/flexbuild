# Copyright 2023-2024 NXP
#
# SPDX-License-Identifier: BSD-3-Clause

# vkmark is an extensible Vulkan benchmarking suite with targeted, configurable scenes

# DEPENDS: libvulkan1 libassimp-dev libglm-dev

repo_vkmark_url=https://github.com/vkmark/vkmark.git
repo_vkmark_commit=ab6e6f3407

vkmark:
ifeq ($(CONFIG_VKMARK),y)
	@[ $(DISTROVARIANT) != desktop ] && exit || \
	 $(call repo-mngr,fetch,vkmark,apps/graphics) && \
	 bld vulkan_headers -r $(DISTROTYPE):$(DISTROVARIANT) -a $(DESTARCH); \
	 $(call fbprint_b,"vkmark") && \
	 cd $(GRAPHICSDIR)/vkmark && \
	 if [ ! -f .patchdone ]; then \
	     git am $(FBDIR)/patch/vkmark/*.patch $(LOG_MUTE) && touch .patchdone; \
	 fi && \
	 [ `hostname` = fbdebian ] && export PKG_CONFIG_SYSROOT_DIR="" || true && \
	 sed -e 's%@TARGET_CROSS@%$(CROSS_COMPILE)%g' -e 's%@STAGING_DIR@%$(RFSDIR)%g' \
	     -e 's%@DESTDIR@%$(DESTDIR)%g' $(FBDIR)/src/system/meson.cross > meson.cross && \
	 sudo rm -f $(RFSDIR)/usr/lib/aarch64-linux-gnu/libvulkan.so && \
	 sudo cp -fa $(DESTDIR)/usr/lib/{libvulkan*.so*,libSPIRV_viv.so,libGLSLC.so} $(RFSDIR)/usr/lib && \
	 sudo cp -fr $(DESTDIR)/usr/include/vulkan $(RFSDIR)/usr/include/ && \
	 meson setup build_$(DISTROTYPE)_$(ARCH) \
		--cross-file=meson.cross \
		--prefix=/usr \
		--buildtype=release \
		-Dc_args="-I$(DESTDIR)/usr/include/vulkan" $(LOG_MUTE) && \
	 ninja -j$(JOBS) install -C build_$(DISTROTYPE)_$(ARCH) $(LOG_MUTE) && \
	 $(call fbprint_d,"vkmark")
endif
