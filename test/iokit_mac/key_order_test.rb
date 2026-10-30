# frozen_string_literal: true

require "test_helper"

class IokitMacKeyOrderTest < Test::Unit::TestCase
  def assert_sorted_keys(hashes)
    hashes.each do |hash|
      assert_equal(hash.keys.sort, hash.keys)
    end
  end

  test "Battery.read lists keys in sorted order" do
    battery = IokitMac::Battery.read
    omit "no internal battery" if battery.nil?
    assert_sorted_keys([battery])
  end

  test "PowerAdapter.read lists keys in sorted order" do
    adapter = IokitMac::PowerAdapter.read
    omit "no external power adapter connected" if adapter.nil?
    assert_sorted_keys([adapter])
  end

  test "Usb.devices lists keys in sorted order on every call" do
    20.times { assert_sorted_keys(IokitMac::Usb.devices) }
  end

  test "Bluetooth.paired_devices lists keys in sorted order on every call" do
    20.times { assert_sorted_keys(IokitMac::Bluetooth.paired_devices) }
  end
end
