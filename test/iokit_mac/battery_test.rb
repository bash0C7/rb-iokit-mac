# frozen_string_literal: true

require "test_helper"

class IokitMacBatteryTest < Test::Unit::TestCase
  KEYS = %i[
    percent current_capacity_percent max_capacity_percent charging charged
    time_to_empty_minutes time_to_full_minutes source power_source_state
    cycle_count design_capacity_mah current_capacity_mah max_capacity_mah
    voltage_mv serial device_name installed fully_charged
  ].freeze

  def setup
    @battery = IokitMac::Battery.read
    omit "no internal battery" if @battery.nil?
  end

  test "returns only documented keys" do
    assert_empty(@battery.keys - KEYS)
  end

  test "reports the charge level as a Float percent consistent with the capacity percents" do
    assert_kind_of(Float, @battery[:percent])
    expected = @battery[:current_capacity_percent] * 100.0 / @battery[:max_capacity_percent]
    assert_in_delta(expected, @battery[:percent], 0.001)
    assert_include(0.0..100.0, @battery[:percent])
  end

  test "reports booleans for the charge flags" do
    %i[charging charged installed fully_charged].each do |key|
      assert_include([true, false], @battery[key], key.to_s)
    end
  end

  test "reports the AppleSmartBattery capacities in mAh" do
    %i[design_capacity_mah current_capacity_mah max_capacity_mah].each do |key|
      assert_kind_of(Integer, @battery[key], key.to_s)
      assert_include(500..20_000, @battery[key], key.to_s)
    end
    assert_operator(@battery[:current_capacity_mah], :<=, @battery[:max_capacity_mah])
  end

  test "reports the cycle count and the pack voltage in mV" do
    assert_operator(@battery[:cycle_count], :>=, 0)
    assert_include(5_000..25_000, @battery[:voltage_mv])
  end

  test "reports remaining times in minutes only when macOS has an estimate" do
    %i[time_to_empty_minutes time_to_full_minutes].each do |key|
      next unless @battery.key?(key)

      assert_kind_of(Integer, @battery[key], key.to_s)
      assert_operator(@battery[key], :>=, 0, key.to_s)
    end
  end

  test "reports the power source names as Strings" do
    assert_kind_of(String, @battery[:source])
    assert_kind_of(String, @battery[:power_source_state])
  end
end
