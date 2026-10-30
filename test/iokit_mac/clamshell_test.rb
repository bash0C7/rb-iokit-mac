# frozen_string_literal: true

require "test_helper"

class IokitMacClamshellTest < Test::Unit::TestCase
  test "returns a boolean on a Mac with a lid" do
    closed = IokitMac::Clamshell.closed?
    omit "no clamshell" if closed.nil?
    assert_include([true, false], closed)
  end
end
