# frozen_string_literal: true

require_relative "../lib/iokit_mac"

puts "=== Battery (basic + detail merged) ==="
pp IokitMac::Battery.read

puts ""
puts "=== PowerAdapter ==="
pp IokitMac::PowerAdapter.read

puts ""
puts "=== Clamshell ==="
puts "closed? = #{IokitMac::Clamshell.closed?.inspect}"

puts ""
puts "=== Idle ==="
puts "seconds = #{IokitMac::Idle.seconds}"

puts ""
puts "=== Thermal ==="
puts "state = #{IokitMac::Thermal.state.inspect}"

puts ""
puts "=== Usb ==="
puts "device count = #{IokitMac::Usb.devices.size}"
IokitMac::Usb.devices.first(5).each_with_index do |dev, i|
  puts "  [#{i}] #{dev.inspect}"
end

puts ""
puts "=== Bluetooth ==="
puts "paired device count = #{IokitMac::Bluetooth.paired_devices.size}"
IokitMac::Bluetooth.paired_devices.first(5).each_with_index do |dev, i|
  puts "  [#{i}] #{dev.inspect}"
end
