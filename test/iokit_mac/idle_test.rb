# frozen_string_literal: true

require "test_helper"

class IokitMacIdleTest < Test::Unit::TestCase
  test "returns a non-negative Float" do
    seconds = IokitMac::Idle.seconds
    assert_kind_of(Float, seconds)
    assert_operator(seconds, :>=, 0.0)
  end

  test "returns seconds, not nanoseconds, so idle time never exceeds the time since boot" do
    assert_operator(IokitMac::Idle.seconds, :<=, Process.clock_gettime(Process::CLOCK_MONOTONIC))
  end
end
