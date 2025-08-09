include $(TOPDIR)/rules.mk

PKG_NAME:=led-modem-controller
PKG_VERSION:=2.1.0
PKG_RELEASE:=1

PKG_MAINTAINER:=SuperKali <hello@superkali.me>

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=LED Modem Controller with Modular Support
  DEPENDS:=+sms-tool +bc
  PKGARCH:=all
endef

define Package/$(PKG_NAME)/description
  LED Modem Controller monitors modem connection status and controls 
  LEDs accordingly. Features modular modem support and configurable 
  device selection. Supports 4G/5G with signal quality LED indication.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) ./files/usr/bin/led-modem-controller $(1)/usr/bin/
	
	$(INSTALL_DIR) $(1)/usr/share/led-modem-controller
	$(INSTALL_BIN) ./files/usr/share/led-modem-controller/led-query.sh $(1)/usr/share/led-modem-controller/
	$(INSTALL_DATA) ./files/usr/share/led-modem-controller/common.sh $(1)/usr/share/led-modem-controller/
	
	$(INSTALL_DIR) $(1)/usr/share/led-modem-controller/modem/usb
	$(INSTALL_DATA) ./files/usr/share/led-modem-controller/modem/usb/* $(1)/usr/share/led-modem-controller/modem/usb/
	
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/etc/init.d/led-modem-controller $(1)/etc/init.d/
	
	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/etc/uci-defaults/99-led-perm-controller $(1)/etc/uci-defaults/
	
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/etc/config/led-modem-controller $(1)/etc/config/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
