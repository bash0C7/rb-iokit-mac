# Acceptance scripts (HITL)

These scripts verify **value vs physical state**: that `IokitMac::Battery.read[:charging]` actually flips when you plug in the adapter, that `IokitMac::Clamshell.closed?` actually changes when you close the lid, etc. They cannot run autonomously — a human must physically toggle hardware between observations.

This directory is **NOT** part of `rake test` and is **NOT** part of the "完了" criteria. It exists for periodic manual verification of semantic mappings between IORegistry / IOKit return values and physical reality on a specific MacBook.

## Scripts

| Script | What you do | What it verifies |
|---|---|---|
| `clamshell_observe.rb` | Close the lid then open it (use an external keyboard / SSH or remote desktop, since closing the lid normally suspends the machine) | The `closed?` semantic mapping on your specific hardware/firmware |
| `idle_observe.rb` | Wait a few seconds without touching keyboard / mouse, then press a key | `Idle.seconds` increases monotonically while idle, resets to ~0 on HID input |
| `battery_charge_observe.rb` | Plug in MagSafe / USB-C charger, then unplug | `Battery.read[:charging]` flips true/false, `PowerAdapter.read` flips nil/Hash |

## How to run

```sh
bundle exec ruby acceptance/clamshell_observe.rb
bundle exec ruby acceptance/idle_observe.rb
bundle exec ruby acceptance/battery_charge_observe.rb
```

Each script prints instructions and waits for Enter between observation steps.
