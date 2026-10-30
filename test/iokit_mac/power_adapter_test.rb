# frozen_string_literal: true

require "test_helper"

class IokitMacPowerAdapterTest < Test::Unit::TestCase
  KEYS = %i[
    watts current_ma voltage_mv adapter_id family_code serial name
    manufacturer model description wireless firmware_version hardware_version
  ].freeze

  def setup
    @adapter = IokitMac::PowerAdapter.read
    omit "no external power adapter connected" if @adapter.nil?
  end

  test "returns only documented snake_case keys" do
    assert_empty(@adapter.keys - KEYS)
  end

  test "reports watts, current in mA, and voltage in mV" do
    assert_operator(@adapter[:watts], :>, 0)
    assert_kind_of(Integer, @adapter[:current_ma]) if @adapter.key?(:current_ma)
    assert_include(1_000..50_000, @adapter[:voltage_mv]) if @adapter.key?(:voltage_mv)
  end
end
