# frozen_string_literal: true

require "test_helper"
require "json"

class IokitMacNativeTest < Test::Unit::TestCase
  READERS = %i[
    _battery_read _power_adapter_read _clamshell_read _idle_read
    _thermal_read _usb_devices_read _bluetooth_paired_devices_read
  ].freeze

  test "each reader takes no arguments and returns UTF-8 JSON" do
    READERS.each do |reader|
      assert_equal(0, IokitMac.method(reader).arity, reader.to_s)
      raw = IokitMac.public_send(reader)
      assert_equal(Encoding::UTF_8, raw.encoding, reader.to_s)
      assert_nothing_raised(reader.to_s) { JSON.parse(raw) }
    end
  end

  test "readers reject arguments" do
    READERS.each do |reader|
      assert_raise(ArgumentError, reader.to_s) { IokitMac.public_send(reader, 1) }
    end
  end

  test "thermal reader returns a bare JSON string" do
    assert_match(/\A"[a-z]+"\z/, IokitMac._thermal_read)
  end
end
