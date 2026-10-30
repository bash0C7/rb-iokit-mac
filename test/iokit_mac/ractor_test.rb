# frozen_string_literal: true

require "test_helper"

class IokitMacRactorTest < Test::Unit::TestCase
  def self.snapshot
    [
      IokitMac::Battery.read.class,
      IokitMac::PowerAdapter.read.class,
      IokitMac::Clamshell.closed?.class,
      IokitMac::Idle.seconds.class,
      IokitMac::Thermal.state.class,
      IokitMac::Usb.devices.map(&:keys),
      IokitMac::Bluetooth.paired_devices.map { it[:address] }
    ]
  end

  test "every public method runs inside a Ractor" do
    port = Ractor::Port.new
    ractor = Ractor.new(port) do |out|
      out << IokitMacRactorTest.snapshot
    end
    ractor.join
    assert_equal(self.class.snapshot, port.receive)
  end

  test "ReadError raised inside a Ractor reaches the caller" do
    port = Ractor::Port.new
    ractor = Ractor.new(port) do |out|
      IokitMac::Parse.payload('{"error":"io_kit_failure","detail":"x"}', source: "idle")
    rescue IokitMac::ReadError => e
      out << e.message
    end
    ractor.join
    assert_equal("idle: io_kit_failure: x", port.receive)
  end
end
