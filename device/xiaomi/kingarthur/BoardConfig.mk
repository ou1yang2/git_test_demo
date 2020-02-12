#
# Copyright 2017 The Android Open-Source Project
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

TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 := 
TARGET_CPU_VARIANT := cortex-a53

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a9

TARGET_BOARD_PLATFORM := kingarthur
TARGET_BOOTLOADER_BOARD_NAME := kingarthur
PRODUCT_DEVICE_VENDOR ?= xiaomi

BOARD_BOOTIMG_HEADER_VERSION := 1
BOARD_MKBOOTIMG_ARGS := --header_version $(BOARD_BOOTIMG_HEADER_VERSION)

ifeq ($(AB_OTA_UPDATER),true)
TARGET_RECOVERY_FSTAB := device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/recovery.ab.fstab
else
TARGET_RECOVERY_FSTAB := device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/recovery.fstab
TARGET_RECOVERY_UPDATER_LIBS += libnvt_recovery_updater
TARGET_RECOVERY_UI_LIB += librecovery_ui_kingarthur
BOARD_INCLUDE_RECOVERY_DTBO := true
BOARD_PREBUILT_DTBOIMAGE := vendor/novatek/n75000_a64/BSP/linux-4.9/dtbo.img
BOARD_USE_PRIVATE_RECOVERY_RES := true
endif

TARGET_USES_HWC2 := true
NUM_FRAMEBUFFER_SURFACE_BUFFERS := 3

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_SPARSE_EXT_DISABLED := false
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 1702887424
ifneq (,$(findstring gtvs, $(TARGET_PRODUCT)))
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 1598029824
else
  ifneq (,$(findstring cert, $(TARGET_PRODUCT)))
    BOARD_SYSTEMIMAGE_PARTITION_SIZE := 1598029824
  endif
endif

ifndef CI_SECUREBOOT_RELEASE
CI_SECUREBOOT_RELEASE := false
endif

BOARD_AVB_ENABLE := $(CI_SECUREBOOT_RELEASE)
ifeq ($(BOARD_AVB_ENABLE), true)
BOARD_AVB_ALGORITHM := SHA256_RSA2048
BOARD_AVB_KEY_PATH := vendor/novatek/libkxhash/rsa_priv.pem

BOARD_BOOTIMAGE_PARTITION_SIZE := 25165824
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 50331648
BOARD_DTBOIMG_PARTITION_SIZE := 1048576
NVT_BOOTIMG_SIGNER := vendor/novatek/libkxhash/nvt_sign_bootimg
NVT_BOOTIMG_PEMKEY := vendor/novatek/libkxhash/rsa_priv.pem
endif

# Product Partition
BOARD_USES_PRODUCTIMAGE := true
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_PRODUCTIMAGE_PARTITION_SIZE := 629145600
TARGET_COPY_OUT_PRODUCT := product


#For CtsMediaStressTest enlarge
#BOARD_USERDATAIMAGE_PARTITION_SIZE := 1073741824
ifneq (,$(findstring a64_cert, $(TARGET_PRODUCT)))
# Currently, only enlarge data image size to 8 GB for arm64 GTVS Cert.
BOARD_USERDATAIMAGE_PARTITION_SIZE := 8589934592
else
BOARD_USERDATAIMAGE_PARTITION_SIZE := 2684354560
endif

ifeq (,$(filter true, $(AB_OTA_UPDATER)))
BOARD_CACHEIMAGE_PARTITION_SIZE := 1048576000
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
endif
BOARD_FLASH_BLOCK_SIZE := 4096

#for seprate vendor.img build, enable three item below
TARGET_COPY_OUT_VENDOR := vendor
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_PARTITION_SIZE := 838860800

TARGET_COPY_OUT_ODM := odm
#BOARD_ROOT_EXTRA_FOLDERS += odm
BOARD_ODMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_ODMIMAGE_PARTITION_SIZE := 268435456
BOARD_USES_ODMIMAGE := true
TARGET_COPY_FILE_TO_ODM := true

#for verifying boot, enable these config
#BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2147483648
#TARGET_USERIMAGES_SPARSE_EXT_DISABLED := false 
#BOARD_VENDORIMAGE_PARTITION_SIZE := 629145600
#BOARD_ODMIMAGE_PARTITION_SIZE := 268435456

BOARD_PROPERTY_OVERRIDES_SPLIT_ENABLED := true

# for system_root image, enable two item below.
# to boot normally, you must burn properly u-boot.img and nvtca53_xxx_android.dtb.img
BOARD_USES_RECOVERY_AS_BOOT := false
BOARD_BUILD_SYSTEM_ROOT_IMAGE := true

TARGET_USES_64_BIT_BINDER := true
TARGET_SUPPORTS_32_BIT_APPS := true
TARGET_SUPPORTS_64_BIT_APPS := true

TARGET_RECOVERY_PIXEL_FORMAT := "RGBX_8888"


# Bluetooth 
# These flags will be defined by device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/realtek/rtkbt/rtkbt.mk
BOARD_HAVE_BLUETOOTH := true
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/bluetooth

BOARD_EGL_CFG := device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/egl/egl.cfg

SKIP_BOOT_JARS_CHECK := true


# NVT patch for stagefright
NVT_PATCH_STAGEFRIGHT := true
NVT_PATCH_MEDIA := true
NVT_PATCH_SUPPORT_AV1 := true

# NVT patch for PQ feature
NVT_PATCH_SUPPORT_AIPQ := true
NVT_PATCH_SUPPORT_GPE := true

# FFMpegExtractor support Divx456 or not
FFEXT_SUPPORT_DivX456 := true


# enabled to carry out all drawing operations performed on a View's canvas with GPU for 2D rendering pipeline.
USE_OPENGL_RENDERER := true


BOARD_SEPOLICY_DIRS += device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/sepolicy
BOARD_PLAT_PRIVATE_SEPOLICY_DIR := device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/sepolicy/private
BOARD_PLAT_PUBLIC_SEPOLICY_DIR := device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/sepolicy/public

#USE_CLANG_PLATFORM_BUILD := true

#OTA RELEASETOOLS_EXTENSIONS
TARGET_RELEASETOOLS_EXTENSIONS:= vendor/novatek/BSP/releasetools.py
# add device-specific extensions to the updater binary

TARGET_RECOVERY_UPDATER_EXTRA_LIBS += libnvtfdt libmtdutils libfrcutils
NVT_TARGET_USERIMAGES_SPARSE_EXT_ON_OTA_PKG := true
TARGET_RECOVERY_PIXEL_FORMAT = BGRA_8888



DEVICE_MANIFEST_FILE := device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/manifest.xml
DEVICE_MATRIX_FILE   := device/$(PRODUCT_DEVICE_VENDOR)/$(TARGET_BOARD_PLATFORM)/compatibility_matrix.xml

BOARD_VNDK_VERSION := current

#use custom audio policy to implement TK audio features
USE_CUSTOM_AUDIO_POLICY := 1
