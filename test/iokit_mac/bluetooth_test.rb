# frozen_string_literal: true

require "test_helper"

class IokitMacBluetoothTest < Test::Unit::TestCase
  test "returns an Array of Hashes with documented keys and types" do
    devices = IokitMac::Bluetooth.paired_devices
    assert_kind_of(Array, devices)
    devices.each do |device|
      assert_empty(device.keys - %i[name address paired connected])
      assert_kind_of(String, device[:address])
      assert_kind_of(String, device[:name]) if device.key?(:name)
      assert_include([true, false], device[:paired])
      assert_include([true, false], device[:connected])
    end
  end

  test "returns the same list from a thread other than the main thread" do
    expected = IokitMac::Bluetooth.paired_devices.map { it[:address] }.sort
    actual = Thread.new { IokitMac::Bluetooth.paired_devices.map { it[:address] }.sort }.value
    assert_equal(expected, actual)
  end
end
