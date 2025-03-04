#
# Copyright (C) 2016 The CyanogenMod Project
#               2017-2019 The LineageOS Project
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

ifeq ($(TARGET_SCREEN_WIDTH),)
    $(warning TARGET_SCREEN_WIDTH is not set, using default value: 1080)
    TARGET_SCREEN_WIDTH := 1080
endif
ifeq ($(TARGET_SCREEN_HEIGHT),)
    $(warning TARGET_SCREEN_HEIGHT is not set, using default value: 1920)
    TARGET_SCREEN_HEIGHT := 1920
endif

TARBIN := prebuilts/build-tools/path/$(HOST_OS)-x86/tar

TARGET_GENERATED_BOOTANIMATION := $(TARGET_OUT_INTERMEDIATES)/BOOTANIMATION/bootanimation.zip
$(TARGET_GENERATED_BOOTANIMATION): INTERMEDIATES := $(TARGET_OUT_INTERMEDIATES)/BOOTANIMATION
$(TARGET_GENERATED_BOOTANIMATION): $(SOONG_ZIP)
	@echo "Building bootanimation.zip"
	@rm -rf $(dir $@)
	@mkdir -p $(dir $@)
	$(hide) if [ -z $(TARGET_PICK_BOOTANIMATION) ]; then \
            BOOTSELECTED=$$(expr $$RANDOM % 9); \
        else \
            if [ $(TARGET_PICK_BOOTANIMATION) -lt 9 ]; then \
                BOOTSELECTED=$(TARGET_PICK_BOOTANIMATION); \
            else \
                BOOTSELECTED=$$(expr $$RANDOM % 9); \
            fi; \
        fi; \
        case "$$BOOTSELECTED" in \
	    [0-1]) \
	        BOOTFPS="30"; \
	        ISQUARE="true"; \
	    ;; \
	    2) \
	        BOOTFPS="48"; \
	        ISQUARE="true"; \
	    ;; \
	    [3-4]) \
	        BOOTFPS="50"; \
	        ISQUARE="false"; \
	    ;; \
	    [5-7]) \
	        BOOTFPS="25"; \
	        ISQUARE="false"; \
	    ;; \
	    8) \
	        BOOTFPS="30"; \
	        ISQUARE="false"; \
	esac; \
	$(TARBIN) xfp "vendor/bootleggers/bootanimation/bootanimation$$BOOTSELECTED.tar" -C $(INTERMEDIATES); \
	if [ $(TARGET_SCREEN_HEIGHT) -lt $(TARGET_SCREEN_WIDTH) ]; then \
	    IMAGEWIDTH=$(TARGET_SCREEN_HEIGHT); \
	else \
	    IMAGEWIDTH=$(TARGET_SCREEN_WIDTH); \
	fi; \
	if [ "$$ISQUARE" = "true" ]; then \
		IMAGEHEIGHT="$$IMAGEWIDTH"; \
		IMAGESCALEHEIGHT="$$IMAGEWIDTH"; \
	else \
		IMAGEHEIGHT=$(TARGET_SCREEN_HEIGHT); \
		IMAGESCALEHEIGHT="$$IMAGEHEIGHT"; \
	fi; \
	IMAGESCALEWIDTH=$$IMAGEWIDTH; \
	if [ "$(TARGET_BOOTANIMATION_HALF_RES)" = "true" ]; then \
	    IMAGEHEIGHT="$$(expr "$$IMAGEHEIGHT" / 2)"; \
	    IMAGEWIDTH="$$(expr "$$IMAGEWIDTH" / 2)"; \
	fi; \
	RESOLUTION="$$IMAGEWIDTH"x"$$IMAGEHEIGHT"; \
	for part_cnt in 0 1 2; do \
	    mkdir -p $(INTERMEDIATES)/part$$part_cnt; \
	done; \
	prebuilts/tools-bootleg/${HOST_OS}-x86/bin/mogrify -strip -gaussian-blur 0.05 -quality 55 -resize $$RESOLUTION^ -gravity center -crop $$RESOLUTION+0+0 -colors 250 $(INTERMEDIATES)/*/*.jpg; \
	echo "$$IMAGESCALEWIDTH $$IMAGESCALEHEIGHT $$BOOTFPS" > $(INTERMEDIATES)/desc.txt; \
	cat vendor/bootleggers/bootanimation/desc.txt >> $(INTERMEDIATES)/desc.txt
	$(hide) $(SOONG_ZIP) -L 0 -o $(TARGET_GENERATED_BOOTANIMATION) -C $(INTERMEDIATES) -D $(INTERMEDIATES)

ifeq ($(TARGET_BOOTANIMATION),)
    TARGET_BOOTANIMATION := $(TARGET_GENERATED_BOOTANIMATION)
endif

include $(CLEAR_VARS)
LOCAL_MODULE := bootanimation.zip
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $(TARGET_OUT)/media

include $(BUILD_SYSTEM)/base_rules.mk

$(LOCAL_BUILT_MODULE): $(TARGET_BOOTANIMATION)
	@cp $(TARGET_BOOTANIMATION) $@
