# frozen_string_literal: true

# HITL: 物理操作で変動する 7 モジュール全部を定点観測。
# お嬢様が USB抜き差し / MagSafe挿し戻し / BT pair操作 / ふた開閉 などの物理操作を
# 行うのに合わせて、各 signal の変動を CSV ログに残す。
#
# env vars:
#   INTERVAL  サンプリング間隔 (秒, default 5)
#   DURATION  観測総時間 (秒, default 600 = 10 min)

require_relative "../lib/iokit_mac"

interval = (ENV["INTERVAL"] || "5").to_i
duration = (ENV["DURATION"] || "600").to_i
start = Time.now

puts "timestamp,elapsed_s,battery_percent,battery_mah,charging,power_source,adapter_present,clamshell_closed,usb_count,bt_count,idle_s,thermal"
$stdout.flush

loop do
  elapsed = Time.now - start
  break if elapsed >= duration

  b = IokitMac::Battery.read
  pa = IokitMac::PowerAdapter.read

  row = [
    Time.now.strftime("%H:%M:%S"),
    elapsed.round(1),
    b ? b[:percent] : nil,
    b ? b[:current_capacity_mah] : nil,
    b ? b[:charging] : nil,
    b ? b[:power_source_state] : nil,
    !pa.nil?,
    IokitMac::Clamshell.closed?,
    IokitMac::Usb.devices.size,
    IokitMac::Bluetooth.paired_devices.size,
    IokitMac::Idle.seconds.round(2),
    IokitMac::Thermal.state
  ]
  puts row.join(",")
  $stdout.flush

  sleep interval
end

puts "# observation complete (#{duration}s)"
