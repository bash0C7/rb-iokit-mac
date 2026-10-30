# frozen_string_literal: true

# HITL: Observe Clamshell.closed? value transitions across physical lid actions.
# WARNING: Closing the lid normally suspends macOS. To run this script meaningfully,
# either (a) SSH in from another machine, (b) attach an external display + keyboard
# in "clamshell mode", or (c) just observe the value before closing the lid.

require_relative "../lib/iokit_mac"

def read_clamshell
  closed = IokitMac::Clamshell.closed?
  puts "  Clamshell.closed? = #{closed.inspect}"
  closed
end

puts "Step 1: lid is currently OPEN. Reading value..."
read_clamshell

puts ""
puts "Step 2: close the lid manually (or via SSH from another machine)."
puts "        Then press Enter here once the lid is closed."
$stdin.gets

puts "Reading value with lid closed:"
read_clamshell

puts ""
puts "Step 3: open the lid again. Then press Enter."
$stdin.gets

puts "Reading value with lid open again:"
read_clamshell

puts ""
puts "Conclusion: record the mapping observed above and consider whether"
puts "IokitMac::Clamshell.closed? needs semantic inversion in lib/iokit_mac.rb."
