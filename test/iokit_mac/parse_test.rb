# frozen_string_literal: true

require "test_helper"

class IokitMacParseTest < Test::Unit::TestCase
  test "decodes objects with Symbol keys" do
    assert_equal({ watts: 30, wireless: false }, IokitMac::Parse.payload('{"watts":30,"wireless":false}', source: "power_adapter"))
  end

  test "decodes JSON null to nil" do
    assert_nil(IokitMac::Parse.payload("null", source: "battery"))
  end

  test "decodes scalar payloads" do
    assert_equal(true, IokitMac::Parse.payload("true", source: "clamshell"))
    assert_equal(42.5, IokitMac::Parse.payload("42.5", source: "idle"))
    assert_equal("nominal", IokitMac::Parse.payload('"nominal"', source: "thermal"))
  end

  test "raises ReadError carrying the source, code, and detail of an error envelope" do
    error = assert_raise(IokitMac::ReadError) do
      IokitMac::Parse.payload('{"error":"io_kit_failure","detail":"IOHIDSystem not found"}', source: "idle")
    end
    assert_equal("idle: io_kit_failure: IOHIDSystem not found", error.message)
    assert_kind_of(IokitMac::Error, error)
  end
end
