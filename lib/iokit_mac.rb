# frozen_string_literal: true

require "json"
require_relative "iokit_mac/version"
require_relative "iokit_mac/iokit_mac"

module IokitMac
  class Error < StandardError; end
  class ReadError < Error; end

  module Parse
    def self.payload(raw, source:)
      parsed = JSON.parse(raw, symbolize_names: true)
      raise ReadError, "#{source}: #{parsed[:error]}: #{parsed[:detail]}" if parsed.is_a?(Hash) && parsed.key?(:error)

      parsed
    end
  end

  module Battery
    def self.read
      battery = Parse.payload(IokitMac._battery_read, source: "battery")
      battery[:percent] = battery[:percent].to_f if battery&.key?(:percent)
      battery
    end
  end

  module PowerAdapter
    def self.read = Parse.payload(IokitMac._power_adapter_read, source: "power_adapter")
  end

  module Clamshell
    def self.closed? = Parse.payload(IokitMac._clamshell_read, source: "clamshell")
  end

  module Idle
    def self.seconds = Parse.payload(IokitMac._idle_read, source: "idle").to_f
  end

  module Thermal
    STATES = %i[nominal fair serious critical unknown].freeze

    def self.state = Parse.payload(IokitMac._thermal_read, source: "thermal").to_sym
  end

  module Usb
    def self.devices = Parse.payload(IokitMac._usb_devices_read, source: "usb_devices")
  end

  module Bluetooth
    def self.paired_devices = Parse.payload(IokitMac._bluetooth_paired_devices_read, source: "bluetooth_paired_devices")
  end
end
