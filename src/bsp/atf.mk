#
# Copyright 2018-2024 NXP
#
# SPDX-License-Identifier: BSD-3-Clause
#

# build ATF image for Layerscape and i.MX platforms

bldstr = "BUILD_STRING=$(DEFAULT_REPO_TAG)"

atf:
	@$(call repo-mngr,fetch,atf,bsp) && \
	 $(call repo-mngr,fetch,uboot,bsp) && \
	 $(call repo-mngr,fetch,mbedtls,bsp) && \
	 if [ "$(MACHINE)" = all ]; then $(call fbprint_w,"Please specify '-m <machine>'") && exit 0; fi && \
	 if [ -z "$(BOOTTYPE)" ]; then $(call fbprint_w,"Please specify '-b <boottype>'") && exit 0; fi && \
	 cd $(BSPDIR)/atf && \
	 curbrch=`git branch | grep ^* | cut -d' ' -f2` && \
	 $(call fbprint_b,"ATF $$curbrch for $(MACHINE)") && \
	 $(MAKE) realclean $(LOG_MUTE) && mkdir -p $(FBOUTDIR)/bsp/atf/$(MACHINE); \
	 platform=$(MACHINE); \
	 [ $${platform:0:6} = ls1012 -o $${platform:0:5} = ls104 ] && chassistype=ls104x_1012 || chassistype=ls2088_1088; \
	 if [ "$(SECURE)" = y -a "$(BL33TYPE)" = uboot ]; then \
	     if [ $$chassistype = ls104x_1012 ]; then \
		 rcwbin=`grep ^rcw_$(BOOTTYPE)_sec= $(FBDIR)/configs/board/$(MACHINE).conf | cut -d'"' -f2`; \
	     else \
		 rcwbin=`grep ^rcw_$(BOOTTYPE)= $(FBDIR)/configs/board/$(MACHINE).conf | cut -d'"' -f2`; \
	     fi; \
	     if [ $${MACHINE:0:5} = lx216 ] && [ ! -f $(PKGDIR)/bsp/atf/ddr4_pmu_train_dmem.bin ]; then \
		 bld ddr_phy_bin; \
	     fi && \
	     if [ "$(COT)" = arm-cot -o "$(COT)" = arm-cot-with-verified-boot ]; then \
		 secureopt="TRUSTED_BOARD_BOOT=1 CST_DIR=$(PKGDIR)/apps/security/cst \
			    GENERATE_COT=1 MBEDTLS_DIR=$(PKGDIR)/bsp/mbedtls"; \
		 outputdir="arm-cot"; \
		 mkdir -p $$outputdir build/$$platform/release; \
		 [ -f $$outputdir/rot_key.pem ] && cp -f $$outputdir/*.pem build/$$platform/release/; \
		 if [ "$(COT)" = arm-cot-with-verified-boot ]; then \
		     if [ ! -f keys/dev.key ]; then \
			[ ! -f ~/.rnd ] && cd ~ && openssl rand -writerand .rnd && cd -; \
			mkdir -p keys; openssl genpkey -algorithm RSA -out keys/dev.key -pkeyopt \
					       rsa_keygen_bits:2048 -pkeyopt rsa_keygen_pubexp:65537; \
			openssl req -batch -new -x509 -key keys/dev.key -out keys/dev.crt; \
		     fi; \
		     cp -rf keys/* $(FBOUTDIR)/bsp/atf/$$platform/; \
		     ubootcfg=$${platform}_tfa_verified_boot_defconfig; \
		     bl33=$(FBOUTDIR)/bsp/atf/$$platform/u-boot-combined-dtb.bin; \
		     secext=_sec_verified_boot; \
		 else \
		     ubootcfg=$${platform}_tfa_SECURE_BOOT_defconfig; \
		     bl33=$(FBOUTDIR)/bsp/u-boot/$${platform}/uboot_$${platform}_tfa_SECURE_BOOT.bin; \
		     secext=_sec; \
		 fi; \
		 ubootcfg=$(PKGDIR)/bsp/uboot/configs/$$ubootcfg; \
	     else \
		 secureopt="TRUSTED_BOARD_BOOT=1 CST_DIR=$(PKGDIR)/apps/security/cst"; \
		 outputdir="nxp-cot" && mkdir -p $$outputdir; \
		 ubootcfg=$(PKGDIR)/bsp/uboot/configs/$${platform}_tfa_SECURE_BOOT_defconfig; \
		 bl33=$(FBOUTDIR)/bsp/u-boot/$${platform}/uboot_$${platform}_tfa_SECURE_BOOT.bin; \
		 secext=_sec; \
	     fi; \
	     [ ! -f $(PKGDIR)/apps/security/cst/srk.pub ] && bld cst; \
	     cp -f $(PKGDIR)/apps/security/cst/srk.* $(PKGDIR)/bsp/atf; \
	 else \
	     if [ $(BL33TYPE) = uboot -a $(SOCFAMILY) = LS ]; then \
		 ubootcfg=$(PKGDIR)/bsp/uboot/configs/$${platform}_tfa_defconfig; \
		 bl33=$(FBOUTDIR)/bsp/u-boot/$${platform}/uboot_$${platform}_tfa.bin; \
	     elif [ $(BL33TYPE) = uefi -a $(SOCFAMILY) = LS ]; then \
		 bl33=`grep ^uefi_$(BOOTTYPE) $(FBDIR)/configs/board/$${MACHINE:0:10}.conf | cut -d'"' -f2`; \
		 if [ -z "$$bl33" ]; then exit; fi; \
		 bl33=$(FBOUTDIR)/$$bl33; \
	     fi; \
	     rcwbin=`grep ^rcw_$(BOOTTYPE)= $(FBDIR)/configs/board/$(MACHINE).conf | cut -d'"' -f2`; \
	 fi && \
	 if [ -z "$$rcwbin" -a $(SOCFAMILY) = LS ]; then echo $(MACHINE) $(BOOTTYPE)boot$$secext is not supported && exit 0; fi && \
	 rcwbin=$(FBOUTDIR)/$$rcwbin && \
	 if [ -n "$(rcw_bin)" ]; then rcwbin=$(FBOUTDIR)/bsp/rcw/$(rcw_bin); fi && \
	 if [ $(SOCFAMILY) = LS ]; then \
	    if [ ! -f $$rcwbin ] || `cd $(BSPDIR)/rcw && git status -s|grep -qiE 'M|A|D' && cd - 1>/dev/null`; then \
	 	$(call fbprint_b,"RCW  for $(MACHINE)");  \
		bld rcw -m $(MACHINE); \
		test -f $$rcwbin || { $(call fbprint_e,"$$rcwbin not exist"); exit;} \
	    fi; \
	 fi; \
	 if [ "$(CONFIG_FUSE_PROVISIONING)" = y ]; then \
	     fusefile=$(PKGDIR)/apps/security/cst/fuse_scr.bin && \
	     fuseopt="fip_fuse FUSE_PROG=1 FUSE_PROV_FILE=$$fusefile" && \
	     if [ ! -d $(PKGDIR)/apps/security/cst ]; then bld cst; fi && \
	     $(call fbprint_b,"dependent fuse_scr.bin") && \
	     cd $(PKGDIR)/apps/security/cst && ./gen_fusescr input_files/gen_fusescr/$$chassistype/input_fuse_file && cd -; \
	 fi; \
	 if [ "$(CONFIG_OPTEE)" = y ]; then \
	     if [ $${MACHINE:0:6} = lx2162 ] || ! `echo $$platform|grep -qE 'qds'`; then \
		[ $(SOCFAMILY) = LS ] && platsoc=arm-plat-ls || platsoc=arm-plat-imx; \
		bl32=$(PKGDIR)/apps/security/optee_os/out/$$platsoc/core/tee_$${MACHINE:0:10}.bin; \
		bl32opt="BL32=$$bl32" && spdopt="SPD=opteed"; \
		[ ! -f $$bl32 ] && CONFIG_OPTEE=y bld optee_os -m $$platform; \
	     fi; \
	 fi; \
	 if [ $(BL33TYPE) = uboot -a $(SOCFAMILY) = LS ]; then \
	    if [ ! -f $$bl33 ] || [[ `cd $(BSPDIR)/uboot && git status -s|grep -qiE 'M|A|D' && cd - 1>/dev/null` ]]; then \
		echo building dependent $$bl33 ... $(LOG_MUTE); \
		if [ ! -f $$ubootcfg ]; then \
		    $(call fbprint_e,Not found the dependent $$ubootcfg) && exit; \
		fi; \
		bld uboot -m $$platform -b tfa; \
	    fi; \
	 elif [ $(BL33TYPE) = uefi ]; then \
	    [ ! -f $$bl33 ] && bld uefi_bin -m $$platform; \
	 fi; \
	 if [ $(BOOTTYPE) = xspi ]; then bootmode=flexspi_nor; else bootmode=$(BOOTTYPE); fi && \
	 if [ $(SOCFAMILY) = LS ]; then \
	     echo $(MAKE) -j$(JOBS) fip pbl PLAT=$$platform BOOT_MODE=$$bootmode RCW=$$rcwbin \
		  BL33=$$bl33 $$bl32opt $$spdopt $$secureopt $$fuseopt ${LOG_MUTE} && \
	     $(MAKE) -j$(JOBS) fip pbl PLAT=$$platform BOOT_MODE=$$bootmode \
		     RCW=$$rcwbin BL33=$$bl33 $$bl32opt $$spdopt $$secureopt $$fuseopt $(bldstr) $(LOG_MUTE) && \
	     if [ $${MACHINE:0:5} = lx216 -a "$(SECURE)" = y ] && [ ! -f $$outputdir/ddr_fip_sec.bin ]; then \
		 $(MAKE) -j$(JOBS) fip_ddr PLAT=$$platform BOOT_MODE=$$bootmode $$secureopt $(bldstr) \
		 $$fuseopt DDR_PHY_BIN_PATH=$(PKGDIR)/bsp/ddr_phy_bin/lx2160a $(LOG_MUTE) ; \
		 [ "$(COT)" = arm-cot -o "$(COT)" = arm-cot-with-verified-boot ] && cp -f build/$$platform/release/*.pem $$outputdir/; \
		 cp -f build/$$platform/release/ddr_fip_sec.bin $$outputdir/; \
	     fi && \
	     [ $${MACHINE:0:5} = lx216 -a "$(SECURE)" = y -a -f $$outputdir/ddr_fip_sec.bin ] && \
	     cp -f $$outputdir/ddr_fip_sec.bin $(FBOUTDIR)/bsp/atf/$(MACHINE)/fip_ddr_sec.bin; \
	     cp -f build/$$platform/release/bl2_$$bootmode*.pbl $(FBOUTDIR)/bsp/atf/$(MACHINE)/ && \
	     cp -f build/$$platform/release/fip.bin $(FBOUTDIR)/bsp/atf/$(MACHINE)/fip_$(BL33TYPE)$$secext.bin && \
	     if [ "$(CONFIG_FUSE_PROVISIONING)" = "y" ]; then \
		 cp -f build/$$platform/release/fuse_fip.bin $(FBOUTDIR)/bsp/atf/$(MACHINE)/fuse_fip$$secext.bin; \
	     fi && \
	     if [ "$(COT)" = arm-cot-with-verified-boot ]; then \
		 [ ! -f $(FBOUTDIR)/images/linux_LS_arm64_signature.itb ] && bld itb -r poky:tiny; \
		 ./mkimage -F $(FBOUTDIR)/images/linux_LS_arm64_signature.itb -k keys -K u-boot.dtb -c "Sign the FIT Image" -r; \
		 chmod 644 $(FBOUTDIR)/images/linux_LS_arm64_signature.itb; \
	     fi; \
	 elif [ $(SOCFAMILY) = IMX ]; then \
	    [ $${MACHINE:0:7} = imx8ulp ] && plat=$${MACHINE:0:7} || plat=$${MACHINE:0:6} && \
	    [ $${MACHINE:0:4} = imx9 ] && plat=$${MACHINE:0:5} || true && \
	    $(MAKE) -j$(JOBS) PLAT=$$plat $(bldstr) bl31 $(LOG_MUTE) && \
	    mkdir -p $(FBOUTDIR)/bsp/atf/$(MACHINE) && \
	    cp -f build/$$plat/release/bl31.bin $(FBOUTDIR)/bsp/atf/$(MACHINE)/; \
	 fi && \
	 ls -l $(FBOUTDIR)/bsp/atf/$(MACHINE)/* ${LOG_MUTE} && \
	 $(call fbprint_d,"ATF for $(MACHINE) $${bootmode} boot")
