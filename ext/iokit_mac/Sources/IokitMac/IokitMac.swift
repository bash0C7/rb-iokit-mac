import Foundation
import IOKit
import IOKit.ps
import IOBluetooth

/// A failed IOKit or IOPS call, encoded for Ruby as `{"error": code, "detail": detail}`.
struct ReadFailure: Error, Encodable {
    let error: String
    let detail: String

    static func ioKit(_ detail: String) -> ReadFailure {
        ReadFailure(error: "io_kit_failure", detail: detail)
    }

    static func typeMismatch(_ detail: String) -> ReadFailure {
        ReadFailure(error: "type_mismatch", detail: detail)
    }
}

/// Runs a reader and encodes its value, or its `ReadFailure`, as JSON with snake_case keys in sorted order.
///
/// Optional properties that are `nil` are left out of the encoded object, and a `nil` top-level value encodes as `null`.
///
/// - Parameter read: The reader to run.
/// - Returns: The JSON text handed to Ruby.
func respond<Value: Encodable>(_ read: () throws(ReadFailure) -> Value) -> String {
    let value: any Encodable
    do {
        value = try read()
    } catch {
        value = error
    }
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.outputFormatting = .sortedKeys
    return String(decoding: try! encoder.encode(value), as: UTF8.self)
}

/// Looks up the first registry entry of the IOKit class `className` and passes it to `body`.
///
/// - Parameters:
///   - className: The IOKit class to match.
///   - body: The work to do with the entry, which is released afterwards.
/// - Returns: The result of `body`, or `nil` when no entry matches.
func withService<Result, Failure>(_ className: String, _ body: (io_service_t) throws(Failure) -> Result) throws(Failure) -> Result? {
    let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(className))
    guard service != IO_OBJECT_NULL else { return nil }
    defer { IOObjectRelease(service) }
    return try body(service)
}

/// Copies every property of a registry entry.
///
/// - Parameter entry: The registry entry.
/// - Returns: The properties.
func registryProperties(of entry: io_registry_entry_t) throws(ReadFailure) -> [String: Any] {
    var properties: Unmanaged<CFMutableDictionary>?
    let result = IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0)
    guard result == KERN_SUCCESS, let properties = properties?.takeRetainedValue() as? [String: Any] else {
        throw .ioKit("IORegistryEntryCreateCFProperties failed: \(result)")
    }
    return properties
}

/// Copies one property of a registry entry.
///
/// - Parameters:
///   - key: The property name.
///   - entry: The registry entry.
/// - Returns: The property value, or `nil` when the entry has no such property.
func registryProperty(_ key: String, of entry: io_registry_entry_t) -> CFTypeRef? {
    IORegistryEntryCreateCFProperty(entry, key as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
}

/// The internal battery, from IOPS and the `AppleSmartBattery` registry entry.
struct Battery: Encodable {
    let percent: Double?
    let currentCapacityPercent: Int?
    let maxCapacityPercent: Int?
    let charging: Bool
    let charged: Bool
    let timeToEmptyMinutes: Int?
    let timeToFullMinutes: Int?
    let source: String?
    let powerSourceState: String?
    let cycleCount: Int?
    let designCapacityMah: Int?
    let currentCapacityMah: Int?
    let maxCapacityMah: Int?
    let voltageMv: Int?
    let serial: String?
    let deviceName: String?
    let installed: Bool?
    let fullyCharged: Bool?
}

/// Reads the internal battery.
///
/// IOPS reports time estimates in minutes and `-1` while it is still calculating; those become `nil`.
/// The mAh capacities come from the `BatteryData` dictionary of `AppleSmartBattery`.
///
/// - Returns: The battery, or `nil` on a Mac without an internal battery.
func readBattery() throws(ReadFailure) -> Battery? {
    guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else {
        throw .ioKit("IOPSCopyPowerSourcesInfo returned NULL")
    }
    guard let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
        throw .ioKit("IOPSCopyPowerSourcesList returned NULL")
    }
    let descriptions = sources.compactMap {
        IOPSGetPowerSourceDescription(snapshot, $0)?.takeUnretainedValue() as? [String: Any]
    }
    guard let info = descriptions.first(where: { $0[kIOPSTypeKey] as? String == kIOPSInternalBatteryType }) else {
        return nil
    }
    let registry = try withService("AppleSmartBattery", registryProperties(of:)) ?? [:]
    let batteryData = registry["BatteryData"] as? [String: Any] ?? [:]

    let current = info[kIOPSCurrentCapacityKey] as? Int
    let max = info[kIOPSMaxCapacityKey] as? Int
    let percent: Double? = if let current, let max, max > 0 { Double(current) / Double(max) * 100 } else { nil }
    let minutes = { (key: String) in (info[key] as? Int).flatMap { $0 >= 0 ? $0 : nil } }

    return Battery(
        percent: percent,
        currentCapacityPercent: current,
        maxCapacityPercent: max,
        charging: info[kIOPSIsChargingKey] as? Bool ?? false,
        charged: info[kIOPSIsChargedKey] as? Bool ?? false,
        timeToEmptyMinutes: minutes(kIOPSTimeToEmptyKey),
        timeToFullMinutes: minutes(kIOPSTimeToFullChargeKey),
        source: info[kIOPSNameKey] as? String,
        powerSourceState: info[kIOPSPowerSourceStateKey] as? String,
        cycleCount: registry["CycleCount"] as? Int,
        designCapacityMah: batteryData["DesignCapacity"] as? Int,
        currentCapacityMah: batteryData["RemainingCapacity"] as? Int,
        maxCapacityMah: batteryData["FullChargeCapacity"] as? Int,
        voltageMv: registry["Voltage"] as? Int,
        serial: registry["Serial"] as? String,
        deviceName: registry["DeviceName"] as? String,
        installed: registry["BatteryInstalled"] as? Bool,
        fullyCharged: registry["FullyCharged"] as? Bool
    )
}

/// The connected power adapter, from `IOPSCopyExternalPowerAdapterDetails`.
struct PowerAdapter: Encodable {
    let watts: Int?
    let currentMa: Int?
    let voltageMv: Int?
    let adapterId: Int?
    let familyCode: Int?
    let serial: String?
    let name: String?
    let manufacturer: String?
    let model: String?
    let description: String?
    let wireless: Bool?
    let firmwareVersion: String?
    let hardwareVersion: String?
}

/// Reads the connected power adapter.
///
/// - Returns: The adapter, or `nil` when none is connected.
func readPowerAdapter() -> PowerAdapter? {
    guard let details = IOPSCopyExternalPowerAdapterDetails()?.takeRetainedValue() as? [String: Any] else {
        return nil
    }
    return PowerAdapter(
        watts: details[kIOPSPowerAdapterWattsKey] as? Int,
        currentMa: details[kIOPSPowerAdapterCurrentKey] as? Int,
        voltageMv: details["AdapterVoltage"] as? Int,
        adapterId: details[kIOPSPowerAdapterIDKey] as? Int,
        familyCode: details[kIOPSPowerAdapterFamilyKey] as? Int,
        serial: details["SerialString"] as? String,
        name: details["Name"] as? String,
        manufacturer: details["Manufacturer"] as? String,
        model: details["Model"] as? String,
        description: details["Description"] as? String,
        wireless: details["IsWireless"] as? Bool,
        firmwareVersion: details["FwVersion"] as? String,
        hardwareVersion: details["HwVersion"] as? String
    )
}

/// Reads `AppleClamshellState` of `IOPMrootDomain`.
///
/// - Returns: `true` when the lid is closed, `false` when it is open, or `nil` on a Mac without a lid.
func readClamshell() throws(ReadFailure) -> Bool? {
    guard let state = withService("IOPMrootDomain", { registryProperty("AppleClamshellState", of: $0) }) else {
        throw .ioKit("IOPMrootDomain not found")
    }
    guard let state else { return nil }
    guard let closed = state as? Bool else {
        throw .typeMismatch("AppleClamshellState is not a boolean")
    }
    return closed
}

/// Reads `HIDIdleTime` of `IOHIDSystem`, which counts nanoseconds since the last HID input.
///
/// - Returns: The idle time in seconds.
func readIdle() throws(ReadFailure) -> Double {
    guard let idle = withService("IOHIDSystem", { registryProperty("HIDIdleTime", of: $0) }) else {
        throw .ioKit("IOHIDSystem not found")
    }
    guard let idle else {
        throw .ioKit("HIDIdleTime missing")
    }
    guard let nanoseconds = idle as? UInt64 else {
        throw .typeMismatch("HIDIdleTime is not a number")
    }
    return Double(nanoseconds) / 1_000_000_000
}

/// Reads `ProcessInfo.thermalState`.
///
/// - Returns: `nominal`, `fair`, `serious`, `critical`, or `unknown` for a case this build does not know.
func readThermal() -> String {
    switch ProcessInfo.processInfo.thermalState {
    case .nominal: "nominal"
    case .fair: "fair"
    case .serious: "serious"
    case .critical: "critical"
    @unknown default: "unknown"
    }
}

/// One `IOUSBHostDevice`.
struct UsbDevice: Encodable {
    let vendorId: Int?
    let productId: Int?
    let name: String?
    let vendorName: String?
    let serial: String?
    let deviceClass: Int?
    let deviceSubclass: Int?
    let deviceProtocol: Int?
    let bcdDevice: Int?
}

/// Lists every `IOUSBHostDevice`.
///
/// - Returns: The devices.
func readUsbDevices() throws(ReadFailure) -> [UsbDevice] {
    var iterator: io_iterator_t = IO_OBJECT_NULL
    let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOUSBHostDevice"), &iterator)
    guard result == KERN_SUCCESS else {
        throw .ioKit("IOServiceGetMatchingServices(IOUSBHostDevice) failed: \(result)")
    }
    defer { IOObjectRelease(iterator) }

    var devices: [UsbDevice] = []
    while case let entry = IOIteratorNext(iterator), entry != IO_OBJECT_NULL {
        defer { IOObjectRelease(entry) }
        let properties = try registryProperties(of: entry)
        devices.append(UsbDevice(
            vendorId: properties["idVendor"] as? Int,
            productId: properties["idProduct"] as? Int,
            name: properties["USB Product Name"] as? String,
            vendorName: properties["USB Vendor Name"] as? String,
            serial: properties["USB Serial Number"] as? String,
            deviceClass: properties["bDeviceClass"] as? Int,
            deviceSubclass: properties["bDeviceSubClass"] as? Int,
            deviceProtocol: properties["bDeviceProtocol"] as? Int,
            bcdDevice: properties["bcdDevice"] as? Int
        ))
    }
    return devices
}

/// One paired Bluetooth device.
struct BluetoothDevice: Encodable {
    let name: String?
    let address: String
    let paired: Bool
    let connected: Bool
}

/// Lists the devices in `IOBluetoothDevice.pairedDevices()`.
///
/// - Returns: The devices.
func readBluetoothPairedDevices() -> [BluetoothDevice] {
    let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] ?? []
    return devices.map {
        BluetoothDevice(name: $0.name, address: $0.addressString, paired: $0.isPaired(), connected: $0.isConnected())
    }
}
