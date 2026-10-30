# frozen_string_literal: true

# HITL: Observe Battery.charging / PowerAdapter.read transitions on plug/unplug.

require_relative "../lib/iokit_mac"

def snapshot(label)
  puts "[#{label}]"
  b = IokitMac::Battery.read
  pa = IokitMac::PowerAdapter.read
  puts "  Battery.charging      = #{b ? b[:charging].inspect : 'no battery'}"
  puts "  Battery.power_source  = #{b ? b[:power_source_state].inspect : 'no battery'}"
  puts "  PowerAdapter.read     = #{pa ? "Hash (#{pa.size} keys)" : 'nil'}"
end

snapshot("initial")

puts ""
puts "Step 1: plug in MagSafe / USB-C charger. Then press Enter."
$stdin.gets
snapshot("plugged in")

puts ""
puts "Step 2: unplug the charger. Then press Enter."
$stdin.gets
snapshot("unplugged")

puts ""
puts "Conclusion: charging should flip true→false, PowerAdapter should flip Hash→nil."
