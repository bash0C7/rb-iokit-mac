# CLAUDE.md — rb-iokit-mac

## Position

Ruby native binding for macOS host-state signals (IOKit, IOPS, IOBluetooth, Foundation), built on the `bash0C7/swift_gem` scaffold. Sibling of `rb-vision-mac`, `rb-av-foundation-mac`, `rb-corebluetooth-mac`, and `rb-foundation-model-mac`.

Scope is limited to signals that are root-free, public Apple API, stable on Apple Silicon, and in the IOKit / IOBluetooth / Foundation host-state family. A signal that fails any of the four belongs in a separate gem.

## Core design principles

1. Thin wrapper. Each signal is one Swift reader that returns JSON, one C singleton method, and one Ruby method that decodes it.
2. Swift builds an `Encodable` struct per signal and encodes it with `.convertToSnakeCase` and `.sortedKeys`, so every Hash lists its keys in sorted order. Hash keys are snake_case Symbols with a unit suffix (`_percent`, `_mah`, `_mv`, `_ma`, `_minutes`). A `nil` property is left out of the object, so a key is absent when macOS does not report the value.
3. "Not present on this Mac" is `null` (Ruby `nil`): no internal battery, no adapter, no lid. A failed IOKit call is the envelope `{"error": code, "detail": detail}` from `ReadFailure`, which `IokitMac::Parse.payload` raises as `IokitMac::ReadError`.
4. Readers are stateless and keep no Swift or Ruby globals. The C extension declares `rb_ext_ractor_safe(true)`; every method runs in any thread or Ractor. Calls hold the GVL (no `rb_thread_call_without_gvl`).
5. Ownership follows the Core Foundation naming rule: `Copy`/`Create` results use `takeRetainedValue`, `Get` results use `takeUnretainedValue`, every `io_object_t` is released with `IOObjectRelease` in a `defer`.
6. Scaffold parity. `bundle exec rake "new[rb-iokit-mac,<dir>]"` in swift_gem produces a skeleton whose only diffs against this repo are the implementation body, `sig/`, tests, examples, acceptance scripts, docs, gemspec summary and description, and build artifacts.

## Architecture

```
[caller (Ruby)]
  │
  │   IokitMac::<Signal>.<method>
  ▼
lib/iokit_mac.rb             ← Parse.payload + per-signal modules (Float / Symbol coercion)
  │
  │   IokitMac._<signal>_read → JSON String
  ▼
ext/iokit_mac/iokit_mac.c     ← rb_define_singleton_method, copies the JSON and calls iokit_mac_free
  │
  │   iokit_mac_<signal>_read()
  ▼
ext/iokit_mac/Sources/IokitMac/IokitMacBridge.swift   ← @c(name) (SE-0495), strdup(respond(reader))
  │
  ▼
ext/iokit_mac/Sources/IokitMac/IokitMac.swift         ← read<Signal>() → Encodable struct or ReadFailure
  │
  ▼
[IOKit / IOPS / IOBluetooth / Foundation]
```

## Public API

| Method | Returns | Source |
|---|---|---|
| `IokitMac::Battery.read` | Hash or nil | `IOPSCopyPowerSourcesInfo` + `AppleSmartBattery` registry entry (`BatteryData` for mAh) |
| `IokitMac::PowerAdapter.read` | Hash or nil | `IOPSCopyExternalPowerAdapterDetails` |
| `IokitMac::Clamshell.closed?` | true / false / nil | `IOPMrootDomain` `AppleClamshellState` (true = lid closed) |
| `IokitMac::Idle.seconds` | Float | `IOHIDSystem` `HIDIdleTime` (nanoseconds, converted to seconds) |
| `IokitMac::Thermal.state` | Symbol in `Thermal::STATES` | `ProcessInfo.thermalState` |
| `IokitMac::Usb.devices` | Array of Hash | `IOUSBHostDevice` matching |
| `IokitMac::Bluetooth.paired_devices` | Array of Hash | `IOBluetoothDevice.pairedDevices` |

Signatures, record types, and their documentation live in `sig/iokit_mac.rbs`.

## Module boundaries

| Layer | Responsibility |
|---|---|
| `lib/iokit_mac.rb` | Loads the .bundle; `Error`, `ReadError`, `Parse.payload`, and one module per signal |
| `sig/iokit_mac.rbs` | RBS for every public method, the `_<signal>_read` singletons, and the Hash record types |
| `ext/iokit_mac/iokit_mac.c` | `Init_iokit_mac` declares Ractor safety and defines the `_<signal>_read` singleton methods |
| `IokitMacBridge.swift` | C ABI exports via `@c(name)`, one per signal plus `iokit_mac_free` |
| `IokitMac.swift` | `ReadFailure`, `respond`, registry helpers, and one `read<Signal>` with its `Encodable` struct per signal |
| `ext/iokit_mac/extconf.rb` | `require_relative "swift_mkmf"` + `SwiftGem::Mkmf.create_swift_makefile("iokit_mac/iokit_mac", package: "IokitMac", source_dir: __dir__)` |
| `ext/iokit_mac/swift_mkmf.rb` | Vendored copy of swift_gem's `lib/swift_gem/mkmf.rb`, kept identical |
| `examples/iokit_mac.rb` | Reads every signal once and prints it |
| `acceptance/*.rb` | Human-in-the-loop scripts that follow signals through physical actions |
| `Rakefile` | `task :swift` + `task compile: :swift` before `Rake::ExtensionTask("iokit_mac")`; `task :rbs`; `task test: %i[rbs compile]`; `task console: :compile` |

## Build flow

`bundle exec rake test` builds and tests in one shot. `xcrun swift build -c release --package-path ext/iokit_mac` writes `IokitMac-Swift.h` under `ext/iokit_mac/.build/out/Intermediates.noindex/GeneratedModuleMaps/` (added with `-I`) and the dylib under `ext/iokit_mac/.build/release`. IOBluetooth is linked through Swift's autolinking of `import IOBluetooth`. `bundle exec rbs -I sig validate` checks the RBS. `xcodebuild docbuild -scheme IokitMac -destination 'generic/platform=macOS'` in `ext/iokit_mac` builds the DocC.

## Tests

`test/iokit_mac/<signal>_test.rb` reads the real hardware and asserts types, key sets, units, and plausible ranges, never a physical state such as "the lid is open". A test omits itself only when the hardware is absent: no internal battery, no adapter connected, no lid. `parse_test.rb` covers the JSON envelope, `native_test.rb` the C method shapes, `ractor_test.rb` calls from a Ractor through `Ractor::Port`.

## Acceptance (HITL)

`acceptance/*.rb` checks how values follow physical input and is not part of `rake test`. Step-style scripts (`clamshell_observe.rb`, `clamshell_dual_observe.rb`, `idle_observe.rb`, `battery_charge_observe.rb`) prompt at each step. Periodic-sampling scripts (`natural_drift_observe.rb`, `physical_action_observe.rb`) write CSV for post-hoc analysis. Claude Code launches them (`tmux new-session -d ...`) and analyzes the logs; the human performs only the physical actions. A change to a signal whose value follows physical input is done only after the matching script has run against real hardware.

To check the lid mapping, use external-display clamshell mode; `pmset -b disablesleep 1` suppresses the lid-close event and leaves `AppleClamshellState` false.

## Related projects

- `~/dev/src/github.com/bash0C7/swift_gem` — scaffold/Mkmf framework
- `~/dev/src/github.com/bash0C7/rb-corebluetooth-mac` — CoreBluetooth scan/connect (this gem only lists paired devices)
- `~/dev/src/github.com/bash0C7/rb-av-foundation-mac` — camera capture

## Environment requirements

macOS 27+, Apple Silicon, Xcode 27 (Swift 6.4, builds run `xcrun swift`), Ruby 4.0+, bundler 4.x, rake-compiler 1.2+. `Gemfile.lock` is not git-tracked.

## Prohibitions

- No Python source
- No code comments. Swift is documented with DocC (`///`, `- Parameter`, `- Returns`, ``` ``symbol`` ``` links to public symbols only); Ruby is documented with `#` comments above declarations in `sig/iokit_mac.rbs`. History goes in commit messages
- Do not hand-edit `ext/iokit_mac/swift_mkmf.rb`; re-copy it from swift_gem
- Do not git-track `Gemfile.lock`
- Do not silent-rescue; report IOKit failures through `ReadFailure` / `IokitMac::ReadError`
- Do not add a signal that needs `sudo`, private API, or a TCC prompt beyond Bluetooth
- Do not put real serials, device names, or Bluetooth addresses into tests, fixtures, or docs
- Commit messages in English, conventional commits style
- `.claude/` is committed
