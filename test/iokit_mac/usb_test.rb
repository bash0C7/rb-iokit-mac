# frozen_string_literal: true

require "test_helper"

class IokitMacUsbTest < Test::Unit::TestCase
  KEYS = %i[
    vendor_id product_id name vendor_name serial
    device_class device_subclass device_protocol bcd_device
  ].freeze

  test "returns an Array of Hashes with documented keys" do
    devices = IokitMac::Usb.devices
    assert_kind_of(Array, devices)
    devices.each do |device|
      assert_empty(device.keys - KEYS)
    end
  end

  test "reports numeric descriptor fields as non-negative Integers" do
    IokitMac::Usb.devices.each do |device|
      %i[vendor_id product_id device_class device_subclass device_protocol bcd_device].each do |key|
        next unless device.key?(key)

        assert_kind_of(Integer, device[key], key.to_s)
        assert_operator(device[key], :>=, 0, key.to_s)
      end
    end
  end
end
