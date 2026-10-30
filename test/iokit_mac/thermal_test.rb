# frozen_string_literal: true

require "test_helper"

class IokitMacThermalTest < Test::Unit::TestCase
  test "returns one of the documented states" do
    assert_include(IokitMac::Thermal::STATES, IokitMac::Thermal.state)
  end

  test "lists the ProcessInfo.ThermalState cases" do
    assert_equal(%i[nominal fair serious critical unknown], IokitMac::Thermal::STATES)
    assert_predicate(IokitMac::Thermal::STATES, :frozen?)
  end
end
