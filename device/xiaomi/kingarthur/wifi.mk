# wifi configuration
WIFI_MODULES := mt7668_usb qca9377
MULTI_WIFI_SUPPORT := true
WIFI_HIDL_FEATURE_DUAL_INTERFACE := true
MIRACAST_SUPPORT := true
include hardware/xiaomi/wifi/mkfiles/wifi.mk
