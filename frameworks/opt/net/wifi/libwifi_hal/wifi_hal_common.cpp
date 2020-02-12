/*
 * Copyright 2016, The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "hardware_legacy/wifi.h"

#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>

#include <android-base/logging.h>
#include <cutils/misc.h>
#include <cutils/properties.h>

#include <string>
#include <vector>

extern "C" int init_module(void *, unsigned long, const char *);
extern "C" int delete_module(const char *, unsigned int);

#include <sys/syscall.h>
#define finit_module(fd, opts, flags) syscall(SYS_finit_module, fd, opts, flags)

#ifdef MULTI_WIFI_SUPPORT
namespace android {

namespace wifi_multiwifi {
  extern const char* get_wifi_fw_sta(void);
  extern const char* get_wifi_fw_ap(void);
  extern const char* get_wifi_fw_p2p(void);
  extern const char* get_wifi_mod_param(void);
  extern const char* get_wifi_mod_name(void);
  extern const char* get_wifi_mod_path(void);
  extern const char* get_wifi_cfg80211_name(void);
  extern std::vector<std::string> get_wifi_def_mods(void);
  extern const char* get_wifi_fw_param_path(void);
}
namespace wifi_power {
  extern void WIFI_POWER_ON(void);
  extern void WIFI_POWER_OFF(void);
}

}
#endif

#ifdef MULTI_WIFI_SUPPORT


#ifdef WIFI_DRIVER_FW_PATH_STA
#undef WIFI_DRIVER_FW_PATH_STA 
#endif
#define WIFI_DRIVER_FW_PATH_STA android::wifi_multiwifi::get_wifi_fw_sta()

#ifdef WIFI_DRIVER_FW_PATH_AP
#undef WIFI_DRIVER_FW_PATH_AP
#endif
#define WIFI_DRIVER_FW_PATH_AP android::wifi_multiwifi::get_wifi_fw_sta()

#ifdef WIFI_DRIVER_FW_PATH_P2P
#undef WIFI_DRIVER_FW_PATH_P2P
#endif
#define WIFI_DRIVER_FW_PATH_P2P android::wifi_multiwifi::get_wifi_fw_p2p()

#ifdef WIFI_DRIVER_MODULE_ARG
#undef WIFI_DRIVER_MODULE_ARG
#endif
#define WIFI_DRIVER_MODULE_ARG android::wifi_multiwifi::get_wifi_mod_param()

#ifdef WIFI_DRIVER_FW_PATH_PARAM
#undef WIFI_DRIVER_FW_PATH_PARAM 
#endif
#define WIFI_DRIVER_FW_PATH_PARAM android::wifi_multiwifi::get_wifi_fw_param_path()

#else


#ifndef WIFI_DRIVER_FW_PATH_STA
#define WIFI_DRIVER_FW_PATH_STA NULL
#endif
#ifndef WIFI_DRIVER_FW_PATH_AP
#define WIFI_DRIVER_FW_PATH_AP NULL
#endif
#ifndef WIFI_DRIVER_FW_PATH_P2P
#define WIFI_DRIVER_FW_PATH_P2P NULL
#endif

#ifndef WIFI_DRIVER_MODULE_ARG
#define WIFI_DRIVER_MODULE_ARG ""
#endif

#endif

static const char* get_modules(void)
{
    return "/proc/modules";
}
static const char DRIVER_PROP_NAME[] = "wlan.driver.status";
#ifdef WIFI_DRIVER_MODULE_PATH
#ifdef MULTI_WIFI_SUPPORT
static const char* DRIVER_MODULE_NAME = android::wifi_multiwifi::get_wifi_mod_name();
static const char* DRIVER_MODULE_TAG = (std::string(android::wifi_multiwifi::get_wifi_mod_name()) + std::string(" ")).c_str();
static const char* DRIVER_MODULE_PATH = android::wifi_multiwifi::get_wifi_mod_path();
static const char* DRIVER_MODULE_ARG = android::wifi_multiwifi::get_wifi_mod_param();
#else
static const char DRIVER_MODULE_NAME[] = WIFI_DRIVER_MODULE_NAME;
static const char DRIVER_MODULE_TAG[] = WIFI_DRIVER_MODULE_NAME " ";
static const char DRIVER_MODULE_PATH[] = WIFI_DRIVER_MODULE_PATH;
static const char DRIVER_MODULE_ARG[] = WIFI_DRIVER_MODULE_ARG;
#endif
static const char MODULE_FILE[] = "/proc/modules";

#endif

static int _insmod(const char *filename, const char *args) {
  int ret;

  int fd = open(filename, O_RDONLY);
  if (fd == -1) return -1;

  ret = finit_module(fd, args, 0);
  if (ret < 0)
    LOG(ERROR)<<"errno: "<<errno <<" " << strerror(errno);

  close(fd);

  return ret;
}

static int _rmmod(const char *modname) {
  int ret = -1;
  int maxtry = 10;

  while (maxtry-- > 0) {
    ret = delete_module(modname, O_NONBLOCK | O_EXCL);
    if (ret < 0) {
      LOG(ERROR)<<"remove module and return: "<< ret << strerror(errno);
    }
    if (ret < 0 && errno == EAGAIN) {
      usleep(500000);
    }
    else
      break;
  }

  if (ret != 0)
    PLOG(DEBUG) << "Unable to unload driver module '" << modname << "'";
  return ret;
}

#ifdef MULTI_WIFI_SUPPORT
std::vector<std::string> installed_modules;
std::vector<std::string>::reverse_iterator riter;
const bool use_cfg80211_mod = false;
static void remove_installed_modules(void) {
    for (riter=installed_modules.rbegin();riter!=installed_modules.rend();riter++)
    {
        _rmmod(riter->c_str());
    }
    installed_modules.clear();

}
static int insmod(const char *filename, const char *args) {
    int ret = 0;
    for(auto def_mod : android::wifi_multiwifi::get_wifi_def_mods()){
       std::string mod_file = std::string(android::wifi_multiwifi::get_wifi_mod_path()) + def_mod + std::string(".ko");
       ret = _insmod(mod_file.c_str(), NULL);
       if (ret < 0){
           remove_installed_modules();
           return ret;
       }
       installed_modules.push_back(def_mod);
    }
    // insmod cfg80211
    if (use_cfg80211_mod) {
        ret = _insmod(android::wifi_multiwifi::get_wifi_cfg80211_name(), NULL);
        if (ret < 0) {
            remove_installed_modules();
            return ret;
        }
        installed_modules.push_back(std::string(android::wifi_multiwifi::get_wifi_cfg80211_name()));
    }

    //insmod driver
    ret = _insmod(filename, args);
    if (ret) {
        LOG(ERROR) << "Failed to insmod driver and ret " << ret << std::endl;
        remove_installed_modules();
        return ret;
    }
    return 0;
}

static int rmmod(const char *modname) {
    int ret = 0;
    ret = _rmmod(modname);
    if (ret) return ret;
    remove_installed_modules();
    return ret;
}
#else
static int insmod(const char *filename, const char *args) {
    return _insmod(filename, args);
}

static int rmmod(const char *modname) {
    return _rmmod(modname);
}
#endif
#ifdef WIFI_DRIVER_STATE_CTRL_PARAM
int wifi_change_driver_state(const char *state) {
  int len;
  int fd;
  int ret = 0;

  if (!state) return -1;
  fd = TEMP_FAILURE_RETRY(open(WIFI_DRIVER_STATE_CTRL_PARAM, O_WRONLY));
  if (fd < 0) {
    PLOG(ERROR) << "Failed to open driver state control param";
    return -1;
  }
  len = strlen(state) + 1;
  if (TEMP_FAILURE_RETRY(write(fd, state, len)) != len) {
    PLOG(ERROR) << "Failed to write driver state control param";
    ret = -1;
  }
  close(fd);
  return ret;
}
#endif

int is_wifi_driver_loaded() {
  char driver_status[PROPERTY_VALUE_MAX];
#ifdef WIFI_DRIVER_MODULE_PATH
  FILE *proc;
  char* line = NULL;
  size_t max_size = 256;
#endif
  if (!property_get(DRIVER_PROP_NAME, driver_status, NULL) ||
      strcmp(driver_status, "ok") != 0) {
    return 0; /* driver not loaded */
  }
#ifdef WIFI_DRIVER_MODULE_PATH
  /*
   * If the property says the driver is loaded, check to
   * make sure that the property setting isn't just left
   * over from a previous manual shutdown or a runtime
   * crash.
   */
  if ((proc = fopen(MODULE_FILE, "r")) == NULL) {
    PLOG(WARNING) << "Could not open " << MODULE_FILE;
    property_set(DRIVER_PROP_NAME, "unloaded");
    return 0;
  }
  while ((::getline(&line, &max_size, proc)) != -1) {
    char *running_modname = std::strtok(line, " ");
    if (strncmp(running_modname, DRIVER_MODULE_NAME, strlen(DRIVER_MODULE_NAME)) == 0) {
      LOG(INFO) << "wifi driver module " << running_modname << " found!";
      if(line) {
          free(line);
      }
      property_set(DRIVER_PROP_NAME, "ok");
      fclose(proc);
      return 1;
    }
  }
  fclose(proc);
  LOG(ERROR) << "driver not found " <<  std::endl;
  property_set(DRIVER_PROP_NAME, "unloaded");
  return 0;
#else
  return 1;
#endif
}

int wifi_load_driver() {
  LOG(INFO) << "LOAD WIFI DRIVER AND SET POWER ON";
  android::wifi_power::WIFI_POWER_ON();
#ifdef WIFI_DRIVER_MODULE_PATH
  if (is_wifi_driver_loaded()) {
    return 0;
  }

  if (DRIVER_MODULE_PATH == NULL || DRIVER_MODULE_NAME == NULL) {
    char property_fact[256] = {0};
    LOG(ERROR) << "DRIVER_MODULE_PATH or DRIVER_MODULE_NAME maybe NULL, return";
    android::wifi_power::WIFI_POWER_OFF();
    if (property_get("ro.product.factorymode", property_fact, NULL) && strcmp(property_fact, "1")) {
      return -1;
    } else {
      return 0;
    }
  }

  if (insmod(DRIVER_MODULE_PATH, DRIVER_MODULE_ARG) < 0) {
    LOG(ERROR) << "Faild to insmod wifi driver module";
    LOG(ERROR) << DRIVER_MODULE_PATH << DRIVER_MODULE_ARG <<std::endl;
    android::wifi_power::WIFI_POWER_OFF();
    return 0;
  }
  property_set("wlan.wifi_chip", DRIVER_MODULE_NAME);
#endif

#ifdef WIFI_DRIVER_STATE_CTRL_PARAM
  if (is_wifi_driver_loaded()) {
    return 0;
  }

  if (wifi_change_driver_state(WIFI_DRIVER_STATE_ON) < 0) {
    android::wifi_power::WIFI_POWER_OFF();
    return -1;
  }
#endif
  property_set(DRIVER_PROP_NAME, "ok");
  return 0;
}

int wifi_unload_driver() {

  LOG(INFO) << "UNLOAD WIFI DRIVER AND SET POWER OFF";
  if (DRIVER_MODULE_PATH == NULL || DRIVER_MODULE_NAME == NULL) {
    char property_fact[256];
    LOG(ERROR) << "DRIVER_MODULE_PATH or DRIVER_MODULE_NAME maybe NULL, return";
    android::wifi_power::WIFI_POWER_OFF();
    if (property_get("ro.product.factorymode", property_fact, NULL) && (strcmp(property_fact, "1") == 0)) {
      return -1;
    } else {
      return 0;
    }
  }

  if (!is_wifi_driver_loaded()) {
    LOG(ERROR) << "driver already removed, quit!";
    return 0;
  }
  usleep(200000); /* allow to finish interface down */
#ifdef WIFI_DRIVER_MODULE_PATH
  if (rmmod(DRIVER_MODULE_NAME) == 0) {
    int count = 20; /* wait at most 10 seconds for completion */
    while (count-- > 0) {
      LOG(INFO) << "left "<< count << " times to check driver: ";
      if (!is_wifi_driver_loaded()) break;
      usleep(500000);
    }
    usleep(500000); /* allow card removal */
    if (count) {
      return 0;
    }
    LOG(ERROR) << "wait driver unload timeout.";
    return 0;
  } else {
    LOG(ERROR) << "unload module failed.";
    return 0;
  }
#else
#ifdef WIFI_DRIVER_STATE_CTRL_PARAM
  if (is_wifi_driver_loaded()) {
    if (wifi_change_driver_state(WIFI_DRIVER_STATE_OFF) < 0) return -1;
  }
#endif
  property_set(DRIVER_PROP_NAME, "unloaded");
  android::wifi_power::WIFI_POWER_OFF();
  return 0;
#endif
}

const char *wifi_get_fw_path(int fw_type) {
  switch (fw_type) {
    case WIFI_GET_FW_PATH_STA:
      return WIFI_DRIVER_FW_PATH_STA;
    case WIFI_GET_FW_PATH_AP:
      return WIFI_DRIVER_FW_PATH_AP;
    case WIFI_GET_FW_PATH_P2P:
      return WIFI_DRIVER_FW_PATH_P2P;
  }
  return NULL;
}

int wifi_change_fw_path(const char *fwpath) {
  int len;
  int fd;
  int ret = 0;

  if (!fwpath) return ret;
  fd = TEMP_FAILURE_RETRY(open(WIFI_DRIVER_FW_PATH_PARAM, O_WRONLY));
  if (fd < 0) {
    PLOG(ERROR) << "Failed to open wlan fw path param";
    return -1;
  }
  len = strlen(fwpath) + 1;
  if (TEMP_FAILURE_RETRY(write(fd, fwpath, len)) != len) {
    PLOG(ERROR) << "Failed to write wlan fw path param";
    ret = -1;
  }
  close(fd);
  return ret;
}
