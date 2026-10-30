# rb-iokit-mac

Ruby binding for macOS host-state signals from IOKit, IOPS, IOBluetooth, and Foundation: battery, power adapter, lid, idle time, thermal state, USB devices, and paired Bluetooth devices. Every signal is public API and needs no root. Built on [swift_gem](https://github.com/bash0C7/swift_gem).

## Requirements

- macOS 27+, Apple Silicon
- Xcode 27 (builds run `xcrun swift`)
- Ruby 4.0+, Bundler 4.x

## Installation

Install from source:

```bash
git clone https://github.com/bash0C7/rb-iokit-mac.git
cd rb-iokit-mac
bundle install
bundle exec rake compile
```

## Usage

```ruby
require "iokit_mac"
```

Hash keys are Symbols in snake_case, listed in sorted order, and a unit suffix (`_percent`, `_mah`, `_mv`, `_ma`, `_minutes`) names the unit of the value. A key is absent when macOS does not report its value. A failed IOKit call raises `IokitMac::ReadError`, a subclass of `IokitMac::Error`.

### Battery

```ruby
IokitMac::Battery.read
# => {charged: false, charging: false, current_capacity_mah: 3100, current_capacity_percent: 80,
#     cycle_count: 120, design_capacity_mah: 4500, device_name: "xxxxxxxx", fully_charged: false,
#     installed: true, max_capacity_mah: 3900, max_capacity_percent: 100, percent: 80.0,
#     power_source_state: "Battery Power", serial: "XXXXXXXXXXXX", source: "InternalBattery-0",
#     time_to_empty_minutes: 312, voltage_mv: 12300}
```

Returns `nil` on a Mac without an internal battery. The first group of keys comes from `IOPSCopyPowerSourcesInfo`; `percent` is `current_capacity_percent / max_capacity_percent * 100` as a Float. `time_to_empty_minutes` and `time_to_full_minutes` are absent while macOS is still estimating them. The second group comes from the `AppleSmartBattery` registry entry; the `_mah` capacities change in finer steps than `percent`.

### Power adapter

```ruby
IokitMac::PowerAdapter.read
# => {adapter_id: 1, current_ma: 4700, description: "pd charger", family_code: -536854528,
#     firmware_version: "0.0", hardware_version: "0.0", manufacturer: "Apple Inc.", model: "0x0000",
#     name: "94W USB-C Power Adapter", serial: "XXXXXXXXXXXX", voltage_mv: 20000, watts: 94,
#     wireless: false}
```

Returns `nil` when no adapter is connected.

### Lid

```ruby
IokitMac::Clamshell.closed?  # => false
```

Reads `AppleClamshellState` of `IOPMrootDomain`: `true` when the lid is closed, `false` when it is open, `nil` on a Mac without a lid. With `pmset -b disablesleep 1` set, macOS does not process the lid-close event and the value stays `false` with the lid closed.

### Idle time

```ruby
IokitMac::Idle.seconds  # => 12.5
```

Seconds since the last keyboard, mouse, or trackpad input (`HIDIdleTime` of `IOHIDSystem`), as a Float.

### Thermal state

```ruby
IokitMac::Thermal.state  # => :nominal
```

`ProcessInfo.thermalState` as one of `IokitMac::Thermal::STATES`: `:nominal`, `:fair`, `:serious`, `:critical`, or `:unknown` for a state added to macOS after the gem was built.

### USB devices

```ruby
IokitMac::Usb.devices
# => [{bcd_device: 256, device_class: 0, device_protocol: 0, device_subclass: 0, name: "Example Keyboard",
#      product_id: 22136, serial: "XXXXXXXX", vendor_id: 4660, vendor_name: "Example Inc."}]
```

One Hash per `IOUSBHostDevice`, including built-in devices.

### Paired Bluetooth devices

```ruby
IokitMac::Bluetooth.paired_devices
# => [{address: "00-00-00-00-00-00", connected: false, name: "Example Mouse", paired: true}]
```

The devices in `IOBluetoothDevice.pairedDevices`. `name` is absent for a device without a name. While Bluetooth is turned off, the list holds only the devices macOS can still enumerate. The app that started Ruby needs Bluetooth permission (System Settings → Privacy & Security → Bluetooth).

### Threads and Ractors

Every method runs in any thread and inside a Ractor. Each call holds the GVL until it returns.

`bundle exec rake console` opens IRB with the gem loaded.

## Examples

```bash
bundle exec ruby examples/iokit_mac.rb
```

reads every signal once and prints it.

The scripts in `acceptance/` check how signals follow physical actions, such as closing the lid or unplugging the adapter, and are run by hand. `acceptance/README.md` lists them.

## Development

```bash
bundle install
bundle exec rake test
```

`rake test` validates `sig/iokit_mac.rbs`, runs `xcrun swift build -c release --package-path ext/iokit_mac`, builds the C extension into `lib/iokit_mac/iokit_mac.bundle`, then runs the tests against the hardware of the Mac running them. The battery tests run only on a Mac with an internal battery, the power adapter tests only with an adapter connected, and the lid test only on a Mac with a lid.

## License

MIT. See LICENSE.txt.
