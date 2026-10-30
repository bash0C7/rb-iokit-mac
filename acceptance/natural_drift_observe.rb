# frozen_string_literal: true

# HITL: 自然変動する信号 (Battery / Idle / Thermal) を定点観測。
# 普段使い or 放置中に流して、CSV ログから drift を確認する。
#
# env vars:
#   INTERVAL  サンプリング間隔 (秒, default 10)
#   DURATION  観測総時間 (秒, default 900 = 15 min)

require_relative "../lib/iokit_mac"

interval = (ENV["INTERVAL"] || "10").to_i
duration = (ENV["DURATION"] || "900").to_i
start = Time.now

puts "timestamp,elapsed_s,battery_percent,battery_mah,battery_charging,power_source,idle_s,thermal_state"
$stdout.flush

loop do
  elapsed = Time.now - start
  break if elapsed >= duration

  b = IokitMac::Battery.read
  percent = b ? b[:percent] : nil
  mah = b ? b[:current_capacity_mah] : nil
  charging = b ? b[:charging] : nil
  power_source = b ? b[:power_source_state] : nil
  idle = IokitMac::Idle.seconds
  thermal = IokitMac::Thermal.state

  puts [
    Time.now.strftime("%H:%M:%S"),
    elapsed.round(1),
    percent,
    mah,
    charging,
    power_source,
    idle.round(2),
    thermal
  ].join(",")
  $stdout.flush

  sleep interval
end

puts "# observation complete (#{duration}s)"
