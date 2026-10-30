import Foundation

/// Reads the internal battery as JSON, exposed to C as `iokit_mac_battery_read`.
///
/// The JSON is an object, `null` on a Mac without an internal battery, or an error envelope.
/// The returned buffer is allocated with `strdup`. Release it with ``cFree(_:)``.
///
/// - Returns: A newly allocated NUL-terminated UTF-8 string owned by the caller.
@c(iokit_mac_battery_read)
public func cBatteryRead() -> UnsafeMutablePointer<CChar> {
    strdup(respond(readBattery))!
}

/// Reads the connected power adapter as JSON, exposed to C as `iokit_mac_power_adapter_read`.
///
/// The JSON is an object, or `null` when no adapter is connected.
/// The returned buffer is allocated with `strdup`. Release it with ``cFree(_:)``.
///
/// - Returns: A newly allocated NUL-terminated UTF-8 string owned by the caller.
@c(iokit_mac_power_adapter_read)
public func cPowerAdapterRead() -> UnsafeMutablePointer<CChar> {
    strdup(respond(readPowerAdapter))!
}

/// Reads the lid state as JSON, exposed to C as `iokit_mac_clamshell_read`.
///
/// The JSON is `true` when the lid is closed, `false` when it is open, `null` on a Mac without a lid, or an error envelope.
/// The returned buffer is allocated with `strdup`. Release it with ``cFree(_:)``.
///
/// - Returns: A newly allocated NUL-terminated UTF-8 string owned by the caller.
@c(iokit_mac_clamshell_read)
public func cClamshellRead() -> UnsafeMutablePointer<CChar> {
    strdup(respond(readClamshell))!
}

/// Reads the seconds since the last HID input as JSON, exposed to C as `iokit_mac_idle_read`.
///
/// The JSON is a number or an error envelope.
/// The returned buffer is allocated with `strdup`. Release it with ``cFree(_:)``.
///
/// - Returns: A newly allocated NUL-terminated UTF-8 string owned by the caller.
@c(iokit_mac_idle_read)
public func cIdleRead() -> UnsafeMutablePointer<CChar> {
    strdup(respond(readIdle))!
}

/// Reads the thermal state as JSON, exposed to C as `iokit_mac_thermal_read`.
///
/// The JSON is a string: `"nominal"`, `"fair"`, `"serious"`, `"critical"`, or `"unknown"`.
/// The returned buffer is allocated with `strdup`. Release it with ``cFree(_:)``.
///
/// - Returns: A newly allocated NUL-terminated UTF-8 string owned by the caller.
@c(iokit_mac_thermal_read)
public func cThermalRead() -> UnsafeMutablePointer<CChar> {
    strdup(respond(readThermal))!
}

/// Lists the USB devices as JSON, exposed to C as `iokit_mac_usb_devices_read`.
///
/// The JSON is an array of objects or an error envelope.
/// The returned buffer is allocated with `strdup`. Release it with ``cFree(_:)``.
///
/// - Returns: A newly allocated NUL-terminated UTF-8 string owned by the caller.
@c(iokit_mac_usb_devices_read)
public func cUsbDevicesRead() -> UnsafeMutablePointer<CChar> {
    strdup(respond(readUsbDevices))!
}

/// Lists the paired Bluetooth devices as JSON, exposed to C as `iokit_mac_bluetooth_paired_devices_read`.
///
/// The JSON is an array of objects.
/// The returned buffer is allocated with `strdup`. Release it with ``cFree(_:)``.
///
/// - Returns: A newly allocated NUL-terminated UTF-8 string owned by the caller.
@c(iokit_mac_bluetooth_paired_devices_read)
public func cBluetoothPairedDevicesRead() -> UnsafeMutablePointer<CChar> {
    strdup(respond(readBluetoothPairedDevices))!
}

/// Releases a buffer returned by the readers of this module, exposed to C as `iokit_mac_free`.
///
/// The caller owns every buffer a reader returns and must pass it to this function exactly once.
///
/// - Parameter ptr: The buffer to release, or `nil`.
@c(iokit_mac_free)
public func cFree(_ ptr: UnsafeMutablePointer<CChar>?) {
    free(ptr)
}
