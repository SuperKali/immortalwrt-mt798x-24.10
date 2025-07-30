#
# Copyright (C) 2008-2012 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=quectel-pcie-mhi
PKG_VERSION:=V1.3.8

include $(INCLUDE_DIR)/package.mk

define KernelPackage/$(PKG_NAME)
  SECTION:=Quectel
  CATEGORY:=Quectel
  TITLE:=X55 PCIE MHI
  FILES:=$(PKG_BUILD_DIR)/pcie_mhi.ko
  AUTOLOAD:=$(call AutoLoad,90,pcie_mhi)
endef

define KernelPackage/$(PKG_NAME)/description
 X55/X62/X75 PCIE MHI
endef

MAKE_OPTS:= \
	$(KERNEL_MAKE_FLAGS) \
	M="$(PKG_BUILD_DIR)"

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		$(MAKE_OPTS) \
		modules
endef

$(eval $(call KernelPackage,quectel-pcie-mhi))
