#
# Copyright 2013 The Android Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


PRODUCT_DEVICE_VENDOR ?= xiaomi
ifeq (,$(findstring gtvs, $(TARGET_PRODUCT)))
ifeq (,$(findstring cert, $(TARGET_PRODUCT)))
#PRODUCT_PACKAGES += NVTLauncher
# CTS:  CtsContentTestCases/CtsProviderTestCases AOSP solution
PRODUCT_PACKAGES += NovaFrameworkPackageStubs

endif
endif

TARGET_BOARD_PLATFORM := kingarthur

PRODUCT_PACKAGES += \
    Camera2  \
    Browser2 \
    TVScreenRecorder \
    MiTVUpnpApp \
    MiTVUpnpService \
    UpnpService \
    MiTVSettings2 \
    TvService \
    mitvmiddleware \
    mitvmiddlewareimpl \
    AirkanTVService  \
    TvHome \
    TVScreenRecorder \
    TWeather \
    TVCalendar \
    TVManager \
    MiTVGallery \
    TVMusic \
    AlarmCenter \
    MiTVMediaExplorer \
    TVSmartScreenSaver \
    MiTVBiAnalytics \
    MiTVMultiCast \
    MiTVPackageInstaller \
    VoiceControl \
    WakeUpService \
    SoundboxMqttService \
    libsurfaceviewoverlay_jni \
    WfdSinkHelper \
    misysdiagnose \
    DeviceReport \
    MiTVLegalWebView

#add for upnp
PRODUCT_PACKAGES += \
     MiTVUpnpApp \
     MiTVUpnpService \
     UpnpService

PRODUCT_PACKAGES += \
    Settings \
    setup-wizard-lib-gingerbread-compat

#This add for miplayer
PRODUCT_PACKAGES +=  libmiplayeradapter \
                     libmimediacodecinterface \
                     libmiffmpeg \
                     libxiaomimediaplayer

# tinytools
PRODUCT_PACKAGES += \
        i2cdetect \
        i2cdump \
        i2cset \
        i2cget \
        tinypcminfo

PRODUCT_PACKAGES += rts_hub_util libusb
PRODUCT_PACKAGES += $(TARGET_RECOVERY_UPDATER_LIBS) $(TARGET_RECOVERY_UI_LIB)

USE_OEM_TV_APP := false

ifeq (,$(findstring gtvs, $(TARGET_PRODUCT)))
ifeq (,$(findstring cert, $(TARGET_PRODUCT)))
PRODUCT_PACKAGES += Provision
endif
endif


# Novatek software upgrade app (update.zip in USB)
PRODUCT_PACKAGES += NovaUpgrade
$(call inherit-product, device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/device_common.mk)
$(call inherit-product, device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/device_idtv.mk)
$(call inherit-product, device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/device_customize.mk)
ifeq (,$(findstring gtvs, $(TARGET_PRODUCT)))
ifeq (,$(findstring cert, $(TARGET_PRODUCT)))
#$(call inherit-product, device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/device_cn_app.mk)
USE_OEM_TV_APP := true
endif
endif
$(warning  USE_OEM_TV_APP : $(USE_OEM_TV_APP))
$(call inherit-product, device/google/atv/products/atv_base.mk)
#$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)

ifneq (,$(filter userdebug eng, $(TARGET_BUILD_VARIANT)))
$(call inherit-product, device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/device_testing.mk)
PRODUCT_PACKAGES += su
endif

ifneq (,$(filter user, $(TARGET_BUILD_VARIANT)))
ifneq (,$(wildcard device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/user_adbshell.mk))
$(warning user_adbshell.mk exist)
$(call inherit-product, device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/user_adbshell.mk)
endif
endif

PRODUCT_NAME := kingarthur
PRODUCT_DEVICE := kingarthur
PRODUCT_BRAND := Xiaomi
PRODUCT_MODEL := kingarthur
PRODUCT_MANUFACTURER := Xiaomi

ifneq ($(PRODUCT_EXTRA_RELEASE_KEYS),)
	PRODUCT_DEFAULT_DEV_CERTIFICATE := $(PRODUCT_EXTRA_RELEASE_KEYS)
endif
#ifneq ($(TARGET_BUILD_VARIANT),eng)
#PRODUCT_DEFAULT_DEV_CERTIFICATE := device/$(PRODUCT_DEVICE_VENDOR)/kingarthur/keys/releasekey
#endif
-include vendor/duokan/framework-exts/build/definitions.mk
MITV_PRODUCT_PACKAGE_OVERLAYS := vendor/duokan/framework-exts/base/corev28/res
PRODUCT_PACKAGE_OVERLAYS := $(MITV_PRODUCT_PACKAGE_OVERLAYS) $(PRODUCT_PACKAGE_OVERLAYS)
PRODUCT_PACKAGES += selinux_policy file_contexts.bin

$(call inherit-product, device/xiaomi/kingarthur/etc/permission.mk)


PRODUCT_FORCE_MULTI32_PREBUILTS_PACKAGES := \
    TVMusic \
    TVCalendar \
    MiTVUpnpService \
    KeyChain \


PRODUCT_LOCALES := zh_CN en_US

BUILD_FACT_PACKAGE := $(shell echo $${BUILD_FACT_PKG})
$(warning FACT_MODE is $(BUILD_FACT_PACKAGE))
#BUILD_FACT_PACKAGE := true
ifeq ($(BUILD_FACT_PACKAGE), true)
include device/xiaomi/kingarthur/factory/factory.mk
endif

BOOTANIMATION_FILE_PATH := system/media/
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/bootanimation.zip:$(BOOTANIMATION_FILE_PATH)/bootanimation.zip \
    $(LOCAL_PATH)/bootanimation_rec.zip:$(BOOTANIMATION_FILE_PATH)/bootanimation_rec.zip \

DEVICE_SPECIAL_MITV_CONFIG_XML := true

# wifi makefile
include device/xiaomi/kingarthur/wifi.mk
# wifi makefile
include device/xiaomi/kingarthur/wifi.mk
