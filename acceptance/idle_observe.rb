# frozen_string_literal: true

# HITL: Observe Idle.seconds reset on HID input.

require_relative "../lib/iokit_mac"

puts "Step 1: do NOT touch keyboard/mouse for ~5 seconds, then press Enter here."
$stdin.gets
puts "  Idle.seconds (immediately after Enter, which is HID input) = #{IokitMac::Idle.seconds}"

puts ""
puts "Step 2: wait 5 seconds without touching anything, then press Enter."
$stdin.gets
puts "  Idle.seconds (after wait + Enter) = #{IokitMac::Idle.seconds}"

puts ""
puts "Step 3: rapid HID input — press Enter immediately."
$stdin.gets
puts "  Idle.seconds (immediately) = #{IokitMac::Idle.seconds}"

puts ""
puts "Conclusion: idle should be near 0 right after Enter, and grow when no input."
