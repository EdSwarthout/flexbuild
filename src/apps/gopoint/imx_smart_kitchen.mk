# Copyright 2024-2025 NXP
#
# SPDX-License-Identifier: BSD-3-Clause

GPNT_APPS_FOLDER = /opt/gopoint-apps
SMART_KITCHEN_DIR = ${GPNT_APPS_FOLDER}/scripts/multimedia/smart-kitchen
#POSIX_IPC_PKG = http://semanchuk.com/philip/posix_ipc/releases/posix_ipc-1.1.1.tar.gz

imx_smart_kitchen:
	@[ $(SOCFAMILY) != IMX -o $(DISTROVARIANT) != desktop ] && exit || \
	 $(call repo-mngr,fetch,imx_smart_kitchen,apps/gopoint) && \
#	 if  [ ! -f $(DESTDIR)/usr/lib/nxp-afe/libdummyimpl.so.1.0 ]; then \
#	     bld nxp_afe -r $(DISTROTYPE):$(DISTROVARIANT); \
#	 fi && \
#	 if [[ ! -f $(DESTDIR)/usr/lib/nxp-afe/libvoiceseekerlight.so.2.0 ]]; then \
#	     bld imx_voiceui -r $(DISTROTYPE):$(DISTROVARIANT); \
#	 fi && \
#	 \
#	 cd $(GPDIR)/imx_smart_kitchen && \
#	 [ ! -f posix_ipc.tar.gz ] && wget -q $(POSIX_IPC_PKG) -O posix_ipc.tar.gz $(LOG_MUTE) && tar xf posix_ipc.tar.gz || true && \
#	 cd posix_ipc-1.1.1 && export CC="$(CROSS_COMPILE)gcc -DMESSAGE_QUEUE_SUPPORT_EXISTS --sysroot=$(RFSDIR)" && \
#	 python3 setup.py build && python3 setup.py install --prefix=$(DESTDIR)/usr && \
	 \
	 export CC="$(CROSS_COMPILE)gcc --sysroot=$(RFSDIR)" && \
	 export CXX="$(CROSS_COMPILE)g++ --sysroot=$(RFSDIR)" && \
	 $(call fbprint_b,"imx_smart_kitchen") && \
	 cd $(GPDIR)/imx_smart_kitchen && \
	 if [ -d $(FBDIR)/patch/imx_smart_kitchen ] && [ ! -f .patchdone ]; then \
		 git am $(FBDIR)/patch/imx_smart_kitchen/*.patch $(LOG_MUTE) && touch .patchdone; \
	 fi && \
	 sed -i 's|/home/root/.nxp-demo-experience|/opt/gopoint-apps|g' \
	     main.cpp main.cpp misc/scripts/vit-notify/WWCommandNotify && \
	 if [ ! -f lvgl/.patchdone ]; then \
	     cp misc/patches/*.patch lvgl/ && \
	     cp -r wayland-client/* lv_drivers/wayland/ && \
	     cd lvgl && git am *.patch $(LOG_MUTE) && touch .patchdone && cd ..; \
	 fi && \
	 rm -rf smart-kitchen-deploy && \
	 $(MAKE) -j$(JOBS) $(LOG_MUTE) && \
	 install -d -m 755 $(DESTDIR)$(SMART_KITCHEN_DIR) && \
	 cp -rf smart-kitchen-deploy/* $(DESTDIR)$(SMART_KITCHEN_DIR) && \
	 $(call fbprint_d,"imx_smart_kitchen")
