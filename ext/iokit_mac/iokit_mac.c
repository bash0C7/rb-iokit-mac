#include <ruby.h>
#include "IokitMac-Swift.h"

static VALUE take_json(char *json) {
    VALUE str = rb_utf8_str_new_cstr(json);
    iokit_mac_free(json);
    return str;
}

static VALUE rb_iokit_mac_battery_read(VALUE self) {
    return take_json(iokit_mac_battery_read());
}

static VALUE rb_iokit_mac_power_adapter_read(VALUE self) {
    return take_json(iokit_mac_power_adapter_read());
}

static VALUE rb_iokit_mac_clamshell_read(VALUE self) {
    return take_json(iokit_mac_clamshell_read());
}

static VALUE rb_iokit_mac_idle_read(VALUE self) {
    return take_json(iokit_mac_idle_read());
}

static VALUE rb_iokit_mac_thermal_read(VALUE self) {
    return take_json(iokit_mac_thermal_read());
}

static VALUE rb_iokit_mac_usb_devices_read(VALUE self) {
    return take_json(iokit_mac_usb_devices_read());
}

static VALUE rb_iokit_mac_bluetooth_paired_devices_read(VALUE self) {
    return take_json(iokit_mac_bluetooth_paired_devices_read());
}

void Init_iokit_mac(void) {
    rb_ext_ractor_safe(true);
    VALUE module = rb_define_module("IokitMac");
    rb_define_singleton_method(module, "_battery_read", rb_iokit_mac_battery_read, 0);
    rb_define_singleton_method(module, "_power_adapter_read", rb_iokit_mac_power_adapter_read, 0);
    rb_define_singleton_method(module, "_clamshell_read", rb_iokit_mac_clamshell_read, 0);
    rb_define_singleton_method(module, "_idle_read", rb_iokit_mac_idle_read, 0);
    rb_define_singleton_method(module, "_thermal_read", rb_iokit_mac_thermal_read, 0);
    rb_define_singleton_method(module, "_usb_devices_read", rb_iokit_mac_usb_devices_read, 0);
    rb_define_singleton_method(module, "_bluetooth_paired_devices_read", rb_iokit_mac_bluetooth_paired_devices_read, 0);
}
