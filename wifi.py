#!/usr/bin/python3

import json
import xml.etree.ElementTree as ET
import os

#const values
QCOM_MODULES = ['qca9377', 'qca9379'];
RTL_MODULES = ['rtl8189ftv', 'rtl8188ftv', 'rtl8723ds', 'rtl8723du', 'rtl8821cs', 'rtl8821cu', 'rtl8822cu'];
MTK_MODULES= ['mt7668_usb'];
VENDORS = [{'name':'qcom', 'modules':QCOM_MODULES}, {'name':'realtek', 'modules':RTL_MODULES},{'name':'mtk', 'modules':MTK_MODULES},];

#global default values
g_project_device_prefix = 'device/xiaomi'
g_miwifi_path_prefix = 'hardware/xiaomi/wifi'
g_wifi_cfg_path = g_miwifi_path_prefix + '/configs'
g_rc_rootfs_path = 'odm/etc/init/hw/init.wifi.rc'
g_manifest_path = '.repo/manifests/mitvos'
g_wifi_hal_path = 'frameworks/opt/net/wifi'
g_hardware_interface_path = 'hardware/interfaces'

class CommentedTreeBuilder ( ET.TreeBuilder ):
    def comment(self, data):
        self.start(ET.Comment, {})
        self.data(data)
        self.end(ET.Comment)
        return

manifest_parser = ET.XMLParser(target = CommentedTreeBuilder())


def get_vendor_from_module(module):
    for vendor in VENDORS:
        if module in vendor['modules']:
            return vendor['name']

def parse_cfg(filename):
    hal = list()
    wifi_cfg = json.load(open(filename, 'r'));
    name = wifi_cfg['product'];
    modules = wifi_cfg['wifi_modules'];
    properties = wifi_cfg['properties'];
    project_configs = {'fw_path':wifi_cfg['fw_path'], 
            'cfg_path':wifi_cfg['cfg_path'],
            'dual_interface':wifi_cfg['dual_interface'], 
            'init_rc':wifi_cfg['init_rc'],
            'miracast':wifi_cfg['miracast']};
    for vendor in VENDORS:
        for module in modules:
            if module in vendor['modules']:
                hal.append(vendor['name']);
        
    return name, modules, properties, project_configs, hal;

def obtain_elements(attrib_name, attrib_path, attrib_revision):
    project = ET.Element('project', attrib={'name':attrib_name, 'path':attrib_path, 'revision':attrib_revision});
    if project.tail == None:
        project.tail = '\n    ';
    return project

def add_common_projects(root):
    attrib_name = '/mitv_bsp/hardware/xiaomi/wifi/'
    attrib_path = '/hardware/xiaomi/wifi/'
    attrib_revision = 'master'
    prj = obtain_elements(attrib_name, attrib_path, attrib_revision);
    prj.tail = '\n    ';
    root.append(prj);
    return

def add_driver_projects(root, path_prefix, modules):
    attrib_revision = 'master';
    name_prefix = '/mitv_bsp/duokan/hardware/wifi/';
    if path_prefix == None:
        path_prefix = 'vendor/duokan/hardware/wifi/';
    for module in modules:
        if module == 'mt7668_usb':
            attrib_revision = 'jobs'
        elif module == 'qca9377' or modules == 'rtl8723ds':
            attrib_revision = 'magnolia_p'
        elif module == 'rtl8821cu':
            attrib_revision = 'master'
        #driver_project = ET.Element('project', attrib={});
        attrib_name = name_prefix + get_vendor_from_module(module)+'drivers/'+module;
        attrib_path = path_prefix + get_vendor_from_module(module)+'drivers/'+module;
        root.append(obtain_elements(attrib_name, attrib_path, attrib_revision));
    return

def get_attrib_by_vendor(vendor, name, path_prefix, path):
    reviosn = 'master';
    name_prefix = '/mitv_bsp/duokan/hardware/wifi/';
    if path_prefix == None:
        path_prefix = 'vendor/duokan/hardware/wifi/';
    full_name = name_prefix + vendor+ '/' + name;
    full_path = path_prefix + vendor + '/' + path;
    return reviosn, full_name, full_path

def add_hal_and_configs_projects(root, path, hals):
    attrib_revision = 'master';
    for hal in hals:
        #driver_project = ET.Element('project', attrib={});
        attrib_revision, attrib_name, attrib_path = get_attrib_by_vendor(hal, 'hal', path, 'wifi_hal');
        root.append(obtain_elements(attrib_name, attrib_path, attrib_revision));
        attrib_revision, attrib_name, attrib_path = get_attrib_by_vendor(hal, 'configs', path, 'configs');
        root.append(obtain_elements(attrib_name, attrib_path, attrib_revision));
    return

def add_projects_to_manifest(product, modules, path, hal):
    manifest_file_path = g_manifest_path + '/' + product+'.xml'
    print(manifest_file_path)
    tree = ET.parse(manifest_file_path, parser = manifest_parser);
    root = tree.getroot();
    #add indent
    projects = root.findall('project');
    print (projects[-1].tag, projects[-1].attrib, projects[-1].tail)
    projects[-1].tail = '\n    ';
    #comments = root.findall('[last()-1]');
    #comments[-1].tail = '\n    ';
    #add comment
    begin_comment = ET.Comment("Xiaomi wifi begin:");
    begin_comment.tail = '\n    ';
    root.append(begin_comment);
    #add projects
    add_common_projects(root);
    #wifi drivers
    add_driver_projects(root, path, modules);
    #wifi hal and configs
    add_hal_and_configs_projects(root, path, hal);
    end_comment = ET.Comment("Xiaomi wifi end");
    end_comment.tail = '\n';
    root.append(end_comment);
    tree.write(manifest_file_path, xml_declaration=True, encoding="utf-8", method="xml")
    return

def add_configs_to_makefile(product_name, wifi_project_configs, modules):
    wifi_mk_path_prefix = g_project_device_prefix + '/';
    wifi_mk_path = wifi_mk_path_prefix + product_name + '/wifi.mk';
    product_mk_path = wifi_mk_path_prefix + product_name + '/'+ product_name + '.mk';
    driver_mk_path = wifi_mk_path_prefix + product_name + '/BoradConfig.mk'
    # /device/xiaomi/${product}/wifi.mk, include wifi configuration product depandent
    if wifi_project_configs['cfg_path'] == None:
        miwifi_mk_file_path = g_miwifi_path_prefix;
    else:
        miwifi_mk_file_path = wifi_project_configs['cfg_path'] + '/mkfiles/' 
    wifi_mk_file = open(wifi_mk_path, 'a+');
    wifi_mk_file.write('# wifi configuration\n');
    wifi_mk_file.write('WIFI_MODULES := ' + ' '.join(modules) + '\n');
    wifi_mk_file.write('MULTI_WIFI_SUPPORT := true\n');
    if wifi_project_configs['dual_interface'] != None and wifi_project_configs['dual_interface']:
        wifi_mk_file.write('WIFI_HIDL_FEATURE_DUAL_INTERFACE := true\n');
    if wifi_project_configs['miracast'] != None and wifi_project_configs['miracast']:
        wifi_mk_file.write('MIRACAST_SUPPORT := true\n');
    wifi_mk_file.write('include ' + miwifi_mk_file_path + 'wifi.mk\n');
    wifi_mk_file.close();
    # /device/xiaomi/${product}/${product}.mk, only to include wifi.mk is enough
    product_mk_file = open(product_mk_path, 'a+');
    product_mk_file.write('# wifi makefile\n');
    product_mk_file.write('include ' + wifi_mk_path + '\n');
    product_mk_file.close();
    # add dependent to BoardConfig.mk for building driver
    driver_mk_file = open(driver_mk_path, 'a+');
    driver_mk_file.write('# build wifi driver\n');
    driver_mk_file.write('include ' + miwifi_mk_file_path + 'AndroidWifi.mk');
    return

def add_wifi_init_rc(product_name, wifi_project_configs):
    if wifi_project_configs['init_rc'] == None:
        root_rc_file_name = g_project_device_prefix + 'init.rc'
    else:
        root_rc_file_name = wifi_project_configs['init_rc']
    rc_file = open(root_rc_file_name, 'w+');
    rc_file.write('import ' + g_rc_rootfs_path + '\n');
    rc_file.close();
    return

def patch_repository(path, patch):
    cmd = 'cp ' + patch + ' ' + path + '/';
    print(cmd);
    cmd += ' && cd ' + path;
    print(cmd);
    cmd += ' && git apply ' + patch;
    print(cmd);
    os.system(cmd);
    return

def patch_wifi_hal():
    patch_repository(g_wifi_hal_path, 'wifi_hal.diff')
    return

def patch_hardware_interface():
    patch_repository(g_hardware_interface_path, 'wifi_hardware_interface.diff')
    return

def patch_repositories():
    patch_wifi_hal()
    patch_hardware_interface()
    return

def welcome():
    print("welcome to wifi bringup tools")
    return

def prepare():
    print("prepare")
    return

def cleanup():
    print("cleanup")
    return

def execute(cfg):
    product_name, wifi_modules, wifi_properties, wifi_project_configs, wifi_hal = parse_cfg('wifi.json');
    add_projects_to_manifest(product_name, wifi_modules, wifi_project_configs['fw_path'], wifi_hal);
    add_configs_to_makefile(product_name, wifi_project_configs, wifi_modules);
    add_wifi_init_rc(product_name, wifi_project_configs);
    patch_repositories()
    return

if __name__ == '__main__':
    welcome()
    prepare()
    execute('wifi.json');
    cleanup()

